import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_text_field.dart';
import 'map_picker_screen.dart';

/// Form screen for creating a new field schedule.
/// Latitude/longitude are populated via the interactive map picker.
class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();

  // Coordinates set by the map picker — never typed manually.
  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _locationPicked = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _locationCtrl.dispose();
    _reportCtrl.dispose();
    super.dispose();
  }

  // ── Map picker ─────────────────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLat: _latitude, initialLng: _longitude),
      ),
    );

    if (result == null) return;

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _address = result.address;
      _locationPicked = true;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    // Validate text fields first.
    if (!_formKey.currentState!.validate()) return;

    // Validate that a location was picked.
    if (!_locationPicked || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select a location on the map.'),
            ],
          ),
          backgroundColor: AppConstants.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    await context.read<ScheduleProvider>().addSchedule(
      customerName: _customerCtrl.text.trim(),
      locationName: _locationCtrl.text.trim(),
      address: _address,
      latitude: _latitude!,
      longitude: _longitude!,
      initialReport: _reportCtrl.text.trim(),
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Schedule created successfully!'),
          ],
        ),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Schedule',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Customer Information ──────────────────────────────────────
              _SectionHeader(title: 'Customer Information'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _customerCtrl,
                label: 'Customer Name',
                hint: 'e.g. Acme Corporation',
                prefixIcon: Icons.business_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Customer name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _locationCtrl,
                label: 'Location Name',
                hint: 'e.g. Acme HQ - Downtown',
                prefixIcon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Location name is required';
                  }
                  return null;
                },
              ),

              // ── Location on Map ───────────────────────────────────────────
              const SizedBox(height: 24),
              _SectionHeader(title: 'Location on Map'),
              const SizedBox(height: 12),

              // Location picker card
              _LocationPickerCard(
                latitude: _latitude,
                longitude: _longitude,
                address: _address,
                picked: _locationPicked,
                onPickTap: _openMapPicker,
              ),

              // ── Field Report ──────────────────────────────────────────────
              const SizedBox(height: 24),
              _SectionHeader(title: 'Field Report'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _reportCtrl,
                label: 'Initial Field Report',
                hint: 'Describe the purpose and scope of this visit…',
                prefixIcon: Icons.description_outlined,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Initial report is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Report must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save button
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving…' : 'Create Schedule',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Location picker card ───────────────────────────────────────────────────────

class _LocationPickerCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String address;
  final bool picked;
  final VoidCallback onPickTap;

  const _LocationPickerCard({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.picked,
    required this.onPickTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Select button
        OutlinedButton.icon(
          onPressed: onPickTap,
          icon: Icon(
            picked
                ? Icons.edit_location_alt_rounded
                : Icons.add_location_alt_rounded,
            size: 20,
          ),
          label: Text(
            picked ? 'Change Location on Map' : 'Select Location on Map',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppConstants.primaryAccent,
            side: BorderSide(
              color: picked
                  ? AppConstants.primaryAccent
                  : AppConstants.primaryAccent.withValues(alpha: 0.4),
              width: picked ? 1.5 : 1,
            ),
            backgroundColor: picked
                ? AppConstants.primaryAccent.withValues(alpha: 0.04)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Coordinate display (shown after pick)
        if (picked && latitude != null && longitude != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppConstants.successColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppConstants.successColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location selected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.successColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (address.isNotEmpty) ...[
                        Text(
                          address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppConstants.deepNavy,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'Lat: ${latitude!.toStringAsFixed(6)}  '
                        'Lng: ${longitude!.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConstants.slate600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Re-open map icon
                IconButton(
                  onPressed: onPickTap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  color: AppConstants.primaryAccent,
                  tooltip: 'Open map',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ] else if (!picked) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Tap the button above to pin the visit location on a map.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.slate600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
