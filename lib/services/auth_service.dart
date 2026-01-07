import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// REGISTER USER + CREATE PROFILE
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// LOGIN USER
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT USER
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// UPDATE USER DETAILS (your existing logic, preserved)
  Future<void> saveUserDetails({
    required String name,
    required String email,
    required String phone,
  }) async {
    final uid = currentUser!.uid;

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
    }, SetOptions(merge: true));
  }
}