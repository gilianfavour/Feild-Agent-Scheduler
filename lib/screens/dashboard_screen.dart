import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_constants.dart';

/// Main dashboard – tab 0 of the bottom nav shell.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleProvider = context.watch<ScheduleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          // Notification icon
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No new notifications'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          // Theme toggle
          IconButton(
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
            ),
            tooltip: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-schedule'),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('New Schedule'),
        elevation: 3,
        backgroundColor: AppConstants.primaryAccent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ScheduleProvider>().loadSchedules(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Status bar (replaces greeting banner)
              _buildStatusBar(theme, scheduleProvider),
              const SizedBox(height: 20),

              // Unified stats card
              _buildUnifiedStatsCard(theme, scheduleProvider),
              const SizedBox(height: 28),

              // Quick actions
              _SectionLabel(label: 'Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(context, theme),
              const SizedBox(height: 28),

              // Recent activity
              _SectionLabel(label: 'Recent Activity'),
              const SizedBox(height: 8),
              _buildRecentActivity(context, theme, scheduleProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status bar ─────────────────────────────────────────────────────────────

  Widget _buildStatusBar(ThemeData theme, ScheduleProvider provider) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final date = DateFormat('MMM d').format(now);
    final pending = provider.pendingCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppConstants.slate600,
          ),
          const SizedBox(width: 10),
          Text(
            '$dayOfWeek, $date',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text('•', style: TextStyle(color: AppConstants.slate600)),
          const SizedBox(width: 8),
          Text(
            '${provider.totalCount} schedule${provider.totalCount == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.slate600,
            ),
          ),
          const Spacer(),
          if (pending > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pending pending',
                style: const TextStyle(
                  color: AppConstants.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Unified stats card ─────────────────────────────────────────────────────

  Widget _buildUnifiedStatsCard(ThemeData theme, ScheduleProvider provider) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Row(
          children: [
            _StatColumn(
              label: 'Total',
              value: provider.totalCount,
              color: theme.colorScheme.onSurface,
            ),
            _Divider(theme),
            _StatColumn(
              label: 'Completed',
              value: provider.completedCount,
              color: theme.colorScheme.onSurface,
            ),
            _Divider(theme),
            _StatColumn(
              label: 'Pending',
              value: provider.pendingCount,
              color: AppConstants.warningColor,
              showDot: true,
            ),
            _Divider(theme),
            _StatColumn(
              label: 'Active',
              value: provider.checkedInCount,
              color: AppConstants.primaryAccent,
              showDot: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Create\nSchedule',
            onTap: () => Navigator.pushNamed(context, '/create-schedule'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.list_alt_rounded,
            label: 'All\nSchedules',
            onTap: () {
              context.read<ScheduleProvider>().clearFilters();
              Navigator.pushNamed(context, '/schedules');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.description_outlined,
            label: 'View\nReports',
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
        ),
      ],
    );
  }

  // ── Recent activity ────────────────────────────────────────────────────────

  Widget _buildRecentActivity(
    BuildContext context,
    ThemeData theme,
    ScheduleProvider provider,
  ) {
    final recent = provider.allSchedules.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final display = recent.take(5).toList();

    if (display.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 40,
                color: AppConstants.slate600.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No schedules yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppConstants.slate600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: display.map((s) {
        return _ActivityTile(
          schedule: s,
          onTap: () => Navigator.pushNamed(
            context,
            '/schedule-details',
            arguments: s.id,
          ),
        );
      }).toList(),
    );
  }
}

// ── Local widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppConstants.slate600,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;
  const _Divider(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool showDot;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          // Number with optional indicator dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              if (showDot) ...[
                const SizedBox(width: 3),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppConstants.slate600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppConstants.primaryAccent),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const _ActivityTile({required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppConstants.statusColor(schedule.status.value);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.customerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.displayAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppConstants.slate600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status label
            Text(
              AppConstants.statusLabel(schedule.status.value),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppConstants.slate600.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
