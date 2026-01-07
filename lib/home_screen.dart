import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // Default Location (e.g., City Center) - Update this to your preferred default
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), 
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _loadFoundItemMarkers();
  }

  Future<void> _loadFoundItemMarkers() async {
    try {
      final firestore = FirestoreService();
      final items = await firestore.getAllFoundItems();
      final Set<Marker> newMarkers = {};

      for (var item in items) {
        if (item['location'] != null) {
          final lat = item['location']['lat'];
          final lng = item['location']['lng'];
          
          newMarkers.add(
            Marker(
              markerId: MarkerId(item['id']),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: item['description'] ?? "Found Item",
                snippet: "Found by ${item['userName']}",
              ),
              // You can use BitmapDescriptor.fromAssetImage for custom icons later
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
        });
      }
    } catch (e) {
      print("Error loading map markers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            "Finder.AI",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 24),
            child: IconButton(
              icon: const Icon(Icons.account_circle, size: 42, color: Colors.black),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🌊 FLOWING BACKGROUND
          const _AnimatedBackground(),

          // 🧠 MAIN CONTENT
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView( 
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Lost. Found. Reconnected.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Scan or describe items — Finder.AI intelligently reconnects lost belongings with the people who need them most.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black54,
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // --- ACTION CARDS (MOVED UP) ---
                    SizedBox(
                      height: 240, // Height maintained as requested
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              title: "I LOST SOMETHING",
                              subtitle: "Find what you lost, faster",
                              icon: Icons.search,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.pushNamed(context, '/lost'),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _ActionCard(
                              title: "I FOUND SOMETHING",
                              subtitle: "Help return it to its owner",
                              icon: Icons.camera_alt,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => Navigator.pushNamed(context, '/found'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- 🗺️ MAP WIDGET (MOVED DOWN) ---
                    Container(
                      height: 250, // Height maintained as requested
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: _kInitialPosition,
                              markers: _markers,
                              zoomControlsEnabled: false,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              onMapCreated: (controller) => _mapController = controller,
                            ),
                            // Map Label Overlay
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_markers.length} Items Found Nearby",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "Powered by AI · Built for public use",
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= BACKGROUND ================= */

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _FlowingCircle(size: 280, top: 120, color: Color(0xFFD8CCF8), speed: 28),
        _FlowingCircle(size: 220, top: 300, color: Color(0xFFF6D9A8), speed: 34),
        _FlowingCircle(size: 180, top: 520, color: Color(0xFFCDEAFE), speed: 40),
        _FlowingCircle(size: 140, top: 180, color: Color(0xFFF4C2D7), speed: 22),

        _FlowingCircle(size: 200, bottom: 220, color: Color(0xFFE6DFFF), speed: 36),
        _FlowingCircle(size: 160, bottom: 120, color: Color(0xFFFFE0B2), speed: 30),
        _FlowingCircle(size: 120, bottom: 60, color: Color(0xFFD1E7FF), speed: 26),
        _FlowingCircle(size: 90, bottom: 340, color: Color(0xFFF3C1D1), speed: 32),
      ],
    );
  }
}

class _FlowingCircle extends StatefulWidget {
  final double size;
  final double? top;
  final double? bottom;
  final Color color;
  final int speed;

  const _FlowingCircle({
    required this.size,
    this.top,
    this.bottom,
    required this.color,
    required this.speed,
  });

  @override
  State<_FlowingCircle> createState() => _FlowingCircleState();
}

class _FlowingCircleState extends State<_FlowingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speed),
    )..repeat();
  }

  // --- FIX: Added dispose to prevent crash ---
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final x = (screenWidth + widget.size) * _controller.value - widget.size;
          final y = sin(_controller.value * 2 * pi) * 24;

          return Transform.translate(
            offset: Offset(x, y),
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

/* ================= ACTION CARD ================= */

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 220,
                color: Colors.white.withOpacity(0.18),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}