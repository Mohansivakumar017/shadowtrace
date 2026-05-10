import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shadowtrace_app/models/alert_model.dart';
import 'dart:developer' as dev;

class AlertService {
  static const String _baseUrl = "https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev";
  static const Duration _timeout = Duration(seconds: 15);

  /// Triggers a new emergency alert with one automatic retry on failure.
  Future<AlertResponse?> triggerAlert(AlertRequest request, {bool isRetry = false}) async {
    final url = Uri.parse("$_baseUrl/trigger-alert");

    try {
      dev.log("Triggering alert for user: ${request.userId}");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AlertResponse.fromJson(data);
      } else {
        throw HttpException("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      dev.log("Error triggering alert: $e");
      if (!isRetry) {
        dev.log("Retrying triggerAlert once...");
        return triggerAlert(request, isRetry: true);
      }
      rethrow;
    }
  }

  /// Sends a guardian response to an active alert.
  Future<bool> respondToAlert({required String alertId, required String response}) async {
    final url = Uri.parse("$_baseUrl/respond-alert");

    try {
      dev.log("Responding to alert $alertId with: $response");
      final httpResponse = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "alertId": alertId,
          "response": response,
        }),
      ).timeout(_timeout);

      return httpResponse.statusCode == 200;
    } catch (e) {
      dev.log("Error responding to alert: $e");
      return false;
    }
  }
}
