class AlertRequest {
  final String userId;
  final String guardianPhone;
  final double latitude;
  final double longitude;
  final String alertType;

  AlertRequest({
    required this.userId,
    required this.guardianPhone,
    required this.latitude,
    required this.longitude,
    required this.alertType,
  });

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "guardianPhone": guardianPhone,
        "latitude": latitude,
        "longitude": longitude,
        "alertType": alertType,
      };
}

class AlertResponse {
  final String alertId;
  final String status;

  AlertResponse({required this.alertId, required this.status});

  factory AlertResponse.fromJson(Map<String, dynamic> json) {
    return AlertResponse(
      alertId: json['alertId'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
