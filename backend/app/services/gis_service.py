from __future__ import annotations

import heapq
import json
import math
from datetime import datetime, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from app.services import land_mask

from app.schemas.gis import (
    BoundaryCheckResponse,
    BoundaryZone,
    MaritimeZoneAssessment,
    RouteAlternative,
    RouteCondition,
    RoutePlanResponse,
    RouteWaypoint,
)


EARTH_RADIUS_KM = 6371.0088
KM_PER_NM = 1.852
MS_TO_KNOTS = 1.94384449

MARINE_ENDPOINT = "https://marine-api.open-meteo.com/v1/marine"
WEATHER_ENDPOINT = "https://api.open-meteo.com/v1/forecast"

MARINE_REGIONS_WFS = "https://geo.vliz.be/geoserver/MarineRegions/wfs"

# Marine Regions reference identifiers verified for the India-focused prototype.
# Main Indian polygons also cover the western/eastern mainland reference area;
# Andaman & Nicobar is represented separately in Marine Regions.
INDIA_TERRITORIAL_ZONES = (
    (49194, "Indian 12 NM"),
    (49060, "Indian 12 NM (Andaman and Nicobar Islands)"),
)
INDIA_EEZ_ZONES = (
    (8480, "Indian Exclusive Economic Zone"),
    (8333, "Indian Exclusive Economic Zone (Andaman and Nicobar Islands)"),
)

_MR_CACHE: dict[str, object] = {}
_COAST_CACHE: dict[tuple[float, float], float | None] = {}

# Synthetic demo fixtures only. Coordinates are [longitude, latitude].
DEMO_ZONES = [
    BoundaryZone(
        id="demo-zone-a",
        name="DEMO Restricted Zone A",
        category="DEMO_RESTRICTED",
        coordinates=[
            [69.10, 20.45],
            [69.55, 20.45],
            [69.55, 20.78],
            [69.10, 20.78],
            [69.10, 20.45],
        ],
        note="Synthetic hackathon geofence. Not an official legal boundary.",
    ),
    BoundaryZone(
        id="demo-zone-b",
        name="DEMO Sensitive Zone B",
        category="DEMO_SENSITIVE",
        coordinates=[
            [68.45, 19.85],
            [68.85, 19.85],
            [68.85, 20.15],
            [68.45, 20.15],
            [68.45, 19.85],
        ],
        note="Synthetic hackathon geofence. Replace with validated GIS data.",
    ),
]


def list_zones() -> list[BoundaryZone]:
    return DEMO_ZONES


def surface_type(latitude: float, longitude: float) -> str:
    return "WATER" if bool(land_mask.is_ocean(latitude, longitude)) else "LAND"


def _rad(value: float) -> float:
    return math.radians(value)


def _angular_diff(a: float, b: float) -> float:
    return abs((a - b + 180.0) % 360.0 - 180.0)


def _haversine_km(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:
    p1 = _rad(lat1)
    p2 = _rad(lat2)
    dphi = _rad(lat2 - lat1)
    dlambda = _rad(lon2 - lon1)

    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(dlambda / 2) ** 2
    )
    return 2 * EARTH_RADIUS_KM * math.asin(min(1.0, math.sqrt(a)))


