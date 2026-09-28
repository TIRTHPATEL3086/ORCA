param(
    [string]$Root = "C:\Users\ADMIN\dev\ORCA"
)

$ErrorActionPreference = "Stop"

$path = Join-Path $Root "marine_app\lib\screens\gis\plan_trip_screen.dart"

if (-not (Test-Path $path)) {
    throw "Could not find: $path"
}

$backup = "$path.phase13b1.bak"

if (-not (Test-Path $backup)) {
    Copy-Item $path $backup
    Write-Host "Backup created: $backup"
}

$content = Get-Content $path -Raw

function Require-Pattern([string]$Pattern, [string]$Message) {
    if (-not $content.Contains($Pattern)) {
        throw $Message
    }
}

# 1. Import
if (-not $content.Contains("offline_readiness_service.dart")) {
    Require-Pattern `
        "import '../../services/gis_service.dart';" `
        "Could not find gis_service.dart import."

    $content = $content.Replace(
        "import '../../services/gis_service.dart';",
        "import '../../services/gis_service.dart';`r`nimport '../../services/offline_readiness_service.dart';"
    )
}

# 2. State fields
if (-not $content.Contains("String offlineReadiness = 'Checking offline readiness...';")) {
    Require-Pattern `
        "bool calculating = false;" `
        "Could not find calculating state field."

    $content = $content.Replace(
        "bool calculating = false;",
        "bool calculating = false;`r`n  bool preparingOffline = false;`r`n  String offlineReadiness = 'Checking offline readiness...';"
    )
}

# 3. Automatically maintain the Always-Ready Safety Cache whenever
#    fresh boundary/geofence geometry is successfully obtained.
if (-not $content.Contains("saveSafetyCacheBoundaries(loadedZones)")) {
    Require-Pattern `
        "final loadedZones = await GisService.getZones();" `
        "Could not find getZones() call."

    $content = $content.Replace(
        "final loadedZones = await GisService.getZones();",
        "final loadedZones = await GisService.getZones();`r`n`r`n      await OfflineReadinessService.saveSafetyCacheBoundaries(`r`n        loadedZones,`r`n      );"
    )
}

# 4. Set status after bootstrap completes.
if (-not $content.Contains("offlineReadiness = 'Safety Cache Ready'")) {
    $needle = @"
        zones = loadedZones;

        if (position != null) {
"@

    $replacement = @"
        zones = loadedZones;
        offlineReadiness = 'Safety Cache Ready';

        if (position != null) {
"@

    Require-Pattern $needle "Could not find zones assignment block."
    $content = $content.Replace($needle, $replacement)
}

# 5. Add helper before _startMission.
if (-not $content.Contains("Future<void> _prepareOfflineMissionPack(")) {
    $needle = "  Future<void> _startMission() async {"

    Require-Pattern $needle "Could not find _startMission()."

    $helper = @"
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


"@

    $content = $content.Replace(
        $needle,
        $helper + $needle
    )
}

# 6. After live route calculation, automatically build the local Mission Pack.
if (-not $content.Contains("_prepareOfflineMissionPack(") -or
    ($content.Split("_prepareOfflineMissionPack(").Count -lt 3)) {

    $needle = @"
      setState(() {
        plan = result;
        selectedRoute = initial;
      });

      final points = initial.waypoints
"@

    $replacement = @"
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
"@

    Require-Pattern $needle "Could not find route-result setState block."
    $content = $content.Replace($needle, $replacement)
}

# 7. Re-save the final selected route immediately before Mission Tracking.
if (-not $content.Contains("Final selected route is persisted before navigation.")) {
    $needle = @"
    if (route == null || speed == null || speed <= 0) {
      return;
    }

    await Navigator.of(context).push(
"@

    $replacement = @"
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

    await Navigator.of(context).push(
"@

    Require-Pattern $needle "Could not find start-mission navigation block."
    $content = $content.Replace($needle, $replacement)
}

# 8. Add an Offline Readiness card into the planner.
if (-not $content.Contains("Widget _offlineReadinessCard()")) {
    $needle = "  Widget _errorView() {"

    Require-Pattern $needle "Could not find _errorView()."

    $widget = @"
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
              full
                  ? Icons.offline_pin_rounded
                  : Icons.shield_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  full
                      ? 'Offline Ready'
                      : 'Always-Ready Safety Cache',
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


"@

    $content = $content.Replace(
        $needle,
        $widget + $needle
    )
}

# 9. Insert card near the top of the content list.
if (-not $content.Contains("_offlineReadinessCard(),")) {
    $needle = @"
      children: [
        Container(
"@

    $replacement = @"
      children: [
        _offlineReadinessCard(),
        const SizedBox(height: 12),
        Container(
"@

    Require-Pattern $needle "Could not find _content() children list."
    $content = $content.Replace($needle, $replacement)
}

Set-Content -Path $path -Value $content -Encoding UTF8

Write-Host ""
Write-Host "Phase 13B1 patch applied successfully." -ForegroundColor Green
Write-Host "Modified: $path"
Write-Host "Backup:   $backup"
Write-Host ""
Write-Host "Next:"
Write-Host "  cd $Root\marine_app"
Write-Host "  flutter analyze"
