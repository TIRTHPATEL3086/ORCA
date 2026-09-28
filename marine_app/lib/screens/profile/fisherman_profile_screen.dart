import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/fisherman_models.dart';
import '../../services/fisherman_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';
import '../vessel/vessel_list_screen.dart';

class FishermanProfileScreen extends StatefulWidget {
  const FishermanProfileScreen({super.key});

  @override
  State<FishermanProfileScreen> createState() => _FishermanProfileScreenState();
}

class _FishermanProfileScreenState extends State<FishermanProfileScreen> {
  final nameController = TextEditingController();
  final landingCentreController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final languageController = TextEditingController();

  FishermanProfileData? profile;
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameController.dispose();
    landingCentreController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    languageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await FishermanService.getProfile();

      if (!mounted) return;

      profile = result;
      nameController.text = result.fullName;
      landingCentreController.text = result.homeLandingCentre ?? '';
      emergencyNameController.text = result.emergencyContactName ?? '';
      emergencyPhoneController.text = result.emergencyContactPhone ?? '';
      languageController.text = result.preferredLanguage;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (nameController.text.trim().length < 2) {
      _message('Enter a valid full name.');
      return;
    }

    if (languageController.text.trim().length < 2) {
      _message('Enter a valid language code.');
      return;
    }

    setState(() => saving = true);

    try {
      final updated = await FishermanService.updateProfile(
        fullName: nameController.text,
        preferredLanguage: languageController.text,
        homeLandingCentre: landingCentreController.text,
        emergencyContactName: emergencyNameController.text,
        emergencyContactPhone: emergencyPhoneController.text,
      );

      if (!mounted) return;

      setState(() => profile = updated);
      _message('Profile updated successfully.');
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  InputDecoration _field(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My ORCA Profile')),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OrcaMascot(size: 96, mood: MascotMood.sleepy),
            const SizedBox(height: 14),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final p = profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.coral,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoftIcon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.22),
                        size: 44,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        p.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fisher ID: ${p.fisherId ?? 'Pending'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.phoneNumber ?? 'No phone number',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const OrcaMascot(
                  size: 92,
                  mood: MascotMood.happy,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            enabled: !saving,
            decoration: _field('Full Name', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: languageController,
            enabled: !saving,
            decoration: _field(
              'Preferred Language Code',
              Icons.language_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: landingCentreController,
            enabled: !saving,
            decoration: _field('Home Landing Centre', Icons.place_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emergencyNameController,
            enabled: !saving,
            decoration: _field(
              'Emergency Contact Name',
              Icons.contact_emergency_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emergencyPhoneController,
            enabled: !saving,
            keyboardType: TextInputType.phone,
            decoration: _field(
              'Emergency Contact Number',
              Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Profile'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VesselListScreen()),
                );
              },
              icon: const Icon(Icons.sailing_rounded),
              label: const Text('Manage My Vessels'),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Home GPS location is already supported by the '
            'database model, but ORCA will populate it during '
            'the map/GPS phase instead of asking you to type '
            'coordinates manually.',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
