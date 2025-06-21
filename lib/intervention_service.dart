import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

const storage = FlutterSecureStorage();

class InterventionService {
  static Future<Map<String, dynamic>> createIntervention({
    required int professionalId,
    required String description,
    required DateTime scheduledAt,
    String status = 'attente',
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http
          .post(
            Uri.parse(
              'http://192.168.1.5:8000/api/Store/Intervention/$professionalId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'description': description,
              'scheduled_at': scheduledAt.toIso8601String(),
              'status': status,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur création intervention: $e');
      rethrow;
    }
  }
}
