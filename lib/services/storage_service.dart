// Modified: lib/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadFoundItemImage(dynamic image) async {
    final ref = _storage
        .ref()
        .child('found_items/${DateTime.now().millisecondsSinceEpoch}.jpg');

    if (kIsWeb) {
      await ref.putData(image as Uint8List, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(image as File);
    }
    return await ref.getDownloadURL();
  }

  Future<String> uploadTempImage(dynamic image) async {
    final ref = _storage
        .ref()
        .child('temp/${DateTime.now().millisecondsSinceEpoch}.jpg');

    if (kIsWeb) {
      await ref.putData(image as Uint8List, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(image as File);
    }
    return await ref.getDownloadURL();
  }
}