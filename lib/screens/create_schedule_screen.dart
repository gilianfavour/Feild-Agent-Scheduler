import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_text_field.dart';

/// Form screen for creating a new field schedule.
class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _reportCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await context.read<ScheduleProvider>().addSchedule(
      customerName: _customerCtrl.text.trim(),
      locationName: _locationCtrl.text.trim(),
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
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

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _validateLat(String? v) {
    if (v == null || v.trim().isEmpty) return 'Latitude is required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Enter a valid number';
    if (d < -90 || d > 90) return 'Latitude must be between -90 and 90';
    return null;
  }

  String? _validateLng(String? v) {
    if (v == null || v.trim().isEmpty) return 'Longitude is required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Enter a valid number';
    if (d < -180 || d > 180) return 'Longitude must be between -180 and 180';
    return null;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _SectionHeader(title: 'Customer Information'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _customerCtrl,
                label: 'Customer Name',
                hint: 'e.g. Acme Corporation',
                prefixIcon: Icons.business_rounded,
                textCapitalization: TextCapitalization.words,
                validator: _requiredText,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _locationCtrl,
                label: 'Location Name',
                hint: 'e.g. Acme HQ - Downtown',
                prefixIcon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.words,
                validator: _requiredText,
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'GPS Coordinates'),
              const SizedBox(height: 12),

              // Lat / Lng row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latCtrl,
                      label: 'Latitude',
                      hint: '37.7749',
                      prefixIcon: Icons.my_location_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      validator: _validateLat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngCtrl,
                      label: 'Longitude',
                      hint: '-122.4194',
                      prefixIcon: Icons.my_location_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      validator: _validateLng,
                    ),
                  ),
                ],
              ),

              // Hint text
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Tip: Use Google Maps to get accurate coordinates.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

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
