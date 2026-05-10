# ShadowTrace Real-World Scenarios

This document maps real-world safety scenarios to the exact code paths in ShadowTrace.

## Scenario 1: Theft/Kidnapping Detection via Voice

**Situation**: User is abducted and cannot use the app normally. They have 5 seconds to trigger SOS.

**Code Path**:
1. User says "help" / "SOS" / "emergency" / "danger"
2. **VoiceCommandScreen** (`lib/screens/voice_command_screen.dart`)
   - `_speechToText.listen()` detects keywords
   - Calls `_processCommand()` → `_triggerVoiceSOS()`
3. **SOSService** (`lib/services/sos_service.dart`)
   - `triggerVoiceSOS()` gets last known location from `LocationService`
   - Calls `triggerSOS(lat, lng)`
   - POST `/sos` endpoint with JWT
4. **SOS Lambda Handler** (`backend/lambda/api/sos/index.js`)
   - Calls `getCurrentUserId()` — throws 401 if no valid JWT
   - Calls `validateInput({lat, lng})`
   - Writes to `shadowtrace-alerts` DynamoDB table with `status: 'ACTIVE'`
   - Publishes SNS message: `"SOS_TRIGGERED"` with location to `ALERTS_TOPIC`
   - Calls `stepFunctions.startExecution()` with emergency workflow
5. **Step Functions Workflow** (`backend/step-functions/emergency_workflow.json`)
   - Enters `WaitForHeartbeat` state
   - Waits for heartbeat with 300s timeout
6. **Trusted Contacts Notified**
   - SNS topic delivers alert with last known coordinates
   - Example: "User at coordinates 28.6139, 77.2090. No response expected."

**Result**: Guardians receive immediate push notification with user's location. Step Functions countdown begins.

---

## Scenario 2: Network Dead Zone During Walk

**Situation**: User starts a trip through a forest with no cellular coverage. After 300 seconds of no location update, system auto-escalates.

**Code Path**:
1. User taps "Start Trip" on **HomeScreen**
   - Calls `route_service.startTrip(origin, destination)`
2. **RouteCalcLambda** calculates 45-minute walking route
   - Returns `polyline`, `eta`, `hazardFlag`
   - Stores trip in DynamoDB: `tripId=trip-abc123, status=ACTIVE`
   - **Returns taskToken** (from Step Functions) to mobile app
3. Trip starts. **LocationService** sends position every 10 seconds
   - Each POST to `/location` triggers `LocationLambda`
4. **LocationLambda** (`backend/lambda/api/update_live_location/index.js`)
   - Calls `location.batchUpdateDevicePosition()` → ALS updates tracker
   - Logs position to `shadowtrace-locations` table
   - **Calls `stepFunctions.sendTaskHeartbeat(taskToken)`** ← CRITICAL
   - This resets the 300s dead-zone timeout
5. **User enters dead zone** (no GPS signal for >300s)
   - Location updates stop coming
   - LocationService stops posting heartbeats
6. **Step Functions Timeout Triggers** (HeartbeatTimeout)
   - Executes `TriggerAlert` state
   - Invokes **DeadZoneLambda** (`backend/lambda/api/dead_zone_timer/index.js`)
7. **DeadZoneLambda**:
   - Calls `location.getDevicePosition(userId)` — gets last known coords
   - Publishes SNS alert: `"DEAD_ZONE_TIMEOUT"` with last position
   - Updates trip status: `status=DEAD_ZONE_ALERT`
8. **Trusted Contacts Notified**:
   - SMS/Push: "User entered dead zone near [place]. Last seen at [lat,lng] 5 minutes ago."

**Result**: Guardians are notified of potential danger in low-signal areas. Human follow-up can begin.

---

## Scenario 3: Route Deviation Detection

**Situation**: User starts trip from home to office. Leaves planned route to detour through a dangerous area.

**Code Path**:
1. User starts trip via HomeScreen → `RouteCalcLambda` creates geofence
   - `location.putGeofence()` stores 200m buffer around route polyline
   - Geofence stored in `shadowtrace-routes` collection
2. User deviates 500m from route (outside 200m buffer)
3. **ALS Tracker detects EXIT event**
   - EventBridge rule (`shadowtrace-geofence-exit`) catches it
4. **EventBridge** triggers **AlertDispatchLambda** with event:
   ```json
   {
     "source": "aws.geo",
     "detail-type": "Location Geofence Event",
     "detail": {
       "DeviceId": "user-123",
       "Position": [77.215, 28.605],
       "EventType": "EXIT"
     }
   }
   ```
5. **AlertDispatchLambda** (`backend/lambda/api/alert_dispatch/index.js`):
   - Queries `shadowtrace-trips` GSI for active trip by userId
   - Fetches `shadowtrace-contacts` for trusted contact list
   - Publishes SNS: `"ROUTE_DEVIATION"` with contact names + location
   - Updates trip: `status=DEVIATION`
6. **Trusted Contacts Notified**:
   - "ROUTE DEVIATION: User has left planned route near [place]. Last position: [28.605, 77.215]"

**Result**: Guardians are alerted to unexpected route changes. Can follow up if needed.

---

## Scenario 4: Safety Score for Dangerous Routes

