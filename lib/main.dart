import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'found_item_screen.dart';
import 'lost_item_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FinderAIApp());
}

class FinderAIApp extends StatelessWidget {
  const FinderAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finder AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22D3EE),
          brightness: Brightness.dark,
        ),
      ),

      /// 🔥 AUTH GATE
      home: const AuthGate(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/found': (_) => const FoundItemScreen(),
        '/lost': (_) => const LostItemScreen(),
      },
    );
  }
}

/// ✅ CLEAN AUTH GATE (NO UI INSIDE)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged In
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Logged Out
        return const LoginScreen();
      },
    );
  }
}
