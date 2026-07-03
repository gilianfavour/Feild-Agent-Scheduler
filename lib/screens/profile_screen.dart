import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_constants.dart';

/// User profile and app settings – tab 3.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile avatar card ─────────────────────────────────────────
            _buildAvatarCard(theme, authProvider.userEmail),
            const SizedBox(height: 16),

            // ── Stats summary ───────────────────────────────────────────────
            _buildStatsSummary(theme, scheduleProvider),
            const SizedBox(height: 24),

            // ── Settings section ────────────────────────────────────────────
            _SectionLabel(label: 'Settings'),
            const SizedBox(height: 8),
            _buildSettingsCard(context, theme, themeProvider),
            const SizedBox(height: 24),

            // ── About section ───────────────────────────────────────────────
            _SectionLabel(label: 'About'),
            const SizedBox(height: 8),
            _buildAboutCard(theme),
            const SizedBox(height: 16),

            // ── Developer ───────────────────────────────────────────────────
            _SectionLabel(label: 'Developer'),
            const SizedBox(height: 8),
            _buildDeveloperCard(context, theme),
            const SizedBox(height: 24),

            // ── Logout ──────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppConstants.errorColor,
                side: const BorderSide(color: AppConstants.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar card ────────────────────────────────────────────────────────────

  Widget _buildAvatarCard(ThemeData theme, String email) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    'DA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              'Demo Agent',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),

            // Role chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Field Agent',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  email.isEmpty ? AppConstants.demoEmail : email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats summary ──────────────────────────────────────────────────────────

  Widget _buildStatsSummary(ThemeData theme, ScheduleProvider provider) {
    return Row(
      children: [
        _StatBadge(
          label: 'Total',
          value: provider.totalCount.toString(),
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 10),
        _StatBadge(
          label: 'Done',
          value: provider.completedCount.toString(),
          color: AppConstants.successColor,
        ),
        const SizedBox(width: 10),
        _StatBadge(
          label: 'Pending',
          value: provider.pendingCount.toString(),
          color: const Color(0xFF6A1B9A),
        ),
        const SizedBox(width: 10),
        _StatBadge(
          label: 'Active',
          value: provider.checkedInCount.toString(),
          color: AppConstants.warningColor,
        ),
      ],
    );
  }

  // ── Settings card ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard(
    BuildContext context,
    ThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          // Dark mode toggle
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              themeProvider.isDark ? 'Currently dark' : 'Currently light',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Switch.adaptive(
              value: themeProvider.isDark,
              activeColor: theme.colorScheme.primary,
              onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),

          // Notifications (demo)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppConstants.warningColor,
                size: 20,
              ),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Push notifications enabled',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Switch.adaptive(
              value: true,
              activeColor: theme.colorScheme.primary,
              onChanged: (_) {}, // demo only
            ),
          ),
        ],
      ),
    );
  }

  // ── About card ─────────────────────────────────────────────────────────────

  Widget _buildAboutCard(ThemeData theme) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _AboutRow(
            icon: Icons.info_outline_rounded,
            iconColor: theme.colorScheme.primary,
            title: 'App Version',
            trailing: AppConstants.appVersion,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          _AboutRow(
            icon: Icons.map_rounded,
            iconColor: const Color(0xFF00695C),
            title: AppConstants.appName,
            trailing: 'v${AppConstants.appVersion}',
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          _AboutRow(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Privacy Policy',
            trailing: 'Demo',
            showArrow: true,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          _AboutRow(
            icon: Icons.description_outlined,
            iconColor: AppConstants.warningColor,
            title: 'Terms of Service',
            trailing: 'Demo',
            showArrow: true,
          ),
        ],
      ),
    );
  }
  // ── Developer card ─────────────────────────────────────────────────────────

  Widget _buildDeveloperCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.restore_rounded,
            color: AppConstants.errorColor,
            size: 20,
          ),
        ),
        title: const Text(
          'Reset Demo Data',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Restore 5 sample schedules',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
        onTap: () => _confirmReset(context),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will delete all existing schedules and restore the 5 original demo schedules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ScheduleProvider>().resetToDemo();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Demo data restored'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

// ── Local helper widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final bool showArrow;

  const _AboutRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailing,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
