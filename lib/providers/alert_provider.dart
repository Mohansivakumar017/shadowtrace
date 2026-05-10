import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowtrace_app/models/alert_model.dart';
import 'package:shadowtrace_app/services/alert_service.dart';
import 'package:shadowtrace_app/services/sound_service.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();
  final SoundService _soundService = SoundService();
  bool _isLoading = false;
  String? _activeAlertId;

  bool get isLoading => _isLoading;
  String? get activeAlertId => _activeAlertId;

  Future<void> sendSOS({
    required String userId,
    required String guardianPhone,
    required double lat,
    required double lng,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    // 1. Internet Check
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      onError("No Internet Connection. Please check your network.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 2. Immediate Haptic & Sound Feedback
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [500, 200, 500, 200], intensities: [255, 255]);
      }

      // TRIGGER EXISTING SOUND
      _soundService.playEmergencySiren();

      // 3. API Call
      final request = AlertRequest(
        userId: userId,
        guardianPhone: guardianPhone,
        latitude: lat,
        longitude: lng,
        alertType: "SOS",
      );

      final response = await _alertService.triggerAlert(request);

      if (response != null) {
        _activeAlertId = response.alertId;
        onSuccess();
      } else {
        onError("Unable to dispatch alert. Please try again.");
      }
    } catch (e) {
      onError("Critical System Error: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendResponse(String responseType) async {
    if (_activeAlertId == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _alertService.respondToAlert(
      alertId: _activeAlertId!,
      response: responseType,
    );

    if (responseType == "SAFE_NOW") {
      _soundService.stopSiren();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
