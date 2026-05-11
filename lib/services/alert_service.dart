import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import '../models/alert_model.dart';
import '../config/app_config.dart';

class AlertService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<AlertResponse?> triggerAlert(AlertRequest request,
      {bool isRetry = false}) async {
    final url = Uri.parse(AppConfig.triggerAlertEndpoint);

    try {
      dev.log("Triggering alert for user: ${request.userId}");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

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

  Future<bool> respondToAlert({
    required String alertId,
    required String response,
  }) async {
    final url = Uri.parse(AppConfig.respondAlertEndpoint);

    try {
      dev.log("Responding to alert $alertId with: $response");
      final httpResponse = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "alertId": alertId,
              "response": response,
            }),
          )
          .timeout(_timeout);

      return httpResponse.statusCode == 200;
    } catch (e) {
      dev.log("Error responding to alert: $e");
      return false;
    }
  }
}
