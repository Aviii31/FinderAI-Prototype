import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for User ID
import 'package:cloud_firestore/cloud_firestore.dart'; // Required to save Alert

// Ensure these imports match your project structure
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'services/firestore_service.dart';
import 'results_screen.dart';

class LostItemScreen extends StatefulWidget {
  const LostItemScreen({super.key});

  @override
  State<LostItemScreen> createState() => _LostItemScreenState();
}

class _LostItemScreenState extends State<LostItemScreen> with SingleTickerProviderStateMixin {
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  File? imageFile;
  Uint8List? webImage;
  bool searching = false;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 30)
    )..repeat();
  }

  Future<void> pickImage() async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    if (kIsWeb) {
      webImage = await picked.readAsBytes();
    } else {
      imageFile = File(picked.path);
    }

    setState(() {});
  }

  // --- NEW: Save "Notify Me" Alert ---
  Future<void> saveLostAlert(List<double> embedding, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseFirestore.instance.collection('lost_alerts').add({
        'userId': user.uid,
        'email': user.email,
        'description': description,
        'embedding': embedding, // Vector used for future matching
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alert set! We'll email you if matches are found."),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      print("Error saving alert: $e");
    }
  }

  Future<void> submit() async {
    final String textQuery = descriptionController.text.trim();
    final bool hasImage = imageFile != null || webImage != null;

    if (!hasImage && textQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add an image or a description")),
      );
      return;
    }

    setState(() => searching = true);
    String? tempImageUrl;

    try {
      List<double> targetEmbedding;
      final ai = AIService();

      // LOGIC: Use Image Embedding if available, otherwise use Text
      if (hasImage) {
        // 1. Upload Image
        final storage = StorageService();
        dynamic image = kIsWeb ? webImage : imageFile;
        tempImageUrl = await storage.uploadTempImage(image);

        // 2. Get Embedding directly from Image
        targetEmbedding = await ai.getImageEmbedding(tempImageUrl);
      } else {
        // 3. Get Embedding from Text
        targetEmbedding = await ai.getEmbedding(textQuery);
      }

      // 4. Search Firestore
      final firestore = FirestoreService();
      final allFound = await firestore.getAllFoundItems();

      List<Map<String, dynamic>> matches = [];
      for (var item in allFound) {
        if (item['embedding'] != null) {
          final itemEmbedding = (item['embedding'] as List).cast<double>();
          final sim = cosineSimilarity(targetEmbedding, itemEmbedding);
          
          if (sim > 0.65) { // Similarity Threshold
            matches.add(item..['similarity'] = sim);
          }
        }
      }

      // 5. Sort by similarity (highest first)
      matches.sort((a, b) => b['similarity'].compareTo(a['similarity']));

      if (mounted) {
        // --- NEW: Check if matches are empty ---
        if (matches.isEmpty) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("No matches yet"),
              content: const Text(
                "We couldn't find a similar item right now.\n\n"
                "Would you like us to email you if someone uploads it later?"
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), // Just close
                  child: const Text("No thanks", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save Alert Logic
                    saveLostAlert(targetEmbedding, textQuery.isEmpty ? "Image Search" : textQuery);
                    Navigator.pop(ctx); // Close Dialog
                    
                    // Navigate to empty results screen (optional, but good UX)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ResultsScreen(results: matches)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: const Text("Notify Me", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          // Matches Found -> Navigate normally
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultsScreen(results: matches),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => searching = false);
      if (tempImageUrl != null) {
        // Cleanup optional
      }
    }
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  @override
  void dispose() {
    _bgController.dispose(); 
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Lost Item",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController), 
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Find Your Lost Item",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Upload an image or describe the item to search for matches.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: isDesktop ? 320 : 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withOpacity(0.85),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                            width: 2,
                          ),
                        ),
                        child: (imageFile == null && webImage == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 70,
                                    color: Color(0xFF6366F1),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    "Tap to upload image (optional)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: kIsWeb
                                    ? Image.memory(
                                        webImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText:
                            "Describe the item (color, brand, where you lost it...)",
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: searching ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: searching
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Find Matches",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
      final dx =
          (size.width + 200) * ((progress + i * 0.15) % 1) - 100;
      final dy = size.height * ((i * 0.2) % 1);

      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), 70 + (i * 6), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}