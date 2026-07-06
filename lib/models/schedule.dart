import 'dart:convert';

/// Represents the lifecycle status of a field schedule.
enum ScheduleStatus { pending, checkedIn, completed }

extension ScheduleStatusX on ScheduleStatus {
  String get value {
    switch (this) {
      case ScheduleStatus.checkedIn:
        return 'checkedIn';
      case ScheduleStatus.completed:
        return 'completed';
      default:
        return 'pending';
    }
  }

  static ScheduleStatus fromString(String s) {
    switch (s) {
      case 'checkedIn':
        return ScheduleStatus.checkedIn;
      case 'completed':
        return ScheduleStatus.completed;
      default:
        return ScheduleStatus.pending;
    }
  }
}

/// Core data model for a field agent schedule.
///
/// [address] is reverse-geocoded from [latitude]/[longitude] via the
/// OpenStreetMap Nominatim service (through the `geocoding` package).
/// It is optional — older stored records that pre-date the address field
/// will have an empty string and display gracefully.
class Schedule {
  final String id;
  final String customerName;
  final String locationName;

  /// Human-readable address obtained from reverse geocoding.
  /// Empty string when unavailable or not yet resolved.
  final String address;

  final double latitude;
  final double longitude;
  final String initialReport;
  final String visitReport;
  final ScheduleStatus status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const Schedule({
    required this.id,
    required this.customerName,
    required this.locationName,
    this.address = '',
    required this.latitude,
    required this.longitude,
    required this.initialReport,
    this.visitReport = '',
    this.status = ScheduleStatus.pending,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  /// Returns a copy with the specified fields overridden.
  Schedule copyWith({
    String? id,
    String? customerName,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? initialReport,
    String? visitReport,
    ScheduleStatus? status,
    DateTime? createdAt,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return Schedule(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      initialReport: initialReport ?? this.initialReport,
      visitReport: visitReport ?? this.visitReport,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'locationName': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'initialReport': initialReport,
      'visitReport': visitReport,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      locationName: map['locationName'] as String,
      // Graceful fallback for records stored before the address field existed.
      address: (map['address'] as String?) ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      initialReport: map['initialReport'] as String,
      visitReport: (map['visitReport'] as String?) ?? '',
      status: ScheduleStatusX.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'] as String)
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Schedule.fromJson(String source) =>
      Schedule.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Display-friendly location: prefer resolved address, fall back to locationName.
  String get displayAddress => address.isNotEmpty ? address : locationName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Schedule && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Schedule(id: $id, customer: $customerName)';
}
