import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/fisherman_models.dart';
import '../../services/fisherman_service.dart';
import '../../widgets/orca_mascot.dart';
import '../../widgets/talkie_ui.dart';

class VesselFormScreen extends StatefulWidget {
  final VesselData? vessel;

  const VesselFormScreen({super.key, this.vessel});

  @override
  State<VesselFormScreen> createState() => _VesselFormScreenState();
}

class _VesselFormScreenState extends State<VesselFormScreen> {
  final pageController = PageController();

  final nameController = TextEditingController();
  final registrationController = TextEditingController();
  final lengthController = TextEditingController();
  final beamController = TextEditingController();
  final speedController = TextEditingController();
  final personsController = TextEditingController();

  final boatTypes = const [
    'Small Motor Boat',
    'Trawler',
    'Gillnetter',
    'Traditional Boat',
    'Other',
  ];

  int step = 0;
  String? selectedType;
  bool knowsSpeed = false;
  bool saving = false;

  bool get editing => widget.vessel != null;

  @override
  void initState() {
    super.initState();

    final vessel = widget.vessel;

    if (vessel != null) {
      nameController.text = vessel.name;
      registrationController.text = vessel.registrationNumber ?? '';
      selectedType = vessel.vesselType;
      lengthController.text = vessel.lengthM?.toString() ?? '';
      beamController.text = vessel.beamM?.toString() ?? '';
      speedController.text = vessel.cruisingSpeedKnots?.toString() ?? '';
      personsController.text = vessel.personsOnboardDefault.toString();
      knowsSpeed = vessel.cruisingSpeedKnots != null;
    } else {
      personsController.text = '1';
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    nameController.dispose();
    registrationController.dispose();
    lengthController.dispose();
    beamController.dispose();
    speedController.dispose();
    personsController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _validateCurrentStep() {
    if (step == 0) {
      if (nameController.text.trim().isEmpty) {
        _message('Enter a boat name or a simple name you use for the boat.');
        return false;
      }
    }

    if (step == 1) {
      final persons = int.tryParse(personsController.text.trim());
      if (persons == null || persons < 1) {
        _message('Usual people onboard must be at least 1.');
        return false;
      }

      if (knowsSpeed && speedController.text.trim().isNotEmpty) {
        final speed = double.tryParse(speedController.text.trim());
        if (speed == null || speed <= 0) {
          _message('Enter a valid cruising speed.');
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;

    if (step < 2) {
      setState(() => step += 1);
      await pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _save();
  }

  Future<void> _back() async {
    if (step == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => step -= 1);

    await pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  double? _optionalDouble(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  Future<void> _save() async {
    final persons = int.parse(personsController.text.trim());

    setState(() => saving = true);

    try {
      if (editing) {
        await FishermanService.updateVessel(
          vesselId: widget.vessel!.id,
          name: nameController.text,
          registrationNumber: registrationController.text,
          vesselType: selectedType,
          lengthM: _optionalDouble(lengthController),
          beamM: _optionalDouble(beamController),
          cruisingSpeedKnots: knowsSpeed
              ? _optionalDouble(speedController)
              : null,
          personsOnboardDefault: persons,
        );
      } else {
        await FishermanService.createVessel(
          name: nameController.text,
          registrationNumber: registrationController.text,
          vesselType: selectedType,
          lengthM: _optionalDouble(lengthController),
          beamM: _optionalDouble(beamController),
          cruisingSpeedKnots: knowsSpeed
              ? _optionalDouble(speedController)
              : null,
          personsOnboardDefault: persons,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _field(
    String label,
    IconData icon, {
    String? hint,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Boat' : 'Set Up Your Boat'),
        leading: IconButton(
          onPressed: saving ? null : _back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              _progressHeader(),
              Expanded(
                child: PageView(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepIdentity(),
                    _stepTripBasics(),
                    _stepOptionalDetails(),
                  ],
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          PillProgress(value: (step + 1) / 3),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${step + 1} of 3',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Only add what you know',
                style: TextStyle(
                  color: AppTheme.coralDeep,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SoftIcon(
                icon,
                color: AppTheme.coralDeep,
                background: AppTheme.coralSoft,
                size: 56,
              ),
              const Spacer(),
              OrcaMascot(
                size: 72,
                mood: const [
                  MascotMood.happy,
                  MascotMood.calm,
                  MascotMood.sparkle,
                ][step.clamp(0, 2)],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _stepIdentity() {
    return _pageShell(
      icon: Icons.directions_boat_filled_rounded,
      title: 'Which boat do you use?',
      subtitle:
          'Keep this simple. A familiar boat name is enough. '
          'Registration number can be added later.',
      children: [
        TextField(
          controller: nameController,
          enabled: !saving,
          textCapitalization: TextCapitalization.words,
          decoration: _field(
            'Boat name *',
            Icons.sailing_rounded,
            hint: 'Example: Sea Queen',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: registrationController,
          enabled: !saving,
          decoration: _field(
            'Registration number (optional)',
            Icons.confirmation_number_outlined,
            hint: 'Skip if you do not know it',
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Boat type',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: boatTypes.map((type) {
            final selected = selectedType == type;

            return ChoiceChip(
              selected: selected,
              label: Text(type),
              avatar: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.directions_boat_outlined,
                size: 18,
              ),
              onSelected: saving
                  ? null
                  : (_) {
                      setState(() => selectedType = type);
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: saving ? null : () => setState(() => selectedType = null),
          child: const Text('I am not sure about the boat type'),
        ),
      ],
    );
  }

  Widget _stepTripBasics() {
    return _pageShell(
      icon: Icons.people_alt_rounded,
      title: 'Your usual trip',
      subtitle:
          'These basics help ORCA prepare future mission and '
          'emergency context without asking the same questions repeatedly.',
      children: [
        TextField(
          controller: personsController,
          enabled: !saving,
          keyboardType: TextInputType.number,
          decoration: _field(
            'Usual people onboard *',
            Icons.groups_outlined,
            hint: 'Example: 3',
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Do you know the usual cruising speed?',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _speedChoice(
                label: 'Yes, I know',
                selected: knowsSpeed,
                onTap: () => setState(() => knowsSpeed = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _speedChoice(
                label: "I don't know",
                selected: !knowsSpeed,
                onTap: () {
                  setState(() {
                    knowsSpeed = false;
                    speedController.clear();
                  });
                },
              ),
            ),
          ],
        ),
        if (knowsSpeed) ...[
          const SizedBox(height: 14),
          TextField(
            controller: speedController,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _field(
              'Approx. cruising speed',
              Icons.speed_rounded,
              suffix: 'kn',
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.limeSoft,
            borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftIcon(
                Icons.info_outline_rounded,
                color: AppTheme.ink,
                background: AppTheme.lime,
                size: 34,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If you do not know the speed, leave it unknown. '
                  'ORCA will ask for it only when a feature really needs an accurate ETA.',
                  style: TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _speedChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: saving ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.coral : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepOptionalDetails() {
    return _pageShell(
      icon: Icons.tune_rounded,
      title: 'Optional technical details',
      subtitle: 'You can skip these. They can be added later from My Vessels.',
      children: [
        TextField(
          controller: lengthController,
          enabled: !saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _field(
            'Approx. boat length',
            Icons.straighten_rounded,
            suffix: 'm',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: beamController,
          enabled: !saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _field(
            'Approx. boat width / beam',
            Icons.swap_horiz_rounded,
            suffix: 'm',
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lavenderSoft,
            borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftIcon(
                Icons.photo_camera_outlined,
                color: AppTheme.indigo,
                background: Colors.white,
                size: 34,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next improvement: scan the boat registration certificate '
                  'and let ORCA pre-fill known details for confirmation.',
                  style: TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : _back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Back'),
              ),
            ),
          if (step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: saving ? null : _next,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: saving
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      step == 2
                          ? (editing ? 'Save Boat' : 'Finish Setup')
                          : 'Continue',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
