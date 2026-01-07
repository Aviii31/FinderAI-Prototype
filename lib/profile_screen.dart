import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isSaving = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      nameController.text = doc['name'] ?? '';
      phoneController.text = doc['phone'] ?? '';
    }
  }

  Future<void> saveProfile() async {
    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      user?.email ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 36),

                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFF6366F1),
                            child: const Icon(
                              Icons.person,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 28),

                          _inputField("Full Name", nameController),
                          const SizedBox(height: 16),
                          _inputField("Phone Number", phoneController),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "SAVE CHANGES",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              "LOG OUT",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 INPUT FIELD (TEXT COLOR FIXED)
  Widget _inputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black), // ✅ typed text
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/* ---------------- BACKGROUND ANIMATION ---------------- */

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

    for (int i = 0; i < 12; i++) {
      final dx =
          (size.width + 200) * ((progress + i * 0.12) % 1) - 100;
      final dy = size.height * ((i * 0.18) % 1);

      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), 80 + (i * 4), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