def _bearing_deg(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:
    p1 = _rad(lat1)
    p2 = _rad(lat2)
    dlambda = _rad(lon2 - lon1)
    y = math.sin(dlambda) * math.cos(p2)
    x = (
        math.cos(p1) * math.sin(p2)
        - math.sin(p1) * math.cos(p2) * math.cos(dlambda)
    )
    return (math.degrees(math.atan2(y, x)) + 360.0) % 360.0


def _point_in_polygon(
    latitude: float,
    longitude: float,
    coordinates: list[list[float]],
) -> bool:
    x = longitude
    y = latitude
    inside = False

    for i in range(len(coordinates) - 1):
        x1, y1 = coordinates[i]
        x2, y2 = coordinates[i + 1]

        if ((y1 > y) != (y2 > y)):
            crossing_x = (
                (x2 - x1) * (y - y1) / ((y2 - y1) or 1e-12) + x1
            )
            if x < crossing_x:
                inside = not inside

    return inside


def _segment_distance_gc_km(
    p_lat: float,
    p_lon: float,
    a_lat: float,
    a_lon: float,
    b_lat: float,
    b_lon: float,
) -> float:
    # Spherical cross-track / along-track distance.
    d13 = _haversine_km(a_lat, a_lon, p_lat, p_lon) / EARTH_RADIUS_KM
    d12 = _haversine_km(a_lat, a_lon, b_lat, b_lon) / EARTH_RADIUS_KM

    if d12 <= 1e-12:
        return _haversine_km(p_lat, p_lon, a_lat, a_lon)

    theta13 = _rad(_bearing_deg(a_lat, a_lon, p_lat, p_lon))
    theta12 = _rad(_bearing_deg(a_lat, a_lon, b_lat, b_lon))

    sin_xt = math.sin(d13) * math.sin(theta13 - theta12)
    sin_xt = max(-1.0, min(1.0, sin_xt))
    dxt = math.asin(sin_xt)

    dat = math.atan2(
        math.sin(d13) * math.cos(theta13 - theta12),
        math.cos(d13),
    )

    if dat < 0 or dat > d12:
        return min(
            _haversine_km(p_lat, p_lon, a_lat, a_lon),
            _haversine_km(p_lat, p_lon, b_lat, b_lon),
        )

    return abs(dxt) * EARTH_RADIUS_KM


def _distance_to_polygon_km(
    latitude: float,
    longitude: float,
    coordinates: list[list[float]],
) -> float:
    if _point_in_polygon(latitude, longitude, coordinates):
        return 0.0

    distances: list[float] = []

    for i in range(len(coordinates) - 1):
        lon1, lat1 = coordinates[i]
        lon2, lat2 = coordinates[i + 1]
        distances.append(
            _segment_distance_gc_km(
                latitude,
                longitude,
                lat1,
                lon1,
                lat2,
                lon2,
            )
        )

    return min(distances)



def _destination_point(
    latitude: float,
    longitude: float,
    bearing_deg: float,
    distance_km: float,
) -> tuple[float, float]:
    angular = distance_km / EARTH_RADIUS_KM
    bearing = _rad(bearing_deg)
    lat1 = _rad(latitude)
    lon1 = _rad(longitude)

    lat2 = math.asin(
        math.sin(lat1) * math.cos(angular)
        + math.cos(lat1) * math.sin(angular) * math.cos(bearing)
    )
    lon2 = lon1 + math.atan2(
        math.sin(bearing) * math.sin(angular) * math.cos(lat1),
        math.cos(angular) - math.sin(lat1) * math.sin(lat2),
    )

    return math.degrees(lat2), ((math.degrees(lon2) + 540) % 360) - 180


def _distance_to_coastline_km(
    latitude: float,
    longitude: float,
) -> float | None:
    """
    Approximate nearest coastline distance using the GLOBE-backed
    global-land-mask. This is operationally useful proximity context,
    not a hydrographic/chart-quality coastline measurement.
    """
    key = (round(latitude, 3), round(longitude, 3))

    if key in _COAST_CACHE:
        return _COAST_CACHE[key]

    if surface_type(latitude, longitude) == "LAND":
        _COAST_CACHE[key] = 0.0
        return 0.0

    bearings = list(range(0, 360, 5))
    rings = (1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0, 512.0)
    previous_ring = 0.0

    for ring in rings:
        land_bearings: list[float] = []

        for bearing in bearings:
            lat2, lon2 = _destination_point(
                latitude,
                longitude,
                float(bearing),
                ring,
            )

            if not bool(land_mask.is_ocean(lat2, lon2)):
                land_bearings.append(float(bearing))

        if land_bearings:
            best = ring

            for bearing in land_bearings:
                low = previous_ring
                high = ring

                for _ in range(10):
                    mid = (low + high) / 2
                    lat2, lon2 = _destination_point(
                        latitude,
                        longitude,
                        bearing,
                        mid,
                    )

                    if bool(land_mask.is_ocean(lat2, lon2)):
                        low = mid
                    else:
                        high = mid

                best = min(best, high)

            result = round(best, 2)
            _COAST_CACHE[key] = result
            return result

        previous_ring = ring

    _COAST_CACHE[key] = None
    return None


def _mr_request(params: dict[str, object]) -> dict:
    encoded = urlencode(params)
    request = Request(
        f"{MARINE_REGIONS_WFS}?{encoded}",
        headers={
            "User-Agent": "ORCA-Hackathon/1.0",
            "Accept": "application/json",
        },
    )

    with urlopen(request, timeout=15) as response:
        payload = json.loads(response.read().decode("utf-8"))

    if not isinstance(payload, dict):
        raise ValueError("Marine Regions returned an unexpected response.")

    return payload


def _mr_geometries(
    layer: str,
    mrgid: int,
) -> list[dict]:
    key = f"{layer}:{mrgid}"

    cached = _MR_CACHE.get(key)
    if isinstance(cached, list):
        return cached

    payload = _mr_request(
        {
            "service": "WFS",
            "version": "1.0.0",
            "request": "GetFeature",
            "typeName": layer,
            "cql_filter": f"mrgid={mrgid}",
            "outputformat": "application/json",
            "srsName": "EPSG:4326",
        }
    )

    geometries: list[dict] = []

    for feature in payload.get("features") or []:
        if isinstance(feature, dict):
            geometry = feature.get("geometry")
            if isinstance(geometry, dict):
                geometries.append(geometry)

    _MR_CACHE[key] = geometries
    return geometries


def _polygon_contains(
    latitude: float,
    longitude: float,
    rings: list,
) -> bool:
    if not rings:
        return False

    outer = rings[0]
    if not _point_in_polygon(latitude, longitude, outer):
        return False

    for hole in rings[1:]:
        if _point_in_polygon(latitude, longitude, hole):
            return False

    return True


def _geometry_contains(
    latitude: float,
    longitude: float,
    geometry: dict,
) -> bool:
    kind = geometry.get("type")
    coordinates = geometry.get("coordinates") or []

    if kind == "Polygon":
        return _polygon_contains(latitude, longitude, coordinates)

    if kind == "MultiPolygon":
        return any(
            _polygon_contains(latitude, longitude, polygon)
            for polygon in coordinates
        )

    return False


def _inside_reference_zones(
    latitude: float,
    longitude: float,
    layer: str,
    zones: tuple[tuple[int, str], ...],
) -> tuple[bool, str | None, bool]:
    """
    Returns:
      inside, matched_name, data_available
    """
    data_available = False

    for mrgid, name in zones:
        geometries = _mr_geometries(layer, mrgid)

        if geometries:
            data_available = True

        for geometry in geometries:
            if _geometry_contains(latitude, longitude, geometry):
                return True, name, True

    return False, None, data_available


def _line_segment_distance_km(
    latitude: float,
    longitude: float,
    a: list[float],
    b: list[float],
) -> float:
    return _segment_distance_gc_km(
        latitude,
        longitude,
        float(a[1]),
        float(a[0]),
        float(b[1]),
        float(b[0]),
    )


def _geometry_line_distance_km(
    latitude: float,
    longitude: float,
    geometry: dict,
) -> float | None:
    kind = geometry.get("type")
    coordinates = geometry.get("coordinates") or []
    distances: list[float] = []

    def add_line(line: list) -> None:
        for index in range(len(line) - 1):
            distances.append(
                _line_segment_distance_km(
                    latitude,
                    longitude,
                    line[index],
                    line[index + 1],
                )
            )

    if kind == "LineString":
        add_line(coordinates)
    elif kind == "MultiLineString":
        for line in coordinates:
            add_line(line)

    return min(distances) if distances else None


def _nearest_eez_boundary_km(
    latitude: float,
    longitude: float,
) -> float | None:
    # Six degrees is comfortably larger than a typical 200 NM search radius
    # at Indian latitudes and keeps the WFS response bounded.
    tile_key = (
        round(latitude / 2) * 2,
        round(longitude / 2) * 2,
    )
    key = f"eez_boundaries:{tile_key[0]}:{tile_key[1]}"

    cached = _MR_CACHE.get(key)

    if isinstance(cached, list):
        geometries = cached
    else:
        span = 6.0
        payload = _mr_request(
            {
                "service": "WFS",
                "version": "1.0.0",
                "request": "GetFeature",
                "typeName": "eez_boundaries",
                "bbox": (
                    f"{longitude - span},{latitude - span},"
                    f"{longitude + span},{latitude + span},EPSG:4326"
                ),
                "maxFeatures": 500,
                "outputformat": "application/json",
                "srsName": "EPSG:4326",
            }
        )

        geometries = []

        for feature in payload.get("features") or []:
            if isinstance(feature, dict):
                geometry = feature.get("geometry")
                if isinstance(geometry, dict):
                    geometries.append(geometry)

        _MR_CACHE[key] = geometries

    distances = [
        value
        for geometry in geometries
        if (
            value := _geometry_line_distance_km(
                latitude,
                longitude,
                geometry,
            )
        )
        is not None
    ]

    return round(min(distances), 2) if distances else None


def _territorial_assessment(
    latitude: float,
    longitude: float,
    coast_distance_km: float | None,
) -> MaritimeZoneAssessment:
    try:
        inside, name, available = _inside_reference_zones(
            latitude,
            longitude,
            "eez_12nm",
            INDIA_TERRITORIAL_ZONES,
        )

        if not available:
            raise ValueError("Marine Regions territorial-sea feature unavailable.")

        indicative_limit = None

        if coast_distance_km is not None:
            indicative_limit = round(
                abs(22.224 - coast_distance_km),
                2,
            )

        return MaritimeZoneAssessment(
            label="Indian territorial sea (12 NM reference)",
            status="INSIDE" if inside else "OUTSIDE",
            zone_name=name,
            distance_to_limit_km=indicative_limit,
            distance_label=(
                "Approx. distance to the 12 NM band edge from coastline"
                if indicative_limit is not None
                else None
            ),
            source="Marine Regions Territorial Seas (12NM), version 4",
            source_note=(
                "Jurisdiction status uses the Marine Regions 12 NM polygon. "
                "The displayed distance is an indicative coastline-based 12 NM "
                "proximity calculation, not a legal baseline measurement."
            ),
        )
    except Exception:
        if coast_distance_km is None:
            return MaritimeZoneAssessment(
                label="Indian territorial sea (12 NM reference)",
                status="UNAVAILABLE",
                source="Marine Regions WFS",
                source_note=(
                    "The reference boundary service could not be reached and no "
                    "coast-distance fallback was available."
                ),
            )

        inside = coast_distance_km <= 22.224

        return MaritimeZoneAssessment(
            label="Indian territorial sea (12 NM reference)",
            status=(
                "INDICATIVE_INSIDE"
                if inside
                else "INDICATIVE_OUTSIDE"
            ),
            distance_to_limit_km=round(
                abs(22.224 - coast_distance_km),
                2,
            ),
            distance_label="Indicative distance to 12 NM band edge",
            source="Coast-distance fallback",
            source_note=(
                "Marine Regions was unavailable. This fallback uses distance "
                "from the approximate coastline and must not be treated as a "
                "legal territorial-sea determination."
            ),
        )


def _eez_assessment(
    latitude: float,
    longitude: float,
) -> MaritimeZoneAssessment:
    try:
        inside, name, available = _inside_reference_zones(
            latitude,
            longitude,
            "eez",
            INDIA_EEZ_ZONES,
        )

        if not available:
            raise ValueError("Marine Regions EEZ feature unavailable.")

        nearest_boundary = None

        try:
            nearest_boundary = _nearest_eez_boundary_km(
                latitude,
                longitude,
            )
        except Exception:
            nearest_boundary = None

        return MaritimeZoneAssessment(
            label="Indian Exclusive Economic Zone (EEZ reference)",
            status="INSIDE" if inside else "OUTSIDE",
            zone_name=name,
            distance_to_limit_km=nearest_boundary,
            distance_label=(
                "Distance to nearest Marine Regions EEZ boundary line"
                if nearest_boundary is not None
                else None
            ),
            source="Marine Regions World EEZ, version 12",
            source_note=(
                "Reference jurisdiction and boundary geometry from Marine Regions. "
                "Operational/legal navigation must still use current official charts "
                "and applicable notices."
            ),
        )
    except Exception:
        return MaritimeZoneAssessment(
            label="Indian Exclusive Economic Zone (EEZ reference)",
            status="UNAVAILABLE",
            source="Marine Regions WFS",
            source_note=(
                "The reference EEZ service could not be reached. ORCA does not "
                "invent an EEZ boundary when authoritative reference geometry is unavailable."
            ),
        )

def check_boundary(
    latitude: float,
    longitude: float,
) -> BoundaryCheckResponse:
    surface = surface_type(latitude, longitude)

    if surface == "LAND":
        return BoundaryCheckResponse(
            latitude=latitude,
            longitude=longitude,
            surface="LAND",
            status="LAND",
            coast_distance_km=0.0,
            coast_distance_note=(
                "Selected point is land. Coast-distance guidance is only "
                "meaningful for a vessel position on water."
            ),
            message=(
                "This point is on land and is not a navigable marine point. "
                "Select a point on water."
            ),
        )

    coast_distance = _distance_to_coastline_km(
        latitude,
        longitude,
    )

    territorial = _territorial_assessment(
        latitude,
        longitude,
        coast_distance,
    )

    eez = _eez_assessment(
        latitude,
        longitude,
    )

    nearest_zone = None
    nearest_distance = None
    demo_status = "CLEAR"
    demo_message = (
        "Water point is outside the current demo restricted/protected geofences."
    )

    for zone in DEMO_ZONES:
        if _point_in_polygon(
            latitude,
            longitude,
            zone.coordinates,
        ):
            demo_status = "INSIDE"
            nearest_zone = zone
            nearest_distance = 0.0
            demo_message = (
                f"This water point is inside {zone.name}. "
                "The polygon is synthetic demo data, not an official restriction."
            )
            break

        distance = _distance_to_polygon_km(
            latitude,
            longitude,
            zone.coordinates,
        )

        if nearest_distance is None or distance < nearest_distance:
            nearest_distance = distance
            nearest_zone = zone

    if (
        demo_status != "INSIDE"
        and nearest_distance is not None
        and nearest_distance <= 10
    ):
        demo_status = "NEAR"
        demo_message = (
            f"Water point is approximately {nearest_distance:.1f} km from "
            f"{nearest_zone.name if nearest_zone else 'a demo geofence'}."
        )

    return BoundaryCheckResponse(
        latitude=latitude,
        longitude=longitude,
        surface="WATER",
        status=demo_status,
        coast_distance_km=coast_distance,
        coast_distance_note=(
            "Approximate nearest coastline distance derived from the "
            "GLOBE-based land/water mask."
            if coast_distance is not None
            else "No coastline was found within the current 512 km search radius."
        ),
        territorial_sea=territorial,
        eez=eez,
        nearest_zone_id=(
            nearest_zone.id
            if nearest_zone is not None
            else None
        ),
        nearest_zone_name=(
            nearest_zone.name
            if nearest_zone is not None
            else None
        ),
        distance_to_zone_km=(
            round(nearest_distance, 2)
            if nearest_distance is not None
            else None
        ),
        inside_zone=demo_status == "INSIDE",
        message=demo_message,
    )



def _request_json(base_url: str, params: dict) -> object:
    url = f"{base_url}?{urlencode(params)}"
    req = Request(
        url,
        headers={
            "User-Agent": "ORCA-Hackathon/1.0",
            "Accept": "application/json",
        },
    )
    with urlopen(req, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def _chunks(items: list, size: int):
    for i in range(0, len(items), size):
        yield items[i:i + size]


def _num(data: dict, key: str) -> float | None:
    value = data.get(key)
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None



def _fetch_conditions_batch(
    points: list[tuple[float, float]],
) -> list[RouteCondition]:
    results: list[RouteCondition] = []

    for batch in _chunks(points, 80):
        lats = ",".join(f"{lat:.6f}" for lat, _ in batch)
        lons = ",".join(f"{lon:.6f}" for _, lon in batch)

        marine = _request_json(
            MARINE_ENDPOINT,
            {
                "latitude": lats,
                "longitude": lons,
                "current": (
                    "wave_height,wave_direction,wave_period,"
                    "ocean_current_velocity,ocean_current_direction"
                ),
                "velocity_unit": "ms",
                "cell_selection": "sea",
            },
        )

        weather = _request_json(
            WEATHER_ENDPOINT,
            {
                "latitude": lats,
                "longitude": lons,
                "current": (
                    "wind_speed_10m,wind_direction_10m,wind_gusts_10m"
                ),
                "wind_speed_unit": "ms",
                "cell_selection": "sea",
            },
        )

        marine_list = marine if isinstance(marine, list) else [marine]
        weather_list = weather if isinstance(weather, list) else [weather]

        for index, _ in enumerate(batch):
            m = marine_list[index] if index < len(marine_list) else {}
            w = weather_list[index] if index < len(weather_list) else {}
            mc = (m or {}).get("current") or {}
            wc = (w or {}).get("current") or {}

            results.append(
                RouteCondition(
                    wave_height_m=_num(mc, "wave_height"),
                    wave_direction_deg=_num(mc, "wave_direction"),
                    wave_period_s=_num(mc, "wave_period"),
                    wind_speed_ms=_num(wc, "wind_speed_10m"),
                    wind_direction_deg=_num(wc, "wind_direction_10m"),
                    wind_gust_ms=_num(wc, "wind_gusts_10m"),
                    current_velocity_ms=_num(mc, "ocean_current_velocity"),
                    current_direction_deg=_num(mc, "ocean_current_direction"),
                )
            )

    return results


def _orientation(
    ax: float,
    ay: float,
    bx: float,
    by: float,
    cx: float,
    cy: float,
) -> float:
    return (by - ay) * (cx - bx) - (bx - ax) * (cy - by)


def _on_segment(
    ax: float,
    ay: float,
    bx: float,
    by: float,
    cx: float,
    cy: float,
) -> bool:
    return (
        min(ax, cx) <= bx <= max(ax, cx)
        and min(ay, cy) <= by <= max(ay, cy)
    )


def _segments_intersect(
    p1: tuple[float, float],
    p2: tuple[float, float],
    q1: tuple[float, float],
    q2: tuple[float, float],
) -> bool:
    x1, y1 = p1
    x2, y2 = p2
    x3, y3 = q1
    x4, y4 = q2

    o1 = _orientation(x1, y1, x2, y2, x3, y3)
    o2 = _orientation(x1, y1, x2, y2, x4, y4)
    o3 = _orientation(x3, y3, x4, y4, x1, y1)
    o4 = _orientation(x3, y3, x4, y4, x2, y2)

    if (o1 > 0) != (o2 > 0) and (o3 > 0) != (o4 > 0):
        return True

    eps = 1e-12

    if abs(o1) < eps and _on_segment(x1, y1, x3, y3, x2, y2):
        return True
    if abs(o2) < eps and _on_segment(x1, y1, x4, y4, x2, y2):
        return True
    if abs(o3) < eps and _on_segment(x3, y3, x1, y1, x4, y4):
        return True
    if abs(o4) < eps and _on_segment(x3, y3, x2, y2, x4, y4):
        return True

    return False


def _edge_hits_demo_zone(
    a_lat: float,
    a_lon: float,
    b_lat: float,
    b_lon: float,
) -> bool:
    route_a = (a_lon, a_lat)
    route_b = (b_lon, b_lat)

    for zone in DEMO_ZONES:
        if _point_in_polygon(a_lat, a_lon, zone.coordinates):
            return True
        if _point_in_polygon(b_lat, b_lon, zone.coordinates):
            return True

        for i in range(len(zone.coordinates) - 1):
            q1 = tuple(zone.coordinates[i])
            q2 = tuple(zone.coordinates[i + 1])
            if _segments_intersect(route_a, route_b, q1, q2):
                return True

    return False



def _edge_is_water(
    a_lat: float,
    a_lon: float,
    b_lat: float,
    b_lon: float,
) -> bool:
    # Sample the segment so diagonal grid moves cannot cut across land.
    for step in range(1, 6):
        t = step / 6
        lat = a_lat + (b_lat - a_lat) * t
        lon = a_lon + (b_lon - a_lon) * t

        if surface_type(lat, lon) != "WATER":
            return False

    return True


def _build_grid(
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    n: int = 11,
) -> tuple[dict[tuple[int, int], tuple[float, float]], tuple[int, int], tuple[int, int]]:
    lat_span = max(abs(end_lat - start_lat), 0.18)
    lon_span = max(abs(end_lon - start_lon), 0.18)

    lat_margin = max(0.10, lat_span * 0.28)
    lon_margin = max(0.10, lon_span * 0.28)

    min_lat = min(start_lat, end_lat) - lat_margin
    max_lat = max(start_lat, end_lat) + lat_margin
    min_lon = min(start_lon, end_lon) - lon_margin
    max_lon = max(start_lon, end_lon) + lon_margin

    lats = [
        min_lat + (max_lat - min_lat) * i / (n - 1)
        for i in range(n)
    ]
    lons = [
        min_lon + (max_lon - min_lon) * j / (n - 1)
        for j in range(n)
    ]

    nodes: dict[tuple[int, int], tuple[float, float]] = {}

    for i, lat in enumerate(lats):
        for j, lon in enumerate(lons):
            if surface_type(lat, lon) == "WATER":
                nodes[(i, j)] = (lat, lon)

    def nearest_key(lat: float, lon: float) -> tuple[int, int]:
        candidates = sorted(
            nodes.items(),
            key=lambda item: _haversine_km(
                lat,
                lon,
                item[1][0],
                item[1][1],
            ),
        )

        for key, (node_lat, node_lon) in candidates:
            if _edge_is_water(
                lat,
                lon,
                node_lat,
                node_lon,
            ):
                return key

        raise ValueError(
            "No water-connected route grid could be generated near the selected point."
        )

    return (
        nodes,
        nearest_key(start_lat, start_lon),
        nearest_key(end_lat, end_lon),
    )


def _node_neighbors(
    key: tuple[int, int],
    nodes: dict[tuple[int, int], tuple[float, float]],
):
    i, j = key

    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            if di == 0 and dj == 0:
                continue

            candidate = (i + di, j + dj)
            if candidate in nodes:
                yield candidate


def _edge_metrics(
    a: tuple[float, float],
    b: tuple[float, float],
    condition: RouteCondition,
    base_speed_knots: float,
) -> tuple[float, float, float]:
    a_lat, a_lon = a
    b_lat, b_lon = b

    distance_nm = _haversine_km(
        a_lat,
        a_lon,
        b_lat,
        b_lon,
    ) / KM_PER_NM

    heading = _bearing_deg(
        a_lat,
        a_lon,
        b_lat,
        b_lon,
    )

    current_along_knots = 0.0

    if (
        condition.current_velocity_ms is not None
        and condition.current_direction_deg is not None
    ):
        diff = _rad(
            _angular_diff(
                heading,
                condition.current_direction_deg,
            )
        )
        current_along_knots = (
            condition.current_velocity_ms
            * MS_TO_KNOTS
            * math.cos(diff)
        )

    wave = condition.wave_height_m or 0.0
    wind = condition.wind_speed_ms or 0.0
    gust = condition.wind_gust_ms or wind

    head_wave = 0.0
    if condition.wave_direction_deg is not None:
        head_wave = max(
            0.0,
            math.cos(
                _rad(
                    _angular_diff(
                        heading,
                        condition.wave_direction_deg,
                    )
                )
            ),
        )

    head_wind = 0.0
    if condition.wind_direction_deg is not None:
        head_wind = max(
            0.0,
            math.cos(
                _rad(
                    _angular_diff(
                        heading,
                        condition.wind_direction_deg,
                    )
                )
            ),
        )

    performance_penalty_knots = (
        0.35 * wave * (1.0 + 0.7 * head_wave)
        + 0.025 * wind * (1.0 + 0.5 * head_wind)
    )

    effective_speed = max(
        1.0,
        base_speed_knots
        + current_along_knots
        - performance_penalty_knots,
    )

    time_minutes = distance_nm / effective_speed * 60.0

    exposure = (
        distance_nm
        * (
            2.2 * (wave ** 2) * (1.0 + 0.8 * head_wave)
            + 0.12 * wind * (1.0 + 0.5 * head_wind)
            + 0.05 * gust
        )
    )

    return distance_nm, time_minutes, exposure


def _astar(
    nodes: dict[tuple[int, int], tuple[float, float]],
    start: tuple[int, int],
    goal: tuple[int, int],
    conditions: dict[tuple[int, int], RouteCondition],
    base_speed_knots: float,
    mode: str,
) -> list[tuple[int, int]]:
    frontier: list[tuple[float, tuple[int, int]]] = [(0.0, start)]
    came_from: dict[tuple[int, int], tuple[int, int] | None] = {
        start: None
    }
    cost_so_far: dict[tuple[int, int], float] = {
        start: 0.0
    }

    while frontier:
        _, current = heapq.heappop(frontier)

        if current == goal:
            break

        for nxt in _node_neighbors(current, nodes):
            a = nodes[current]
            b = nodes[nxt]

            if not _edge_is_water(a[0], a[1], b[0], b[1]):
                continue

            if _edge_hits_demo_zone(a[0], a[1], b[0], b[1]):
                continue

            condition = conditions.get(
                nxt,
                RouteCondition(),
            )

            _, time_minutes, exposure = _edge_metrics(
                a,
                b,
                condition,
                base_speed_knots,
            )

            if mode == "FASTEST":
                step_cost = time_minutes + exposure * 0.10
            else:
                step_cost = time_minutes + exposure * 0.55

            new_cost = cost_so_far[current] + step_cost

            if nxt not in cost_so_far or new_cost < cost_so_far[nxt]:
                cost_so_far[nxt] = new_cost

                goal_lat, goal_lon = nodes[goal]
                next_lat, next_lon = nodes[nxt]

                heuristic_minutes = (
                    _haversine_km(
                        next_lat,
                        next_lon,
                        goal_lat,
                        goal_lon,
                    )
                    / KM_PER_NM
                    / max(base_speed_knots, 1.0)
                    * 60.0
                )

                priority = new_cost + heuristic_minutes
                heapq.heappush(
                    frontier,
                    (priority, nxt),
                )
                came_from[nxt] = current

    if goal not in came_from:
        raise ValueError(
            "No water-only route could be found within the current search grid."
        )

    path = []
    current = goal

    while current is not None:
        path.append(current)
        current = came_from[current]

    path.reverse()
    return path



def _route_alternative(
    route_id: str,
    title: str,
    path: list[tuple[int, int]],
    nodes: dict[tuple[int, int], tuple[float, float]],
    conditions: dict[tuple[int, int], RouteCondition],
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    base_speed_knots: float,
) -> RouteAlternative:
    coords: list[tuple[float, float, RouteCondition]] = []

    first_key = path[0]
    last_key = path[-1]

    coords.append(
        (
            start_lat,
            start_lon,
            conditions.get(first_key, RouteCondition()),
        )
    )

    for key in path:
        lat, lon = nodes[key]

        if _haversine_km(
            coords[-1][0],
            coords[-1][1],
            lat,
            lon,
        ) > 0.25:
            coords.append(
                (
                    lat,
                    lon,
                    conditions.get(key, RouteCondition()),
                )
            )

    if _haversine_km(
        coords[-1][0],
        coords[-1][1],
        end_lat,
        end_lon,
    ) > 0.25:
        coords.append(
            (
                end_lat,
                end_lon,
                conditions.get(last_key, RouteCondition()),
            )
        )
    else:
        coords[-1] = (
            end_lat,
            end_lon,
            coords[-1][2],
        )

    total_distance_nm = 0.0
    total_eta_minutes = 0.0
    total_exposure = 0.0

    waves: list[float] = []
    winds: list[float] = []
    gusts: list[float] = []
    currents: list[float] = []

    waypoints: list[RouteWaypoint] = []

    for index, (lat, lon, condition) in enumerate(coords):
        waypoints.append(
            RouteWaypoint(
                latitude=round(lat, 6),
                longitude=round(lon, 6),
                sequence=index,
                condition=condition,
            )
        )

        if condition.wave_height_m is not None:
            waves.append(condition.wave_height_m)
        if condition.wind_speed_ms is not None:
            winds.append(condition.wind_speed_ms)
        if condition.wind_gust_ms is not None:
            gusts.append(condition.wind_gust_ms)
        if condition.current_velocity_ms is not None:
            currents.append(condition.current_velocity_ms)

        if index == 0:
            continue

        previous = coords[index - 1]

        distance_nm, time_minutes, exposure = _edge_metrics(
            (previous[0], previous[1]),
            (lat, lon),
            condition,
            base_speed_knots,
        )

        total_distance_nm += distance_nm
        total_eta_minutes += time_minutes
        total_exposure += exposure

    max_wave = max(waves) if waves else None
    max_wind = max(winds) if winds else None
    max_gust = max(gusts) if gusts else None
    avg_current = sum(currents) / len(currents) if currents else None

    status = "LOW"

    if (
        (max_wave is not None and max_wave >= 2.5)
        or (max_wind is not None and max_wind >= 15.0)
        or (max_gust is not None and max_gust >= 18.0)
    ):
        status = "HIGH"
    elif (
        (max_wave is not None and max_wave >= 1.5)
        or (max_wind is not None and max_wind >= 10.0)
        or (max_gust is not None and max_gust >= 13.0)
    ):
        status = "CAUTION"

    rationale = [
        "Water-only grid: land cells are treated as impassable.",
        "Loaded demo geofences are treated as impassable route edges.",
        "ETA accounts for vessel cruise speed, along-route ocean current, "
        "and prototype wave/wind performance penalties.",
    ]

    if route_id == "lower_exposure":
        rationale.append(
            "Route cost places stronger weight on wave height, relative wave "
            "direction, wind, gusts, and exposure distance."
        )
    else:
        rationale.append(
            "Route cost prioritizes travel time while still penalizing "
            "rougher conditions."
        )

    if max_wave is not None:
        rationale.append(
            f"Maximum sampled wave height along this route: {max_wave:.1f} m."
        )

    if avg_current is not None:
        rationale.append(
            f"Average sampled current magnitude: {avg_current:.2f} m/s."
        )

    route_message = (
        "Current sampled conditions are within the prototype LOW screening band."
        if status == "LOW"
        else (
            "Current sampled conditions include moderate exposure. "
            "Review official advisories before departure."
            if status == "CAUTION"
            else (
                "Current sampled conditions include high wave/wind exposure. "
                "Do not rely on this prototype for a go/no-go decision."
            )
        )
    )

    exposure_score = (
        total_exposure / max(total_distance_nm, 0.1)
    )

    return RouteAlternative(
        route_id=route_id,
        title=title,
        distance_nm=round(total_distance_nm, 2),
        eta_minutes=round(total_eta_minutes, 1),
        exposure_score=round(exposure_score, 2),
        max_wave_height_m=(
            round(max_wave, 2)
            if max_wave is not None
            else None
        ),
        max_wind_speed_ms=(
            round(max_wind, 2)
            if max_wind is not None
            else None
        ),
        max_wind_gust_ms=(
            round(max_gust, 2)
            if max_gust is not None
            else None
        ),
        average_current_ms=(
            round(avg_current, 3)
            if avg_current is not None
            else None
        ),
        route_status=status,
        route_message=route_message,
        rationale=rationale,
        waypoints=waypoints,
    )


def plan_weather_aware_route(
    start_latitude: float,
    start_longitude: float,
    end_latitude: float,
    end_longitude: float,
    cruising_speed_knots: float,
) -> RoutePlanResponse:
    start_surface = surface_type(
        start_latitude,
        start_longitude,
    )
    end_surface = surface_type(
        end_latitude,
        end_longitude,
    )

    if start_surface != "WATER":
        raise ValueError(
            "Start point is on land. Choose a water start point or wait until the vessel is afloat."
        )

    if end_surface != "WATER":
        raise ValueError(
            "Destination is on land. Choose a navigable water destination."
        )

    nodes, start_key, goal_key = _build_grid(
        start_latitude,
        start_longitude,
        end_latitude,
        end_longitude,
    )

    node_keys = list(nodes.keys())
    node_points = [nodes[key] for key in node_keys]

    sampled = _fetch_conditions_batch(node_points)

    conditions = {
        key: sampled[index]
        for index, key in enumerate(node_keys)
    }

    fastest_path = _astar(
        nodes,
        start_key,
        goal_key,
        conditions,
        cruising_speed_knots,
        mode="FASTEST",
    )

    lower_exposure_path = _astar(
        nodes,
        start_key,
        goal_key,
        conditions,
        cruising_speed_knots,
        mode="LOWER_EXPOSURE",
    )

    fastest = _route_alternative(
        "fastest",
        "Faster Route",
        fastest_path,
        nodes,
        conditions,
        start_latitude,
        start_longitude,
        end_latitude,
        end_longitude,
        cruising_speed_knots,
    )

    lower_exposure = _route_alternative(
        "lower_exposure",
        "Lower-Exposure Route",
        lower_exposure_path,
        nodes,
        conditions,
        start_latitude,
        start_longitude,
        end_latitude,
        end_longitude,
        cruising_speed_knots,
    )

    return RoutePlanResponse(
        start_surface=start_surface,
        end_surface=end_surface,
        fastest=fastest,
        lower_exposure=lower_exposure,
        data_source=(
            "Open-Meteo Marine API + Open-Meteo Weather API "
            "(development live model adapter)"
        ),
        data_freshness=(
            f"Route grid sampled at {datetime.now(timezone.utc).isoformat()}"
        ),
        model_note=(
            "The A* cost grid uses current model conditions. Wave directions are "
            "treated as directions waves come from; ocean-current directions follow "
            "the flow direction. This is a hackathon routing model, not a certified "
            "marine-navigation system."
        ),
        demo_boundary_note=(
            "Geofence polygons are synthetic demo fixtures. Official/legal "
            "boundary layers must replace them before operational deployment."
        ),
    )
