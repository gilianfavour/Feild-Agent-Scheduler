import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/schedule_card.dart';

/// Displays all schedules with search and status filter – tab 1.
class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  final List<Map<String, String>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Pending', 'value': AppConstants.statusPending},
    {'label': 'Checked In', 'value': AppConstants.statusCheckedIn},
    {'label': 'Completed', 'value': AppConstants.statusCompleted},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = context.read<ScheduleProvider>().searchQuery;
      _searchCtrl.text = q;
      if (q.isNotEmpty) setState(() => _showSearch = true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        context.read<ScheduleProvider>().setSearch('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ScheduleProvider>();
    final schedules = provider.filteredSchedules;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Schedules',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            tooltip: 'Search',
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
            ),
            tooltip: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Schedule',
            onPressed: () => Navigator.pushNamed(context, '/create-schedule'),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Column(
        children: [
          // Search + filter bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            color: theme.colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              16,
              _showSearch ? 8 : 0,
              16,
              _showSearch ? 0 : 0,
            ),
            height: _showSearch ? null : 0,
            child: _showSearch
                ? Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: provider.setSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by customer name…',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    provider.setSearch('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Filter chips – always visible
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final selected = provider.statusFilter == f['value'];
                  return FilterChip(
                    label: Text(f['label']!),
                    selected: selected,
                    onSelected: (_) => provider.setStatusFilter(f['value']!),
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? theme.colorScheme.primary : null,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${schedules.length} schedule${schedules.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedules.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<ScheduleProvider>().loadSchedules(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return ScheduleCard(
                          schedule: schedule,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/schedule-details',
                            arguments: schedule.id,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Schedules Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter,\nor create a new schedule.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-schedule'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
