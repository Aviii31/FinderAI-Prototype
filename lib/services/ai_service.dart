// Modified: lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Update these URLs to match your deployed Firebase function URLs
  static const String _baseUrl = 'https://us-central1-finderai-prototype.cloudfunctions.net';
  
  static const String embeddingUrl = '$_baseUrl/getTextEmbedding';
  static const String descriptionUrl = '$_baseUrl/getImageDescription';
  static const String imageEmbeddingUrl = '$_baseUrl/getImageEmbedding'; // New URL

  Future<List<double>> getEmbedding(String text) async {
    final response = await http.post(
      Uri.parse(embeddingUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': text}),
    );

    if (response.statusCode == 200) {
      return List<double>.from(json.decode(response.body)['embedding']);
    } else {
      throw Exception('Failed to get text embedding: ${response.body}');
    }
  }

  Future<String> getImageDescription(String imageUrl) async {
    final response = await http.post(
      Uri.parse(descriptionUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'imageUrl': imageUrl}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['description'];
    } else {
      throw Exception('Failed to get image description: ${response.body}');
    }
  }

  // New Method
  Future<List<double>> getImageEmbedding(String imageUrl) async {
    final response = await http.post(
      Uri.parse(imageEmbeddingUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'imageUrl': imageUrl}),
    );

    if (response.statusCode == 200) {
      return List<double>.from(json.decode(response.body)['embedding']);
    } else {
      throw Exception('Failed to get image embedding: ${response.body}');
    }
  }
}