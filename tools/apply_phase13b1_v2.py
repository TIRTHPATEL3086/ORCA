from __future__ import annotations

from pathlib import Path
import re
import shutil
import sys

ROOT = Path(r"C:\Users\ADMIN\dev\ORCA")
if len(sys.argv) > 1:
    ROOT = Path(sys.argv[1])

path = ROOT / "marine_app" / "lib" / "screens" / "gis" / "plan_trip_screen.dart"

if not path.exists():
    raise SystemExit(f"Could not find: {path}")

backup = path.with_suffix(path.suffix + ".phase13b1.bak")
if not backup.exists():
    shutil.copy2(path, backup)
    print(f"Backup created: {backup}")

text = path.read_text(encoding="utf-8")

def require(pattern: str, label: str):
    if not re.search(pattern, text, flags=re.S):
        raise SystemExit(f"Could not find {label}.")

# 1) import
if "offline_readiness_service.dart" not in text:
    require(r"import\s+'../../services/gis_service\.dart';", "gis_service import")
    text = re.sub(
        r"(import\s+'../../services/gis_service\.dart';)",
        r"\1\nimport '../../services/offline_readiness_service.dart';",
        text,
        count=1,
    )

# 2) state fields
if "String offlineReadiness = 'Checking offline readiness...';" not in text:
    require(r"bool\s+calculating\s*=\s*false\s*;", "calculating state field")
    text = re.sub(
        r"(bool\s+calculating\s*=\s*false\s*;)",
        r"\1\n  bool preparingOffline = false;\n  String offlineReadiness = 'Checking offline readiness...';",
        text,
        count=1,
    )

# 3) cache boundary/geofence data automatically
if "saveSafetyCacheBoundaries(" not in text:
    require(
        r"final\s+loadedZones\s*=\s*await\s+GisService\.getZones\(\)\s*;",
        "getZones() call",
    )
    text = re.sub(
        r"(final\s+loadedZones\s*=\s*await\s+GisService\.getZones\(\)\s*;)",
        "\\1\n\n      await OfflineReadinessService.saveSafetyCacheBoundaries(\n        loadedZones,\n      );",
        text,
        count=1,
    )

# 4) update readiness after zones load
if "offlineReadiness = 'Safety Cache Ready';" not in text:
    require(r"zones\s*=\s*loadedZones\s*;", "zones assignment")
    text = re.sub(
        r"(zones\s*=\s*loadedZones\s*;)",
        r"\1\n        offlineReadiness = 'Safety Cache Ready';",
        text,
        count=1,
    )

# 5) helper before _startMission
if "Future<void> _prepareOfflineMissionPack(" not in text:
    require(r"Future<void>\s+_startMission\(\)\s+async\s*\{", "_startMission()")

    helper = """
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

"""
    text = re.sub(
        r"\s*Future<void>\s+_startMission\(\)\s+async\s*\{",
        "\n" + helper + "\n  Future<void> _startMission() async {",
        text,
        count=1,
    )

# 6) automatically save pack after successful route calculation
if text.count("_prepareOfflineMissionPack(") < 2:
    pattern = re.compile(
        r"setState\(\(\)\s*\{\s*plan\s*=\s*result\s*;\s*selectedRoute\s*=\s*initial\s*;\s*\}\s*\)\s*;\s*(?=final\s+points\s*=)",
        re.S,
    )
    if not pattern.search(text):
        raise SystemExit("Could not find route result setState block.")

    replacement = """setState(() {
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

      """
    text = pattern.sub(replacement, text, count=1)

# 7) persist final selected route immediately before navigation
if "Final selected route is persisted before navigation." not in text:
    pattern = re.compile(
        r"if\s*\(\s*route\s*==\s*null\s*\|\|\s*speed\s*==\s*null\s*\|\|\s*speed\s*<=\s*0\s*\)\s*\{\s*return\s*;\s*\}\s*(?=await\s+Navigator\.of\(context\)\.push)",
        re.S,
    )
    if not pattern.search(text):
        raise SystemExit("Could not find start-mission validation block.")

    replacement = """if (route == null || speed == null || speed <= 0) {
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

    """
    text = pattern.sub(replacement, text, count=1)

# 8) readiness card widget before _errorView
if "Widget _offlineReadinessCard()" not in text:
    require(r"Widget\s+_errorView\(\)\s*\{", "_errorView()")

    widget = """
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

"""

    text = re.sub(
        r"\s*Widget\s+_errorView\(\)\s*\{",
        "\n" + widget + "\n  Widget _errorView() {",
        text,
        count=1,
    )

# 9) insert card specifically into _content()
if "_offlineReadinessCard()," not in text:
    m = re.search(r"Widget\s+_content\(\)\s*\{", text)
    if not m:
        raise SystemExit("Could not find _content().")

    list_idx = text.find("return ListView(", m.start())
    if list_idx < 0:
        raise SystemExit("Could not find ListView in _content().")

    children_idx = text.find("children: [", list_idx)
    if children_idx < 0:
        raise SystemExit("Could not find children list in _content().")

    insert_at = children_idx + len("children: [")
    text = (
        text[:insert_at]
        + "\n        _offlineReadinessCard(),\n"
          "        const SizedBox(height: 12),"
        + text[insert_at:]
    )

path.write_text(text, encoding="utf-8")

print()
print("Phase 13B1 patch applied successfully.")
print(f"Modified: {path}")
print(f"Backup:   {backup}")
print()
print("Now run:")
print(r"  cd C:\Users\ADMIN\dev\ORCA\marine_app")
print("  flutter analyze")
