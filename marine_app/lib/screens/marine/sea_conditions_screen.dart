import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marine_conditions.dart';
import '../../services/marine_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';

class SeaConditionsScreen extends StatefulWidget {
  const SeaConditionsScreen({super.key});

  @override
  State<SeaConditionsScreen> createState() => _SeaConditionsScreenState();
}

class _SeaConditionsScreenState extends State<SeaConditionsScreen> {
  MarineConditionsData? data;
  Position? position;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('Location service is disabled. Enable GPS and retry.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required to load marine conditions near you.',
      );
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final currentPosition = await _getPosition();

      final result = await MarineService.getConditions(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      );

      if (!mounted) return;

      setState(() {
        position = currentPosition;
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LOW':
        return AppTheme.success;
      case 'CAUTION':
        return AppTheme.warning;
      case 'HIGH':
        return AppTheme.danger;
      default:
        return AppTheme.muted;
    }
  }

  String _value(double? value, String unit, {int decimals = 1}) {
    if (value == null) return 'Unavailable';

    return '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sea Conditions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.white),
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: GridBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _errorView()
            : _content(),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OrcaMascot(size: 110, mood: MascotMood.sleepy, halo: true),
            const SizedBox(height: 18),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final d = data!;
    final p = position!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _screeningCard(d),
          const SizedBox(height: 14),
          _mapCard(p.latitude, p.longitude),
          const SizedBox(height: 22),
          const Text(
            'Live marine conditions',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          _grid(d),
          const SizedBox(height: 18),
          _evidenceCard(d),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.butter.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SoftIcon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.ink,
                  background: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.navigationNotice,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard(double latitude, double longitude) {
    final point = LatLng(latitude, longitude);

    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 7.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.orca.marine_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.coral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: AppTheme.coralDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${latitude.toStringAsFixed(4)}, '
                    '${longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screeningCard(MarineConditionsData d) {
    final color = _statusColor(d.screeningStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.coral,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, color: color, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Prototype screening: '
                          '${d.screeningStatus}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  d.screeningReason,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const OrcaMascot(
            size: 72,
            mood: MascotMood.happy,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _grid(MarineConditionsData d) {
    final items = [
      ('Wave height', _value(d.waveHeightM, 'm'), Icons.waves_rounded),
      ('Wave period', _value(d.wavePeriodS, 's'), Icons.timelapse_rounded),
      ('Swell', _value(d.swellHeightM, 'm'), Icons.water_rounded),
      (
        'Sea temperature',
        _value(d.seaSurfaceTemperatureC, '°C'),
        Icons.thermostat_rounded,
      ),
      (
        'Ocean current',
        _value(d.oceanCurrentVelocityMs, 'm/s', decimals: 2),
        Icons.trending_up_rounded,
      ),
      ('Wind', _value(d.windSpeedMs, 'm/s'), Icons.air_rounded),
      ('Wind gust', _value(d.windGustMs, 'm/s'), Icons.storm_rounded),
      (
        'Sea level',
        _value(d.seaLevelHeightMslM, 'm', decimals: 2),
        Icons.height_rounded,
      ),
    ];

    const tiles = [
      Colors.white,
      AppTheme.lavenderSoft,
      AppTheme.limeSoft,
      Colors.white,
    ];
    const iconTints = [
      AppTheme.coralDeep,
      AppTheme.indigo,
      AppTheme.sageDeep,
      AppTheme.coralDeep,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        final tile = tiles[index % tiles.length];
        final tint = iconTints[index % iconTints.length];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftIcon(
                item.$3,
                color: tint,
                background: tile == Colors.white
                    ? AppTheme.coralSoft
                    : Colors.white,
                size: 36,
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.$1,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _evidenceCard(MarineConditionsData d) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SoftIcon(
                Icons.fact_check_outlined,
                color: AppTheme.indigo,
                background: AppTheme.lavenderSoft,
                size: 38,
              ),
              SizedBox(width: 11),
              Text(
                'Evidence & freshness',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...d.evidence.map(
            (e) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.source,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    e.modelTime == null
                        ? e.freshnessLabel
                        : '${e.freshnessLabel} • ${e.modelTime}',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (e.note != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      e.note!,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official India reference: '
            '${d.officialIndiaReference}',
            style: const TextStyle(
              color: AppTheme.coralDeep,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
