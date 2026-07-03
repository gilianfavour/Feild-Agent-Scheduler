import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule.dart';
import '../utils/app_constants.dart';

/// Manages the full list of schedules and persists them locally.
class ScheduleProvider extends ChangeNotifier {
  final List<Schedule> _schedules = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';

  List<Schedule> get allSchedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // ── Computed lists ─────────────────────────────────────────────────────────

  List<Schedule> get filteredSchedules {
    return _schedules.where((s) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _statusFilter == 'all' || s.status.value == _statusFilter;
      return matchesSearch && matchesFilter;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  int get totalCount => _schedules.length;
  int get completedCount =>
      _schedules.where((s) => s.status == ScheduleStatus.completed).length;
  int get pendingCount =>
      _schedules.where((s) => s.status == ScheduleStatus.pending).length;
  int get checkedInCount =>
      _schedules.where((s) => s.status == ScheduleStatus.checkedIn).length;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> loadSchedules() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Version check: wipe stale data from older builds ──────────────────
      final storedVersion = prefs.getInt(AppConstants.prefDataVersion) ?? 0;
      if (storedVersion < AppConstants.currentDataVersion) {
        await prefs.remove(AppConstants.prefSchedules);
        await prefs.setInt(
          AppConstants.prefDataVersion,
          AppConstants.currentDataVersion,
        );
        _schedules.clear();
        _seedDemoData();
        await _persist();
        _setLoading(false);
        return;
      }

      // ── Normal load ───────────────────────────────────────────────────────
      final jsonList = prefs.getStringList(AppConstants.prefSchedules) ?? [];

      final parsed = <Schedule>[];
      for (final raw in jsonList) {
        try {
          parsed.add(Schedule.fromMap(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {
          // skip corrupt entry
        }
      }

      _schedules
        ..clear()
        ..addAll(parsed);

      // Always seed if nothing survived parsing.
      if (_schedules.isEmpty) {
        _seedDemoData();
        await _persist();
      }
    } catch (_) {
      // Storage completely unavailable — use demo data in memory.
      _schedules.clear();
      _seedDemoData();
    }
    _setLoading(false);
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addSchedule({
    required String customerName,
    required String locationName,
    required double latitude,
    required double longitude,
    required String initialReport,
  }) async {
    final schedule = Schedule(
      id: const Uuid().v4(),
      customerName: customerName,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      initialReport: initialReport,
      createdAt: DateTime.now(),
    );
    _schedules.add(schedule);
    await _persist();
    notifyListeners();
  }

  Future<void> checkIn(String id) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _schedules[index] = _schedules[index].copyWith(
      status: ScheduleStatus.checkedIn,
      checkInTime: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> checkOut({
    required String id,
    required String visitReport,
  }) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _schedules[index] = _schedules[index].copyWith(
      status: ScheduleStatus.completed,
      visitReport: visitReport,
      checkOutTime: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Schedule? getById(String id) {
    try {
      return _schedules.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _schedules.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(AppConstants.prefSchedules, jsonList);
  }

  // ── Demo reset ─────────────────────────────────────────────────────────────

  /// Wipes all stored schedules and re-seeds the demo data.
  Future<void> resetToDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSchedules);
    await prefs.setInt(
      AppConstants.prefDataVersion,
      AppConstants.currentDataVersion,
    );
    _schedules.clear();
    _seedDemoData();
    await _persist();
    notifyListeners();
  }

  void _seedDemoData() {
    final now = DateTime.now();
    _schedules.addAll([
      Schedule(
        id: const Uuid().v4(),
        customerName: 'Acme Corporation',
        locationName: 'Acme HQ - Downtown',
        latitude: 37.7749,
        longitude: -122.4194,
        initialReport: 'Routine maintenance visit. Check all HVAC units.',
        status: ScheduleStatus.completed,
        createdAt: now.subtract(const Duration(days: 5)),
        checkInTime: now.subtract(const Duration(days: 5, hours: -9)),
        checkOutTime: now.subtract(const Duration(days: 5, hours: -11)),
        visitReport: 'All HVAC units inspected. No issues found.',
      ),
      Schedule(
        id: const Uuid().v4(),
        customerName: 'TechStart Inc.',
        locationName: 'TechStart Office - Midtown',
        latitude: 40.7580,
        longitude: -73.9855,
        initialReport:
            'New client onboarding visit. Install monitoring equipment.',
        status: ScheduleStatus.checkedIn,
        createdAt: now.subtract(const Duration(days: 1)),
        checkInTime: now.subtract(const Duration(hours: 2)),
      ),
      Schedule(
        id: const Uuid().v4(),
        customerName: 'Global Finance Ltd.',
        locationName: 'Finance Tower - Floor 12',
        latitude: 51.5074,
        longitude: -0.1278,
        initialReport:
            'Quarterly security audit. Review access control systems.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Schedule(
        id: const Uuid().v4(),
        customerName: 'Sunrise Retail',
        locationName: 'Sunrise Mall - West Wing',
        latitude: 34.0522,
        longitude: -118.2437,
        initialReport: 'POS system upgrade and staff training session.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Schedule(
        id: const Uuid().v4(),
        customerName: 'Metro Logistics',
        locationName: 'Metro Warehouse Zone B',
        latitude: 41.8781,
        longitude: -87.6298,
        initialReport:
            'Inventory system integration and barcode scanner setup.',
        createdAt: now,
      ),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
