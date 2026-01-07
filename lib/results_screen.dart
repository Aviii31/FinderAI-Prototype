import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Launch Maps
import 'services/firestore_service.dart'; // Import Firestore Service

class ResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> results;

  const ResultsScreen({super.key, required this.results});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  
  // Local list to handle immediate removal from UI upon deletion
  late List<Map<String, dynamic>> _currentResults;

  @override
  void initState() {
    super.initState();
    _currentResults = List.from(widget.results); // Create a modifiable copy
    // Initialize the background animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  // Callback to remove item from grid
  void _removeItem(String itemId) {
    setState(() {
      _currentResults.removeWhere((item) => item['id'] == itemId);
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      extendBodyBehindAppBar: true, // Allows content to flow behind AppBar
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 1. Animated Background
          _AnimatedBackground(controller: _bgController),

          // 2. Content
          Center(
            child: ConstrainedBox(
              // Keeping your update: Increased maxWidth to 1500
              constraints: const BoxConstraints(maxWidth: 1500),
              child: _currentResults.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // Keeping your update: 4 items per row
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _currentResults.length,
                      itemBuilder: (context, index) {
                        final item = _currentResults[index];
                        double similarity = item['similarity'] ?? 0.0;
                        if (similarity.isNaN || similarity.isInfinite) similarity = 0.0;
                        final int percentage = (similarity * 100).clamp(0, 100).round();

                        return _GridResultCard(
                          item: item,
                          percentage: percentage,
                          onDelete: () => _removeItem(item['id']),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              "All matches resolved!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text(
        "Potential Matches",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

// ================== THE GRID CARD ==================
class _GridResultCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int percentage;
  final VoidCallback onDelete; // Callback to update UI

  const _GridResultCard({
    required this.item, 
    required this.percentage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final matchColor = percentage > 85
        ? const Color(0xFF10B981)
        : percentage > 75
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _DetailPopup(
            item: item, 
            percentage: percentage, 
            matchColor: matchColor,
            onDelete: onDelete, // Pass callback
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                item['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[100],
                  child: Icon(Icons.broken_image, color: Colors.grey[300]),
                ),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[50],
                    child: const Center(child: CircularProgressIndicator.adaptive()),
                  );
                },
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.7)
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Percentage Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    "$percentage%",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: matchColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Tap to View
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Text(
                  "Tap to view",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================== THE DETAIL POPUP ==================
class _DetailPopup extends StatelessWidget {
  final Map<String, dynamic> item;
  final int percentage;
  final Color matchColor;
  final VoidCallback onDelete;

  const _DetailPopup({
    super.key,
    required this.item,
    required this.percentage,
    required this.matchColor,
    required this.onDelete,
  });

  // --- Deletion Logic ---
  Future<void> _confirmAndRecover(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Recovery"),
        content: const Text(
          "Are you sure this is your item?\n\n"
          "Marking it as recovered will verify the match and remove it from the database permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Green for success
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes, I have it"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Delete from Firestore
        await FirestoreService().deleteFoundItem(item['id']);
        
        // 2. Update parent UI
        onDelete();

        if (context.mounted) {
          Navigator.pop(context); // Close Popup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Item marked as recovered!"),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Parse Date ---
    String? foundDateStr;
    if (item['foundAt'] != null) {
      try {
        final date = DateTime.parse(item['foundAt']);
        // Format: DD/MM/YYYY at HH:MM
        foundDateStr = "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        // Fallback or ignore if parsing fails
      }
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Image & Close Button ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      item['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 200, child: Center(child: Icon(Icons.error))),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: Match % and Finder ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: matchColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: matchColor),
                              const SizedBox(width: 4),
                              Text(
                                "$percentage% Match",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: matchColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Found by",
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 12)),
                            Text(item['userName'] ?? "Anonymous",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- NEW: Found Date Row (if available) ---
                    if (foundDateStr != null) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: const Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            "Found on: $foundDateStr",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 16),
                    ],

                    // --- Description ---
                    const Text("Description",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(
                      item['description'] ?? "No description available",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 20),

                    // --- Contact Info ---
                    const Text("Contact Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    _contactRow(Icons.email, "Email", item['email'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _contactRow(Icons.phone, "Phone", item['phone'] ?? 'N/A'),

                    // --- Google Maps Button ---
                    if (item['location'] != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final lat = item['location']['lat'];
                            final lng = item['location']['lng'];
                            final googleMapsUrl = Uri.parse(
                                "https://www.google.com/maps/search/?api=1&query=$lat,$lng"); 
                            
                            if (await canLaunchUrl(googleMapsUrl)) {
                              await launchUrl(googleMapsUrl);
                            }
                          },
                          icon: const Icon(Icons.map, color: Color(0xFF6366F1)),
                          label: const Text("View Location on Google Maps",
                              style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- NEW: RECOVER / DELETE BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmAndRecover(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green for Success
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: const Text(
                          "I have recovered this item",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        "This will remove the item from the database.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- BACKGROUND ANIMATION CLASSES ----------------

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BackgroundPainter(controller.value),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      const Color(0xFF6366F1).withOpacity(0.12),
      const Color(0xFFF59E0B).withOpacity(0.12),
      const Color(0xFF8B5CF6).withOpacity(0.12),
    ];

    for (int i = 0; i < 10; i++) {
      final dx = (size.width + 200) * ((progress + i * 0.15) % 1) - 100;
      final dy = size.height * ((i * 0.2) % 1);

      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), 70 + (i * 6), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}