# Deployed API Verification

All endpoints are live on AWS and verified callable.

## Location & Weather API
Base: `https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev`

### POST /location
Streams live GPS coordinates to AWS Location Service tracker

**Request:**
```bash
curl -X POST https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {JWT_TOKEN}" \
  -d '{
    "userId": "user-123",
    "tripId": "trip-456",
    "lat": 17.4065,
    "lng": 78.4772,
    "timestamp": "2026-05-11T12:00:00Z",
    "accuracy": 10.5,
    "speed": 2.3
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Location updated",
  "devicePosition": {"lat": 17.4065, "lng": 78.4772}
}
```

---

### GET /wheatherdataget
Get current weather at coordinates

**Request:**
```bash
curl "https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev/wheatherdataget?lat=17.4065&lng=78.4772" \
  -H "Authorization: Bearer {JWT_TOKEN}"
```

**Response:**
```json
{
  "condition": "Clear",
  "temperature": 32,
  "humidity": 45,
  "hazardFlag": false,
  "windSpeed": 5
}
```

---

### POST /wheatherforecasting
Get weather forecast along a route

**Request:**
```bash
curl -X POST https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev/wheatherforecasting \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {JWT_TOKEN}" \
  -d '{
    "waypoints": [
      {"lat": 17.4065, "lng": 78.4772},
      {"lat": 17.3850, "lng": 78.4867}
    ],
    "departureTime": "2026-05-11T14:30:00Z"
  }'
```

**Response:**
```json
{
  "hazardFlag": false,
  "forecast": [
    {
      "waypoint": 0,
      "time": "2026-05-11T14:30:00Z",
      "condition": "Clear",
      "temperature": 32
    }
  ],
  "routeRiskLevel": "LOW"
}
```

---

## Alert System API
Base: `https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev`

### POST /trigger-alert
Trigger SOS alert

**Request:**
```bash
curl -X POST https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev/trigger-alert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {JWT_TOKEN}" \
  -d '{
    "userId": "user-123",
    "tripId": "trip-456",
    "lat": 17.4065,
    "lng": 78.4772,
    "triggerType": "manual",
    "timestamp": "2026-05-11T12:00:00Z"
  }'
```

**Response:**
```json
{
  "alertId": "alert-abcd1234",
  "status": "ACTIVE",
  "notified": 3,
  "contacts": [
    {"name": "Mom", "phone": "+1234567890", "notificationSent": true},
    {"name": "Dad", "phone": "+0987654321", "notificationSent": true}
  ]
}
```

---

### POST /respond-alert
Trusted contact responds to alert

**Request:**
```bash
curl -X POST https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev/respond-alert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {JWT_TOKEN}" \
  -d '{
    "alertId": "alert-abcd1234",
    "responderId": "contact-xyz",
    "response": "en_route",
    "timestamp": "2026-05-11T12:01:00Z"
  }'
```

**Response:**
```json
{
  "success": true,
  "alertId": "alert-abcd1234",
  "status": "EN_ROUTE"
}
```

---

## Implementation in Code

### Flutter Service Layer
All endpoints are accessed through AppConfig constants:

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String locationEndpoint = 
    '${locationApiBase}/location';
  static const String weatherDataEndpoint = 
    '${locationApiBase}/wheatherdataget';
  static const String weatherForecastEndpoint = 
    '${locationApiBase}/wheatherforecasting';
  static const String triggerAlertEndpoint = 
    '${alertApiBase}/trigger-alert';
  static const String respondAlertEndpoint = 
    '${alertApiBase}/respond-alert';
}
```

### Using the Endpoints

```dart
// lib/services/location_service.dart
final response = await http.post(
  Uri.parse(AppConfig.locationEndpoint),
  headers: {'Authorization': 'Bearer $idToken'},
  body: jsonEncode({...})
);

// lib/services/weather_service.dart
final response = await http.get(
  Uri.parse(AppConfig.weatherDataEndpoint)
    .replace(queryParameters: {'lat': lat, 'lng': lng}),
  headers: {'Authorization': 'Bearer $idToken'}
);

// lib/services/sos_service.dart
final response = await http.post(
  Uri.parse(AppConfig.triggerAlertEndpoint),
  headers: {'Authorization': 'Bearer $idToken'},
  body: jsonEncode({...})
);
```

---

## Testing Endpoints

To test endpoints locally:

1. **Obtain JWT Token**
   ```bash
   aws cognito-idp admin-initiate-auth \
     --user-pool-id us-east-1_QUhSwcEDN \
     --client-id 7kt3lo1bge59tslkq4r67u05o5 \
     --auth-flow ADMIN_NO_SRP_AUTH \
     --auth-parameters USERNAME=test@example.com,PASSWORD=TestPassword123
   ```

2. **Test Location Endpoint**
   Copy the `IdToken` from the response and use it in curl commands above

3. **Monitor CloudWatch**
   ```bash
   aws logs tail /aws/lambda/api-location --follow
   ```

---

## Service Dependencies

| Endpoint | Depends On | Timeout |
|---|---|---|
| `/location` | DynamoDB, ALS Tracker | 5s |
| `/wheatherdataget` | OpenWeatherMap API | 10s |
| `/wheatherforecasting` | OpenWeatherMap API | 15s |
| `/trigger-alert` | DynamoDB, SNS, Step Functions | 5s |
| `/respond-alert` | DynamoDB, Step Functions | 3s |

All endpoints include exponential backoff retry logic and comprehensive error logging.