**Situation**: User plans a late-night trip and wants to know the safety rating of their route.

**Code Path**:
1. After route calculation, HomeScreen shows trip preview
2. User taps "Check Safety Score"
3. Calls `SafetyScoreService` → POST `/safety-score` with `routePolyline`
4. **SafetyScoreLambda** (`backend/lambda/api/safety_score/index.js`):
   - Queries `shadowtrace-locations` for historical trips by userId
   - Identifies past deviations (positions >100m from polyline)
   - Deducts 10 points per past deviation event
   - Checks trip table for `hazardFlag==true` (bad weather)
   - Deducts 15 points if weather hazard
   - Calls `location.searchPlaceIndexForPosition()` on each waypoint
   - Returns labels: ["Central Station", "Park Avenue", "Office Building"]
5. Returns JSON:
   ```json
   {
     "safetyScore": 75,
     "riskFactors": ["2 past deviation events", "Weather hazard flagged"],
     "waypointNames": ["Central Station", "Park Avenue", "Office Building"],
     "deviationCount": 2
   }
   ```
6. UI displays: **"75/100 - Moderate Risk"** with risk breakdown

**Result**: User can decide whether to proceed, take different route, or inform guardians in advance.

---

## Scenario 5: Trusted Contact Live Monitoring

**Situation**: Guardian wants to check where a protected user currently is.

**Code Path**:
1. Guardian opens **TrustedContactsScreen** in their ShadowTrace app
2. Taps on user "Sarah" → Taps "View Location"
3. Calls `route_service.getDevicePosition("sarah-user-id")`
4. POST `/device-position/sarah-user-id` with JWT
5. **API Handler** calls `location.getDevicePosition(userId)`
   - ALS returns latest position from `shadowtrace-tracker`
6. Returns:
   ```json
   {
     "lat": 28.612,
     "lng": 77.216,
     "lastUpdate": "2026-05-10T14:35:00Z"
   }
7. UI updates map marker to Sarah's current position
8. If position is >5 minutes old → shows warning "Location is stale"

**Result**: Guardian has peace of mind. Can see user's real-time or recent position.

---

## Scenario 6: Silent SOS (5 Rapid Power Button Presses)

**Situation**: User is in immediate danger but can't openly call for help.

**Code Path**:
1. **SilentSosDetector** (Kotlin: `app/src/main/java/.../SilentSosDetector.kt`)
   - Listens for `ACTION_SCREEN_OFF` broadcasts
   - Counts 5 presses within 3 seconds
2. Calls `triggerSilentSOS()`
3. Makes HTTP POST to `/sos` endpoint
4. Same flow as Scenario 1 (Voice SOS)
5. **Key difference**: No voice confirmation needed
   - Discreet, no audio/screen activity
   - Appears like accidental presses to attacker
6. Shows heads-up notification: "SOS triggered. Guardians notified."

**Result**: Immediate emergency alert sent without alerting attacker.

---

## Scenario 7: Dead Zone Warning (60s Mark)

**Situation**: User's phone loses signal. App shows visual/haptic warning at 60 seconds remaining.

**Code Path**:
1. No location update received for 60 seconds
2. **LiveTrackingScreen** (Flutter: `lib/screens/live_tracking_screen.dart`)
   - Internal timer `_deadZoneCounter` increments
   - At 60s: `setState(() => _showDeadZoneWarning = true)`
3. **DeadZoneCountdown** widget appears:
   - Shows countdown from 240s (5 minutes - 60s elapsed)
   - Circular progress indicator
4. If `PRE_ALERT_VIBRATION` feature flag enabled:
   - `Vibration.vibrate(duration: 500)` at 60s mark
5. User can tap "Send Heartbeat" → POST `/heartbeat`
   - Resets counter
   - OR timer continues to 300s → auto-SOS

**Result**: User aware of escalating danger. Can take action if in tunnel/covered area.

---

## Critical Environment Variables

Each scenario depends on correct configuration:

```bash
# In .env (backend)
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXX
COGNITO_CLIENT_ID=YOUR_CLIENT_ID
API_BASE_URL=https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/dev
SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:ACCOUNT:shadowtrace-sns
EMERGENCY_WORKFLOW_ARN=arn:aws:states:ap-south-1:ACCOUNT:stateMachine:ShadowTraceEmergencyWorkflow
OWM_KEY=YOUR_OPENWEATHER_API_KEY  # For weather hazard detection

# In .env (Flutter)
API_BASE_URL=https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/dev
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXX
COGNITO_CLIENT_ID=YOUR_CLIENT_ID
```

---

## Testing Scenarios

To verify each scenario locally:

1. **Test Voice SOS**: Use `speech_to_text` mock in integration tests
2. **Test Dead Zone**: Mock location stream stopping via `StreamController.pause()`
3. **Test Route Deviation**: Create geofence, move device >200m away via simulator
4. **Test Safety Score**: Pre-populate `shadowtrace-locations` with past deviations
5. **Test Silent SOS**: Fire `ACTION_SCREEN_OFF` broadcast via `adb shell am broadcast`
6. **Test Trusted Contact Monitoring**: Call `location.getDevicePosition()` directly
