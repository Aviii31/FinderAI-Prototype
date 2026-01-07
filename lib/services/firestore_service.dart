import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> addFoundItem({
    required String imageUrl,
    required String description,
    required List<double> embedding,
    required String userId,
    required String userName,
    required String email,
    required String phone,
    // Existing location coordinates
    required double? latitude,
    required double? longitude,
    // NEW: Accept the Date & Time Found
    DateTime? foundAt, 
  }) async {
    await _db.collection('found_items').add({
      'imageUrl': imageUrl,
      'description': description,
      'embedding': embedding,
      'userId': userId,
      'userName': userName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(), // When it was uploaded
      
      // NEW: Save the actual "Time Found" selected by user
      'foundAt': foundAt?.toIso8601String(),

      // Existing location map
      'location': (latitude != null && longitude != null)
          ? {'lat': latitude, 'lng': longitude}
          : null,
    });
  }

  Future<List<Map<String, dynamic>>> getAllFoundItems() async {
    final snap = await _db.collection('found_items').get();
    return snap.docs.map((d) => {
      'id': d.id, // ID is crucial for deletion
      ...d.data(),
    }).toList();
  }

  // --- NEW: DELETE FUNCTION ---
  Future<void> deleteFoundItem(String itemId) async {
    await _db.collection('found_items').doc(itemId).delete();
  }
}