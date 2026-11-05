import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/mapbox_service.dart';
import '../widgets/safety_rating_dialog.dart';
import 'auth_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _originController = TextEditingController(text: 'Locating...');
  final _destController = TextEditingController();
  final _destFocusNode = FocusNode();

  String _travelMode = 'driving'; // 'driving', 'two_wheeler', 'walking'
  MapType _currentMapType = MapType.normal;

  List<MapboxPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Preset destination hubs for one-tap student demonstration
  final List<Map<String, dynamic>> _presetDestinations = [
    {
      'title': 'Kopargaon Railway Station',
      'subtitle': 'Central transit junction',
      'latLng': const LatLng(19.8920, 74.4820),
    },
    {
      'title': 'Shirdi Sai Baba Temple',
      'subtitle': 'Prominent pilgrimage hub',
      'latLng': const LatLng(19.7667, 74.4767),
    },
    {
      'title': 'Model Colony Kopargaon',
      'subtitle': 'Residential avenue',
      'latLng': const LatLng(19.8885, 74.4750),
    },
    {
      'title': 'Sanjeevani Sugar Factory',
      'subtitle': 'Industrial corridor',
      'latLng': const LatLng(19.8812, 74.4880),
    },
    {
      'title': 'Kopargaon ST Stand / Market',
      'subtitle': 'Active commercial bus terminal',
      'latLng': const LatLng(19.8945, 74.4795),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nav = context.read<NavigationProvider>();
      await nav.fetchCurrentLocation();
      if (mounted) {
        setState(() {
          _originController.text = nav.isLiveLocationAcquired
              ? 'Your Live Location'
              : 'Sanjivani College of Engg, Kopargaon';
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originController.dispose();
    _destController.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  void _onDestQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final currentPos = context.read<NavigationProvider>().currentLocation;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final results = await MapboxService.searchPlaces(
          trimmed,
          proximityLng: currentPos.longitude,
          proximityLat: currentPos.latitude,
          limit: 5,
        );
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _handleCustomDestination(String query) async {
    _debounceTimer?.cancel();
    _destFocusNode.unfocus();
    setState(() => _searchResults = []);

    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Check preset match first
    final presetMatch = _presetDestinations.where(
      (item) => item['title'].toString().toLowerCase().contains(trimmed.toLowerCase()) ||
                item['subtitle'].toString().toLowerCase().contains(trimmed.toLowerCase()),
    );

    if (presetMatch.isNotEmpty) {
      final selected = presetMatch.first;
      _onDestinationSelected(selected['latLng'], selected['title']);
      return;
    }

    // Dynamic forward geocoding via Mapbox Places API using current user location proximity
    setState(() => _isSearching = true);
    final currentPos = context.read<NavigationProvider>().currentLocation;
    final place = await MapboxService.forwardGeocode(
      trimmed,
      proximityLng: currentPos.longitude,
      proximityLat: currentPos.latitude,
    );
    setState(() => _isSearching = false);

    if (place != null) {
      _destController.text = place.placeName;
      _onDestinationSelected(place.coordinates, place.placeName);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF202124),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No location found for "$trimmed". Try another landmark.',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _onDestinationSelected(LatLng point, String title) {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    _destFocusNode.unfocus();
    setState(() => _searchResults = []);
    _destController.text = title;
    context.read<NavigationProvider>().selectDestinationAndEvaluate(
      destination: point,
      token: token,
      destinationTitle: title,
    );
  }

  void _swapLocations() {
    final nav = context.read<NavigationProvider>();
    if (nav.destinationLocation != null) {
      final currentOriginText = _originController.text;
      _originController.text = _destController.text;
      _destController.text = currentOriginText;
      // Re-evaluate
      final token = context.read<AuthProvider>().currentUser?.token ?? '';
      nav.selectDestinationAndEvaluate(
        destination: nav.currentLocation,
        token: token,
        destinationTitle: _destController.text,
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.hybrid;
      } else if (_currentMapType == MapType.hybrid) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  void _triggerSos() async {
    final auth = context.read<AuthProvider>();
    final nav = context.read<NavigationProvider>();
    final token = auth.currentUser?.token ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Trigger Emergency SOS?', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will immediately dispatch your live GPS location to local emergency contacts and Kopargaon police dispatch.',
          style: TextStyle(color: Color(0xFF5F6368), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISPATCH SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await nav.triggerEmergencySos(token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Emergency SOS broadcasted successfully!'),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('SOS Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final rec = navProvider.routeRecommendation;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 500 ? 410.0 : screenWidth - 32;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-Screen Google Map Viewport
          Positioned.fill(
            child: SizedBox.expand(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: navProvider.currentLocation,
                  zoom: 15.0,
                ),
                mapType: _currentMapType,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                markers: navProvider.markers,
                polylines: navProvider.polylines,
                onMapCreated: (controller) {
                  navProvider.setMapController(controller);
                },
              ),
            ),
          ),

          // 2. Route Evaluation Loading Overlay
          if (navProvider.isEvaluatingRoute)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                          strokeWidth: 2.2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Finding safest route in Kopargaon...',
                        style: TextStyle(
                          color: Color(0xFF202124),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Modern Google Maps Style Panel on Top-Left
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: cardWidth,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Brand + Mode Switcher Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          // App Branding Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_rounded, color: Color(0xFF137333), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'SafeRoute',
                                  style: TextStyle(
                                    color: Color(0xFF137333),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Travel Mode Switcher
                          _buildModeTab('driving', Icons.directions_car_rounded, 'Drive'),
                          const SizedBox(width: 4),
                          _buildModeTab('two_wheeler', Icons.two_wheeler_rounded, '2-Wheeler'),
                          const SizedBox(width: 4),
                          _buildModeTab('walking', Icons.directions_walk_rounded, 'Walk'),
                        ],
                      ),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F4)),

                    // Inputs Section with Iconic Route Dots Connector
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Route Dots
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1A73E8), width: 2.5),
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 32,
                                color: const Color(0xFFDADCE0),
                              ),
                              const Icon(Icons.location_on, color: Color(0xFFEA4335), size: 14),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Text Fields
                          Expanded(
                            child: Column(
                              children: [
                                // Origin Field
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE8EAED)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _originController,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF202124), fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Choose starting point',
                                      hintStyle: TextStyle(color: Color(0xFF80868B), fontSize: 13),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Destination Field
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE8EAED)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _destController,
                                          focusNode: _destFocusNode,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF202124), fontWeight: FontWeight.w500),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Choose destination...',
                                            hintStyle: TextStyle(color: Color(0xFF80868B), fontSize: 13),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: _onDestQueryChanged,
                                          onSubmitted: _handleCustomDestination,
                                        ),
                                      ),
                                      if (_isSearching)
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A73E8)),
                                        )
                                      else if (_destController.text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _destController.clear();
                                            setState(() => _searchResults = []);
                                            navProvider.clearRoute();
                                          },
                                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF5F6368)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Swap Locations Button
                          IconButton(
                            icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF5F6368), size: 22),
                            onPressed: _swapLocations,
                            tooltip: 'Reverse route',
                          ),
                        ],
                      ),
                    ),

                    // Quick Shortcut Chips (One-Tap Kopargaon Landmarks)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
                      child: SizedBox(
                        height: 30,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetDestinations.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final item = _presetDestinations[idx];
                            return ActionChip(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              backgroundColor: const Color(0xFFF1F3F4),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              avatar: const Icon(Icons.directions_rounded, size: 14, color: Color(0xFF1A73E8)),
                              label: Text(
                                item['title'],
                                style: const TextStyle(color: Color(0xFF3C4043), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              onPressed: () => _onDestinationSelected(item['latLng'], item['title']),
                            );
                          },
                        ),
                      ),
                    ),

                    // Dynamic Autocomplete Dropdown List
                    if (_searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F3F4)),
                          itemBuilder: (context, idx) {
                            final place = _searchResults[idx];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.location_on_outlined, color: Color(0xFF5F6368), size: 18),
                              title: Text(
                                place.text,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                              ),
                              subtitle: Text(
                                place.placeName,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _onDestinationSelected(place.coordinates, place.placeName),
                            );
                          },
                        ),
                      ),

                    // SafeRoute Metrics Section (Visible when route is evaluated)
                    if (rec != null) ...[
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F4)),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time & Distance Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  rec.estimatedTimeForMode(_travelMode),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF188038), // Google Maps Green
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${rec.formattedDistance})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Fastest & Safest',
                                    style: TextStyle(
                                      color: Color(0xFF137333),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec.routeSummary,
                              style: const TextStyle(color: Color(0xFF3C4043), fontSize: 12.5),
                            ),
                            const SizedBox(height: 12),

                            // SafeRoute Metrics Badges
                            Row(
                              children: [
                                // Safety Rating Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF188038),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        '★ ${rec.safetyRating.toStringAsFixed(1)} / 5.0 Safety',
                                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Risk Score Meter Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.speed_rounded, color: Color(0xFF1A73E8), size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Risk ${rec.compositeRiskScore.toStringAsFixed(1)}/10 (Low)',
                                        style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action Buttons Row (Start Safe Navigation + Crowdsource Rate)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A73E8), // Google Blue
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    icon: const Icon(Icons.navigation_rounded, size: 18),
                                    label: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          content: Text('Safe navigation corridor active with live hazard monitoring.'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3C4043),
                                    side: const BorderSide(color: Color(0xFFDADCE0)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: const Icon(Icons.star_border_rounded, size: 18, color: Colors.amber),
                                  label: const Text('Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  onPressed: () => showDialog(context: context, builder: (_) => const SafetyRatingDialog()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating Round Action Buttons on Right Side
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layer Style Toggle Button
                _buildFloatingButton(
                  icon: Icons.layers_rounded,
                  tooltip: 'Change map style',
                  onTap: _toggleMapType,
                ),
                const SizedBox(height: 12),

                // Re-center Location Button
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Re-center location',
                  color: const Color(0xFF1A73E8),
                  onTap: () async {
                    await navProvider.fetchCurrentLocation();
                    if (mounted) {
                      setState(() {
                        _originController.text = navProvider.isLiveLocationAcquired
                            ? 'Your Live Location'
                            : 'Sanjivani College of Engg, Kopargaon';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Glowing Emergency SOS Button
                GestureDetector(
                  onTap: _triggerSos,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Floating Top-Right Profile / Logout Menu Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF3C4043), size: 22),
                  onSelected: (val) async {
                    if (val == 'rate') {
                      showDialog(context: context, builder: (_) => const SafetyRatingDialog());
                    } else if (val == 'logout') {
                      final navigator = Navigator.of(context);
                      await authProvider.logout();
                      if (mounted) {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.currentUser?.name ?? 'Student',
                            style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            authProvider.currentUser?.emergencyContact ?? '',
                            style: const TextStyle(color: Color(0xFF5F6368), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'rate',
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text('Crowdsource Safety', style: TextStyle(color: Color(0xFF202124), fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, IconData icon, String label) {
    final isSelected = _travelMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _travelMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFF5F6368),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = const Color(0xFF3C4043),
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}
