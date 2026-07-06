import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../services/location_service.dart';
import '../utils/app_constants.dart';
import 'map_picker_screen.dart';

/// Shows full details of a single schedule and allows check-in / check-out.
class ScheduleDetailsScreen extends StatefulWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  State<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends State<ScheduleDetailsScreen> {
  bool _isCheckingIn = false;
  String? _proximityMessage;

  // ── Check In ───────────────────────────────────────────────────────────────

  Future<void> _checkIn(Schedule schedule) async {
    setState(() {
      _isCheckingIn = true;
      _proximityMessage = null;
    });

    final result = await LocationService.instance.checkProximity(
      targetLat: schedule.latitude,
      targetLng: schedule.longitude,
      radiusMeters: AppConstants.checkInRadiusMeters,
    );

    if (!mounted) return;

    if (result.error != null) {
      setState(() {
        _isCheckingIn = false;
        _proximityMessage = 'Location error: ${result.error}';
      });
      _showSnackbar(
        'Unable to get your location. Please enable GPS.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isCheckingIn = false;
    });

    if (result.isWithinRadius) {
      await context.read<ScheduleProvider>().checkIn(schedule.id);
      if (mounted) {
        _showSnackbar('Check-in successful! ✅', isError: false);
        setState(() => _proximityMessage = null);
      }
    } else {
      final km = result.distanceMeters >= 1000
          ? '${(result.distanceMeters / 1000).toStringAsFixed(2)} km'
          : '${result.distanceMeters.toStringAsFixed(0)} m';
      setState(() {
        _proximityMessage =
            'You are not at the scheduled location yet.\nDistance from target: $km';
      });
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppConstants.errorColor
            : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheduleId = ModalRoute.of(context)?.settings.arguments as String?;
    final schedule = scheduleId != null
        ? context.watch<ScheduleProvider>().getById(scheduleId)
        : null;

    if (schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Details')),
        body: const Center(child: Text('Schedule not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status hero card
            _buildStatusCard(context, schedule),
            const SizedBox(height: 16),

            // Customer info
            _buildInfoCard(
              context,
              title: 'Customer Information',
              icon: Icons.business_rounded,
              children: [
                _InfoRow(label: 'Customer', value: schedule.customerName),
                _InfoRow(label: 'Location', value: schedule.locationName),
                if (schedule.address.isNotEmpty)
                  _InfoRow(label: 'Address', value: schedule.address),
              ],
            ),
            const SizedBox(height: 12),

            // Coordinates
            _buildInfoCard(
              context,
              title: 'GPS Coordinates',
              icon: Icons.map_rounded,
              children: [
                _InfoRow(
                  label: 'Latitude',
                  value: schedule.latitude.toStringAsFixed(6),
                ),
                _InfoRow(
                  label: 'Longitude',
                  value: schedule.longitude.toStringAsFixed(6),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Map preview
            _MapPreviewCard(
              latitude: schedule.latitude,
              longitude: schedule.longitude,
              label: schedule.locationName,
            ),
            const SizedBox(height: 12),

            // Initial report
            _buildInfoCard(
              context,
              title: 'Initial Field Report',
              icon: Icons.description_outlined,
              children: [
                _InfoRow(label: 'Report', value: schedule.initialReport),
              ],
            ),
            const SizedBox(height: 12),

            // Visit report (if checked out)
            if (schedule.visitReport.isNotEmpty) ...[
              _buildInfoCard(
                context,
                title: 'Visit Report',
                icon: Icons.assignment_turned_in_outlined,
                children: [
                  _InfoRow(label: 'Report', value: schedule.visitReport),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Timestamps
            _buildInfoCard(
              context,
              title: 'Timeline',
              icon: Icons.access_time_rounded,
              children: [
                _InfoRow(
                  label: 'Created',
                  value: _formatDate(schedule.createdAt),
                ),
                if (schedule.checkInTime != null)
                  _InfoRow(
                    label: 'Checked In',
                    value: _formatDate(schedule.checkInTime!),
                  ),
                if (schedule.checkOutTime != null)
                  _InfoRow(
                    label: 'Checked Out',
                    value: _formatDate(schedule.checkOutTime!),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Proximity warning
            if (_proximityMessage != null) _buildProximityWarning(context),

            // Action buttons
            _buildActionButtons(context, schedule),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Schedule schedule) {
    final theme = Theme.of(context);
    final statusColor = AppConstants.statusColor(schedule.status.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor.withOpacity(0.85), statusColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppConstants.statusIcon(schedule.status.value),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.customerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.statusLabel(schedule.status.value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProximityWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.warningColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppConstants.warningColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _proximityMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppConstants.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Schedule schedule) {
    final canCheckIn = schedule.status == ScheduleStatus.pending;
    final canCheckOut = schedule.status == ScheduleStatus.checkedIn;

    if (!canCheckIn && !canCheckOut) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.successColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: AppConstants.successColor),
            const SizedBox(width: 8),
            Text(
              'This schedule has been completed.',
              style: TextStyle(
                color: AppConstants.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCheckIn)
          FilledButton.icon(
            onPressed: _isCheckingIn ? null : () => _checkIn(schedule),
            icon: _isCheckingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              _isCheckingIn ? 'Verifying Location…' : 'Check In',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppConstants.warningColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (canCheckOut)
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/checkout',
              arguments: schedule.id,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Check Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppConstants.successColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
}

// ── Map preview card (OpenStreetMap via flutter_map) ──────────────────────────
//
// Why flutter_map?
// flutter_map renders OpenStreetMap tiles — free, open-source, no API key,
// no billing. The preview is non-interactive (gestures disabled) to avoid
// accidental panning inside a scroll view. "Open Full Map" pushes the full
// interactive MapPickerScreen.

class _MapPreviewCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String label;

  const _MapPreviewCard({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = LatLng(latitude, longitude);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'LOCATION MAP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLat: latitude,
                        initialLng: longitude,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_full_rounded, size: 14),
                  label: const Text(
                    'Open Full Map',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // ── OSM map thumbnail ─────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                // Disable all gestures — this is a static preview inside
                // a scrollable screen.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.feild_agent_scheduler',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 36,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 8,
                            color: AppConstants.primaryAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Coordinate footer ─────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.pin_drop_outlined,
                  size: 14,
                  color: AppConstants.slate600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${latitude.toStringAsFixed(6)},  '
                  '${longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.slate600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _InfoRow ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
