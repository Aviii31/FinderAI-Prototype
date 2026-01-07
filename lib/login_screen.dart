import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final AuthService auth = AuthService();

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();
  }

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      setState(() => isLoading = true);

      if (isLogin) {
        await auth.login(email: email, password: password);
      } else {
        if (nameController.text.trim().isEmpty ||
            phoneController.text.trim().isEmpty) {
          throw "Name and Phone are required";
        }

        await auth.register(
          name: nameController.text.trim(),
          email: email,
          phone: phoneController.text.trim(),
          password: password,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
                      "Finder.AI",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isLogin ? "Welcome back" : "Create your account",
                      style: const TextStyle(
                        fontSize: 18,
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
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!isLogin) ...[
                            _inputField("Full Name", nameController),
                            const SizedBox(height: 14),
                            _inputField("Phone Number", phoneController),
                            const SizedBox(height: 14),
                          ],

                          _inputField("Email", emailController),
                          const SizedBox(height: 14),

                          _inputField(
                            "Password",
                            passwordController,
                            obscure: true,
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      isLogin ? "LOGIN" : "REGISTER",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          TextButton(
                            onPressed: () =>
                                setState(() => isLogin = !isLogin),
                            child: Text(
                              isLogin
                                  ? "New here? Create account"
                                  : "Already have an account?",
                              style: const TextStyle(color: Colors.black87),
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
  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black), // ✅ typed text
      cursorColor: Colors.black,
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
