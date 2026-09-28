import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/fisherman_models.dart';
import '../../services/fisherman_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import 'vessel_form_screen.dart';

class VesselListScreen extends StatefulWidget {
  const VesselListScreen({super.key});

  @override
  State<VesselListScreen> createState() => _VesselListScreenState();
}

class _VesselListScreenState extends State<VesselListScreen> {
  bool loading = true;
  String? error;
  List<VesselData> vessels = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await FishermanService.getVessels();

      if (!mounted) return;

      setState(() => vessels = result);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openForm([VesselData? vessel]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VesselFormScreen(vessel: vessel)),
    );

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete(VesselData vessel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete vessel?'),
          content: Text('Remove "${vessel.name}" from your ORCA account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FishermanService.deleteVessel(vessel.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vessel deleted.')));

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vessels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.charcoal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Vessel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: GridBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _errorView()
            : vessels.isEmpty
            ? _emptyView()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  itemCount: vessels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _vesselCard(vessels[index]);
                  },
                ),
              ),
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
            const OrcaMascot(size: 96, mood: MascotMood.sleepy),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OrcaMascot(size: 120, mood: MascotMood.calm, halo: true),
            const SizedBox(height: 18),
            const Text(
              'No vessel added yet',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your vessel once so ORCA can reuse its '
              'speed, dimensions and usual persons onboard '
              'for future trip planning and safety workflows.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add My Vessel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vesselCard(VesselData vessel) {
    final details = <String>[
      if (vessel.vesselType != null) vessel.vesselType!,
      if (vessel.cruisingSpeedKnots != null)
        '${vessel.cruisingSpeedKnots!.toStringAsFixed(1)} kn',
      '${vessel.personsOnboardDefault} person(s)',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg - 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftIcon(
            Icons.sailing_rounded,
            color: AppTheme.coralDeep,
            background: AppTheme.coralSoft,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vessel.name,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (vessel.registrationNumber != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lavenderSoft,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      vessel.registrationNumber!,
                      style: const TextStyle(
                        color: AppTheme.indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openForm(vessel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.charcoal,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _delete(vessel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
