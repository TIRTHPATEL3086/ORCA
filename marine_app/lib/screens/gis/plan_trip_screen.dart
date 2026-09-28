import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../models/gis_models.dart';
import '../../services/fisherman_service.dart';
import '../../services/gis_service.dart';
import '../../services/offline_readiness_service.dart';
import 'mission_tracking_screen.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final MapController mapController = MapController();
  final speedController = TextEditingController(text: '8');

  List<BoundaryZoneData> zones = const [];
  LatLng? startPoint;
  LatLng? endPoint;

  RoutePlanData? plan;
  RouteAlternativeData? selectedRoute;

  bool loading = true;
  bool calculating = false;
  bool preparingOffline = false;
  String offlineReadiness = 'Checking offline readiness...';
  String? error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    speedController.dispose();
    super.dispose();
  }

  Future<Position?> _tryPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  Future<void> _bootstrap() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final loadedZones = await GisService.getZones();

      await OfflineReadinessService.saveSafetyCacheBoundaries(
        loadedZones,
      );
      final position = await _tryPosition();

      try {
        final vessels = await FishermanService.getVessels();

        final speeds = vessels
            .map((v) => v.cruisingSpeedKnots)
            .whereType<double>()
            .where((v) => v > 0)
            .toList();

        if (speeds.isNotEmpty) {
          speedController.text = speeds.first.toStringAsFixed(1);
        }
      } catch (_) {
        // Editable fallback speed remains available.
      }

      if (!mounted) return;

      setState(() {
        zones = loadedZones;
        offlineReadiness = 'Safety Cache Ready';

        if (position != null) {
          startPoint = LatLng(position.latitude, position.longitude);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _useGpsStart() async {
    final p = await _tryPosition();

    if (p == null) {
      _message('GPS is unavailable or permission was not granted.');
      return;
    }

    final point = LatLng(p.latitude, p.longitude);

    final check = await GisService.checkBoundary(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (check.surface == 'LAND') {
      _message(
        'Your GPS position is currently on land. '
        'For a real mission, start tracking once the vessel is on water. '
        'For testing, use the demo sea route.',
      );
    }

    setState(() {
      startPoint = point;
      plan = null;
      selectedRoute = null;
    });

    mapController.move(point, 8);
  }

  void _loadDemoRoute() {
    const start = LatLng(20.65, 69.75);
    const end = LatLng(20.00, 68.40);

    setState(() {
      startPoint = start;
      endPoint = end;
      plan = null;
      selectedRoute = null;
      speedController.text = '8';
    });

    mapController.move(const LatLng(20.32, 69.08), 7.4);
  }

  Future<void> _planRoute() async {
    final start = startPoint;
    final end = endPoint;

    if (start == null || end == null) {
      _message('Choose a water start point and destination first.');
      return;
    }

    final speed = double.tryParse(speedController.text.trim());

    if (speed == null || speed <= 0) {
      _message('Enter a valid cruising speed in knots.');
      return;
    }

    setState(() {
      calculating = true;
      plan = null;
      selectedRoute = null;
    });

    try {
      final result = await GisService.planRoute(
        startLatitude: start.latitude,
        startLongitude: start.longitude,
        endLatitude: end.latitude,
        endLongitude: end.longitude,
        cruisingSpeedKnots: speed,
      );

      if (!mounted) return;

      final lower = result.lowerExposure;
      final fast = result.fastest;

      final initial = lower.exposureScore < fast.exposureScore ? lower : fast;

      setState(() {
        plan = result;
        selectedRoute = initial;
      });

      await _prepareOfflineMissionPack(
        routePlan: result,
        selected: initial,
        start: start,
        destination: end,
        speed: speed,
      );

      final points = initial.waypoints
          .map((w) => LatLng(w.latitude, w.longitude))
          .toList();

      if (points.isNotEmpty) {
        mapController.move(points[points.length ~/ 2], 7.7);
      }
    } catch (e) {
      if (!mounted) return;
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() => calculating = false);
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LOW':
        return AppTheme.success;
      case 'CAUTION':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  String _eta(double minutes) {
    final total = minutes.round();
    final h = total ~/ 60;
    final m = total % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  List<LatLng> _routePoints(RouteAlternativeData? route) {
    if (route == null) return const [];

    return route.waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
  }

  Future<void> _prepareOfflineMissionPack({
    required RoutePlanData routePlan,
    required RouteAlternativeData selected,
    required LatLng start,
    required LatLng destination,
    required double speed,
  }) async {
    if (mounted) {
      setState(() {
        preparingOffline = true;
        offlineReadiness = 'Preparing offline mission data...';
      });
    }

    final saved = await OfflineReadinessService.saveMissionPack(
      plan: routePlan,
      selectedRoute: selected,
      start: start,
      destination: destination,
      cruisingSpeedKnots: speed,
      zones: zones,
    );

    if (!mounted) return;

    setState(() {
      preparingOffline = false;
      offlineReadiness = saved
          ? 'Offline Ready • Mission Pack saved automatically'
          : 'Safety Cache Ready • Mission Pack could not be saved';
    });
  }


  Future<void> _startMission() async {
    final route = selectedRoute;
    final speed = double.tryParse(speedController.text.trim());

    if (route == null || speed == null || speed <= 0) {
      return;
    }

    // Final selected route is persisted before navigation.
    final routePlan = plan;
    final start = startPoint;
    final destination = endPoint;

    if (routePlan != null && start != null && destination != null) {
      await _prepareOfflineMissionPack(
        routePlan: routePlan,
        selected: route,
        start: start,
        destination: destination,
        speed: speed,
      );
    }


    if (routePlan != null && start != null && destination != null) {
      await _prepareOfflineMissionPack(
          routePlan: routePlan,
          selected: route,
          start: start,
          destination: destination,
          speed: speed,
      );
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MissionTrackingScreen(route: route, cruisingSpeedKnots: speed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      appBar: AppBar(
        title: const Text('Marine Trip Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _errorView()
          : _content(),
    );
  }

  Widget _offlineReadinessCard() {
    final full = offlineReadiness.startsWith('Offline Ready');
    final color = full ? AppTheme.success : AppTheme.oceanBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              full ? Icons.offline_pin_rounded : Icons.shield_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  full ? 'Offline Ready' : 'Always-Ready Safety Cache',
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  offlineReadiness,
                  style: const TextStyle(
                    color: Color(0xFF637983),
                    fontSize: 11.8,
                    height: 1.3,
                  ),
                ),
                if (!full)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'Plan a route and ORCA prepares the Mission Pack automatically — no separate download step.',
                      style: TextStyle(
                        color: Color(0xFF637983),
                        fontSize: 11.2,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (preparingOffline)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }


  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_rounded,
              size: 50,
              color: AppTheme.oceanBlue,
            ),
            const SizedBox(height: 14),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _bootstrap, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final center = startPoint ?? const LatLng(20.32, 69.08);

    final selectedPoints = _routePoints(selectedRoute);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        _offlineReadinessCard(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'ORCA now plans on a water-only grid. Land cells and loaded '
            'demo geofences are blocked, while live wave, wind and ocean-current '
            'conditions influence route cost and ETA.',
            style: TextStyle(
              color: Color(0xFF557079),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Container(
          height: 400,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCE8EC)),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 7.3,
                  onTap: (_, point) {
                    setState(() {
                      endPoint = point;
                      plan = null;
                      selectedRoute = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.orca.marine_app',
                  ),
                  PolygonLayer(
                    polygons: zones.map((zone) {
                      return Polygon(
                        points: zone.coordinates
                            .map((pair) => LatLng(pair[1], pair[0]))
                            .toList(),
                        color: AppTheme.danger.withValues(alpha: 0.13),
                        borderColor: AppTheme.danger,
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),
                  if (selectedPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: selectedPoints,
                          strokeWidth: 5,
                          color: AppTheme.oceanBlue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (startPoint != null)
                        Marker(
                          point: startPoint!,
                          width: 48,
                          height: 48,
                          child: _marker(
                            Icons.sailing_rounded,
                            AppTheme.success,
                          ),
                        ),
                      if (endPoint != null)
                        Marker(
                          point: endPoint!,
                          width: 48,
                          height: 48,
                          child: _marker(
                            Icons.flag_rounded,
                            AppTheme.oceanBlue,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Column(
                  children: [
                    _mapButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Use GPS start',
                      onTap: _useGpsStart,
                    ),
                    const SizedBox(height: 8),
                    _mapButton(
                      icon: Icons.science_rounded,
                      tooltip: 'Load sea demo route',
                      onTap: _loadDemoRoute,
                    ),
                  ],
                ),
              ),
              if (calculating)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap a water point for destination. If your phone GPS is on land, '
          'use the demo sea route for testing.',
          style: TextStyle(color: Color(0xFF74868E), fontSize: 12.2),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: speedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Vessel cruising speed',
            suffixText: 'kn',
            helperText: 'Uses saved vessel speed when available.',
            prefixIcon: const Icon(Icons.speed_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: calculating ? null : _planRoute,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.alt_route_rounded),
            label: Text(
              calculating
                  ? 'Sampling sea conditions...'
                  : 'Build Weather-Aware Routes',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Choose a route',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Compare arrival time with environmental exposure.',
            style: TextStyle(color: Color(0xFF71838B), fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          _routeChoice(plan!.fastest),
          const SizedBox(height: 10),
          _routeChoice(plan!.lowerExposure),
          if (selectedRoute != null) ...[
            const SizedBox(height: 18),
            _selectedDetails(selectedRoute!),
            const SizedBox(height: 15),
            SizedBox(
              height: 58,
              child: FilledButton.icon(
                onPressed: _startMission,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  'START MISSION',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                plan!.navigationNotice,
                style: const TextStyle(
                  color: Color(0xFF6C6048),
                  fontSize: 11.8,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _marker(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.navy),
      ),
    );
  }

  Widget _routeChoice(RouteAlternativeData route) {
    final selected = selectedRoute?.routeId == route.routeId;

    final color = _statusColor(route.routeStatus);

    return InkWell(
      onTap: () {
        setState(() => selectedRoute = route);

        final points = _routePoints(route);

        if (points.isNotEmpty) {
          mapController.move(points[points.length ~/ 2], 7.7);
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.oceanBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppTheme.oceanBlue : const Color(0xFFE0E9ED),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.title,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    route.routeStatus,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _inlineMetric('ETA', _eta(route.etaMinutes))),
                Expanded(
                  child: _inlineMetric(
                    'Distance',
                    '${route.distanceNm.toStringAsFixed(1)} nm',
                  ),
                ),
                Expanded(
                  child: _inlineMetric(
                    'Exposure',
                    route.exposureScore.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Max waves '
              '${route.maxWaveHeightM?.toStringAsFixed(1) ?? '--'} m'
              ' • Max wind '
              '${route.maxWindSpeedMs?.toStringAsFixed(1) ?? '--'} m/s',
              style: const TextStyle(color: Color(0xFF657982), fontSize: 12.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7C8D94), fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _selectedDetails(RouteAlternativeData route) {
    final samples = <RouteWaypointData>[];

    if (route.waypoints.isNotEmpty) {
      samples.add(route.waypoints.first);

      if (route.waypoints.length > 2) {
        samples.add(route.waypoints[route.waypoints.length ~/ 2]);
      }

      if (route.waypoints.length > 1) {
        samples.add(route.waypoints.last);
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why ORCA selected this path',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ...route.rationale
              .take(4)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.success,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: Color(0xFF62767E),
                            fontSize: 12.2,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (samples.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Conditions along route',
              style: TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            ...samples.asMap().entries.map((entry) {
              final label = entry.key == 0
                  ? 'Start'
                  : entry.key == samples.length - 1
                  ? 'Destination'
                  : 'Mid-route';

              return _conditionRow(label, entry.value.condition);
            }),
          ],
        ],
      ),
    );
  }

  Widget _conditionRow(String label, RouteConditionData c) {
    String v(double? value, String unit) {
      return value == null ? '--' : '${value.toStringAsFixed(1)} $unit';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF71838B),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Wave ${v(c.waveHeightM, 'm')} • '
              'Wind ${v(c.windSpeedMs, 'm/s')} • '
              'Current ${v(c.currentVelocityMs, 'm/s')}',
              style: const TextStyle(color: AppTheme.navy, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
