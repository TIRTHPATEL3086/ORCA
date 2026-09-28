import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gis_models.dart';

class OfflineReadinessStatus {
  final bool hasSafetyCache;
  final bool hasMissionPack;
  final DateTime? safetyUpdatedAt;
  final DateTime? missionUpdatedAt;

  const OfflineReadinessStatus({
    required this.hasSafetyCache,
    required this.hasMissionPack,
    required this.safetyUpdatedAt,
    required this.missionUpdatedAt,
  });

  String get mode {
    if (hasMissionPack) return 'MISSION_READY';
    if (hasSafetyCache) return 'LIMITED_OFFLINE_READY';
    return 'NOT_READY';
  }
}

class OfflineReadinessService {
  OfflineReadinessService._();

  static const _safetyCacheKey = 'orca_always_ready_safety_cache_v1';
  static const _missionPackKey = 'orca_auto_mission_pack_v1';

  static Future<void> saveSafetyCacheBoundaries(
    List<BoundaryZoneData> zones,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      final payload = <String, dynamic>{
        'version': 1,
        'type': 'always_ready_safety_cache',
        'updated_at': now.toIso8601String(),
        'boundary_count': zones.length,
        'boundaries': zones
            .map(
              (zone) => {
                'coordinates': zone.coordinates,
              },
            )
            .toList(),
        'capabilities': [
          'cached_boundary_geometry',
          'cached_restricted_zone_geometry',
          'device_gps_compatible',
        ],
        'limitations': [
          'No new weather or advisory can be created while offline.',
          'Cached information must be checked for age before use.',
        ],
      };

      await prefs.setString(
        _safetyCacheKey,
        jsonEncode(payload),
      );
    } catch (_) {
      // Offline readiness must never crash the live mission workflow.
    }
  }

  static Map<String, dynamic> _routeToJson(
    RouteAlternativeData route,
  ) {
    return {
      'route_id': route.routeId,
      'distance_nm': route.distanceNm,
      'eta_minutes': route.etaMinutes,
      'exposure_score': route.exposureScore,
      'route_status': route.routeStatus,
      'waypoints': route.waypoints
          .map(
            (waypoint) => {
              'latitude': waypoint.latitude,
              'longitude': waypoint.longitude,
            },
          )
          .toList(),
    };
  }

  static Future<bool> saveMissionPack({
    required RoutePlanData plan,
    required RouteAlternativeData selectedRoute,
    required LatLng start,
    required LatLng destination,
    required double cruisingSpeedKnots,
    required List<BoundaryZoneData> zones,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      final payload = <String, dynamic>{
        'version': 1,
        'type': 'orca_auto_mission_pack',
        'prepared_automatically': true,
        'prepared_at': now.toIso8601String(),
        'start': {
          'latitude': start.latitude,
          'longitude': start.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'cruising_speed_knots': cruisingSpeedKnots,
        'selected_route_id': selectedRoute.routeId,
        'routes': {
          'fastest': _routeToJson(plan.fastest),
          'lower_exposure': _routeToJson(plan.lowerExposure),
        },
        'boundaries': zones
            .map(
              (zone) => {
                'coordinates': zone.coordinates,
              },
            )
            .toList(),
        'offline_capabilities': [
          'route_waypoints',
          'route_distance',
          'route_eta_snapshot',
          'route_exposure_snapshot',
          'cached_boundaries_and_geofences',
          'device_gps_positioning',
          'mission_context',
        ],
        'freshness': {
          'prepared_at': now.toIso8601String(),
          'live_refresh_required_when_online': true,
        },
        'limitations': [
          'This v1 core pack stores mission geometry and context locally.',
          'Offline map-tile packaging and live-offline alert rules are added in the next phase.',
          'No new marine forecast is inferred without connectivity.',
        ],
      };

      await prefs.setString(
        _missionPackKey,
        jsonEncode(payload),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateSelectedRoute(
    RouteAlternativeData route,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_missionPackKey);

      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) return;

      decoded['selected_route_id'] = route.routeId;
      decoded['selected_route_updated_at'] =
          DateTime.now().toUtc().toIso8601String();

      await prefs.setString(
        _missionPackKey,
        jsonEncode(decoded),
      );
    } catch (_) {
      // Keep the existing pack if a local update fails.
    }
  }

  static Future<OfflineReadinessStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final safety = prefs.getString(_safetyCacheKey);
    final mission = prefs.getString(_missionPackKey);

    DateTime? safetyUpdatedAt;
    DateTime? missionUpdatedAt;

    if (safety != null && safety.isNotEmpty) {
      try {
        final decoded = jsonDecode(safety);
        if (decoded is Map<String, dynamic>) {
          safetyUpdatedAt = DateTime.tryParse(
            decoded['updated_at']?.toString() ?? '',
          );
        }
      } catch (_) {}
    }

    if (mission != null && mission.isNotEmpty) {
      try {
        final decoded = jsonDecode(mission);
        if (decoded is Map<String, dynamic>) {
          missionUpdatedAt = DateTime.tryParse(
            decoded['prepared_at']?.toString() ?? '',
          );
        }
      } catch (_) {}
    }

    return OfflineReadinessStatus(
      hasSafetyCache: safety != null && safety.isNotEmpty,
      hasMissionPack: mission != null && mission.isNotEmpty,
      safetyUpdatedAt: safetyUpdatedAt,
      missionUpdatedAt: missionUpdatedAt,
    );
  }

  static Future<Map<String, dynamic>?> getMissionPack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_missionPackKey);

      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> clearMissionPack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missionPackKey);
  }
}
