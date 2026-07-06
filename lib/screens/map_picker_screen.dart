/// map_picker_screen.dart
///
/// Why OpenStreetMap?
/// ------------------
/// OpenStreetMap (OSM) is a free, open-source global map used via the
/// flutter_map package. Unlike Google Maps it requires no API key, no billing
/// account, and has no per-request cost. Tiles are served from OSM's public
/// tile server (tile.openstreetmap.org) under the ODbL license.
///
/// How location selection works:
/// ------------------------------
/// 1. On open, the camera is moved to the device's GPS position (geolocator).
/// 2. The user taps anywhere on the map — flutter_map fires `onTap(LatLng)`.
/// 3. A marker is placed at the tapped position.
/// 4. Reverse geocoding (geocoding package → Nominatim) resolves the
///    coordinates to a human-readable address string.
/// 5. Pressing "Confirm Location" pops the screen returning a [MapPickerResult].
///
/// How reverse geocoding works:
/// ------------------------------
/// `geocoding.placemarkFromCoordinates(lat, lng)` calls the Nominatim REST API
/// over HTTPS. The response is a list of [Placemark] objects containing
/// sub-locality, street, city, country etc. We format these into one address
/// string. No API key is needed — Nominatim is a free OSM geocoding service.

library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_constants.dart';

/// Result returned from [MapPickerScreen] when the user confirms a location.
class MapPickerResult {
  final double latitude;
  final double longitude;

  /// Human-readable address from reverse geocoding (Nominatim / OSM).
  final String address;

  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Full-screen OpenStreetMap picker.
/// Push via [Navigator.push<MapPickerResult>] and await the result.
class MapPickerScreen extends StatefulWidget {
  /// Pre-selected coordinates — map centres here and a marker is pre-placed.
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // ── Map controller ─────────────────────────────────────────────────────────
  final MapController _mapController = MapController();

  // ── State ──────────────────────────────────────────────────────────────────
  LatLng? _markerPosition;
  bool _isLocating = false; // moving to current GPS position
  bool _isGeocoding = false; // resolving address from coordinates
  String _resolvedAddress = ''; // result from reverse geocoding

  // Default centre: Nairobi, Kenya — overridden by device GPS on init.
  static const LatLng _defaultCenter = LatLng(-1.2921, 36.8219);
  static const double _defaultZoom = 12.0;
  static const double _pickedZoom = 16.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      // Pre-select if coordinates were passed in (e.g. editing an existing schedule).
      _markerPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_markerPosition!);
    } else {
      // Move map to device's current location on first open.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _moveToCurrentLocation(),
      );
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  /// Requests location permission and animates the map to the device's position.
  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      _mapController.move(LatLng(pos.latitude, pos.longitude), _pickedZoom);
    } catch (_) {
      // Silently fall back to default centre — GPS unavailable.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Map tap ────────────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng position) {
    setState(() {
      _markerPosition = position;
      _resolvedAddress = ''; // clear stale address while geocoding
    });
    _reverseGeocode(position);
  }

  // ── Reverse geocoding ──────────────────────────────────────────────────────

  /// Resolves [position] to a human-readable address using the geocoding
  /// package, which calls the Nominatim OSM geocoding API — free, no key.
  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build address from most-specific to least-specific components.
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        setState(() {
          _resolvedAddress = parts.join(', ');
        });
      } else {
        setState(() {
          _resolvedAddress =
              '${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (_) {
      // Nominatim unavailable (offline) — use raw coordinates.
      if (mounted) {
        setState(() {
          _resolvedAddress =
              '${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  void _confirm() {
    if (_markerPosition == null) return;
    Navigator.pop(
      context,
      MapPickerResult(
        latitude: _markerPosition!.latitude,
        longitude: _markerPosition!.longitude,
        address: _resolvedAddress.isNotEmpty
            ? _resolvedAddress
            : '${_markerPosition!.latitude.toStringAsFixed(6)}, '
                  '${_markerPosition!.longitude.toStringAsFixed(6)}',
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMarker = _markerPosition != null;
    final initialCenter = _markerPosition ?? _defaultCenter;
    final initialZoom = hasMarker ? _pickedZoom : _defaultZoom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _GlassButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Select Location',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _GlassButton(
              onTap: _isLocating ? null : _moveToCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // ── OpenStreetMap via flutter_map ───────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OSM tile layer — no API key required.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.feild_agent_scheduler',
                maxZoom: 19,
              ),

              // Marker layer
              if (hasMarker)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markerPosition!,
                      width: 40,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const _MapPin(),
                    ),
                  ],
                ),
            ],
          ),

          // ── "Tap to place marker" hint ─────────────────────────────────────
          if (!hasMarker)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to place a marker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── OSM attribution (required by tile license) ─────────────────────
          Positioned(
            bottom: 220,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black87),
              ),
            ),
          ),

          // ── Bottom sheet: address + coordinates + confirm ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  if (hasMarker) ...[
                    // Address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppConstants.primaryAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isGeocoding
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppConstants.slate600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resolving address…',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppConstants.slate600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _resolvedAddress.isNotEmpty
                                      ? _resolvedAddress
                                      : 'Address unavailable',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Coordinate tiles
                    Row(
                      children: [
                        Expanded(
                          child: _CoordTile(
                            label: 'LATITUDE',
                            value: _formatCoord(
                              _markerPosition!.latitude,
                              isLat: true,
                            ),
                            icon: Icons.north_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CoordTile(
                            label: 'LONGITUDE',
                            value: _formatCoord(
                              _markerPosition!.longitude,
                              isLat: false,
                            ),
                            icon: Icons.east_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 18,
                            color: AppConstants.slate600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No location selected',
                            style: TextStyle(
                              color: AppConstants.slate600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Confirm button
                  FilledButton.icon(
                    onPressed: (hasMarker && !_isGeocoding) ? _confirm : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppConstants.primaryAccent,
                      disabledBackgroundColor: AppConstants.slate200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoord(double value, {required bool isLat}) {
    final dir = isLat ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    return '${value.abs().toStringAsFixed(6)}° $dir';
  }
}

// ── Custom map pin ─────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppConstants.primaryAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryAccent.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        // Pin tail
        Container(width: 2, height: 10, color: AppConstants.primaryAccent),
      ],
    );
  }
}

// ── Glass action button ────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Coordinate display tile ────────────────────────────────────────────────────

class _CoordTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CoordTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppConstants.primaryAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppConstants.primaryAccent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryAccent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
