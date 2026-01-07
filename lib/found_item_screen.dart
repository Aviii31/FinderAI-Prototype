import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // Tag location

import 'services/storage_service.dart';
import 'services/firestore_service.dart';
import 'services/ai_service.dart';

class FoundItemScreen extends StatefulWidget {
  const FoundItemScreen({super.key});

  @override
  State<FoundItemScreen> createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController descController = TextEditingController();
  final TextEditingController dateController = TextEditingController(); // NEW: Date Controller

  Uint8List? imageBytes;
  bool uploading = false;
  DateTime? selectedDate; // NEW: Store the specific date
  final user = FirebaseAuth.instance.currentUser;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 30)
    )..repeat();
    
    // Default to "Now"
    selectedDate = DateTime.now();
    dateController.text = _formatDateTime(selectedDate!);
  }

  // --- Helper to Format Date nicely without external packages ---
  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // --- Date & Time Picker Logic ---
  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (!mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            date.year, date.month, date.day, time.hour, time.minute
          );
          dateController.text = _formatDateTime(selectedDate!);
        });
      }
    }
  }

  Future<void> pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => imageBytes = bytes);
  }

  /// 📍 Get Current Location
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> submitFoundItem() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => uploading = true);

    try {
      Position? position = await _determinePosition();
      final storage = StorageService();
      final imageUrl = await storage.uploadFoundItemImage(imageBytes);

      String desc = descController.text.trim();
      final ai = AIService();
      if (desc.isEmpty) {
        desc = await ai.getImageDescription(imageUrl);
      }

      final embedding = await ai.getEmbedding(desc);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final name = userDoc.data()?['name'] ?? 'Anonymous';
      final phone = userDoc.data()?['phone'] ?? '';
      final email = user?.email ?? '';

      final firestore = FirestoreService();
      
      // CHANGE: You will need to update your FirestoreService.addFoundItem
      // to accept 'dateFound'. If you can't change that file easily, 
      // you can just pass it as part of the map manually here if needed, 
      // but assuming you update the service:
      await firestore.addFoundItem(
        imageUrl: imageUrl,
        description: desc,
        embedding: embedding,
        userId: user!.uid,
        userName: name,
        email: email,
        phone: phone,
        latitude: position?.latitude,
        longitude: position?.longitude,
        // PASS THE DATE HERE (Make sure to update FirestoreService to accept this!)
        // If your service doesn't have this arg yet, you can add it to the map inside the service.
        foundAt: selectedDate, 
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Success!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Item uploaded successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color.fromARGB(137, 255, 255, 255)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    descController.dispose();
    dateController.dispose();
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
          "Report Found Item",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
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
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView( // Added scroll view for smaller screens
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Scan a Found Item",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload an image and tell us when/where you found it.",
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                  
                      // Image Picker
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          height: isDesktop ? 350 : 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: imageBytes == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined, size: 72, color: Color(0xFFF59E0B)),
                                    SizedBox(height: 16),
                                    Text(
                                      "Tap to upload or scan image",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                                ),
                        ),
                      ),
                  
                      const SizedBox(height: 24),
                  
                      // --- NEW: Date & Time Picker ---
                      TextField(
                        controller: dateController,
                        readOnly: true, // User cannot type manually, must pick
                        onTap: _pickDateTime,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Date & Time Found",
                          labelStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                  
                      // Description Input
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "Optional description (brand, color, etc...)",
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                  
                      const SizedBox(height: 32),
                  
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: uploading ? null : submitFoundItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                          ),
                          child: uploading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    ),
                                    SizedBox(width: 12),
                                    Text("Processing AI & Location...", style: TextStyle(color: Colors.white))
                                  ],
                                )
                              : const Text(
                                  "Upload Found Item",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
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
      final dx = (size.width + 200) * ((progress + i * 0.15) % 1) - 100;
      final dy = size.height * ((i * 0.2) % 1);
      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), 70 + (i * 6), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}