# ShadowTrace AI

**Intelligent Travel Monitoring & Smart Emergency Assistant**

ShadowTrace AI is a personal safety platform that combines real-time GPS tracking, AI-based safe route analysis, automated emergency detection, and AWS cloud infrastructure into a unified mobile app for travelers, students, employees, and families.

[![AWS](https://img.shields.io/badge/Cloud-AWS-orange)](https://aws.amazon.com)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter-blue)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js-green)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Problem Statement

In today's world, personal safety during travel has become a critical concern. People travel alone for work, education, or personal reasons — and in emergency situations such as kidnapping, accidents, or theft, victims often cannot manually send alerts. Existing solutions lack continuous monitoring, quick emergency communication, and trusted-contact tracking. ShadowTrace AI addresses all three gaps in a single unified platform.

---

## Proposed Solution

ShadowTrace AI merges two safety frameworks into one cloud-native mobile platform:

**Case 1 — Smart Travel Monitoring:** Continuous GPS telemetry streamed to AWS, AI-based route selection evaluating weather/traffic/network, geofence corridor detection for route deviation, and automated dead-zone failsafe alerts.

**Case 2 — Emergency Detection & Remote Monitoring:** Hands-free voice SOS, silent SOS via power-button sequence, trusted-contact live location view, and automated SNS escalation — all without requiring physical phone interaction.

---

## Real-World Scenarios

| Scenario | Trigger | AWS Flow |
|---|---|---|
| Kidnapping / theft | Voice keyword ("help") | VoiceTrigger → POST /sos → Lambda → SNS → Trusted contacts |
| Network dead zone | No GPS ping for 5 min | Step Functions HeartbeatTimeout → alert_dispatch → SNS |
| Route deviation | Traveler leaves corridor | ALS Geofence EXIT → EventBridge → alert_dispatch → SNS |
| Trusted contact monitoring | Guardian opens app | GET /device-position → ALS GetDevicePosition → Flutter map |
| Silent SOS | Power button ×5 | SilentSosDetector.kt → POST /sos → SNS |

---

## System Architecture

```
Flutter App
    │
    ▼ (JWT via Cognito)
API Gateway (HTTP API)
    │
    ├─► Lambda: update_live_location ──► AWS Location Service (BatchUpdateDevicePosition)
    │                                         │
    │                                    Tracker ──► Geofence Collection
    │                                                      │
    │                                              EventBridge (EXIT event)
    │                                                      │
    ├─► Lambda: sos_handler ──────────────────────► SNS ──► Trusted Contacts (SMS/Push)
    │
    ├─► Lambda: route_calc ───────────────────────► ALS CalculateRoute + PutGeofence
    │                                               OpenWeatherMap (hazard flag)
    │
    ├─► Lambda: dead_zone_timer ─────────────────► Step Functions (HeartbeatSeconds: 300)
    │                                                      │ timeout
    │                                              alert_dispatch → SNS
    │
    └─► DynamoDB (shadowtrace-trips / locations / alerts / device-tokens)

Spatial Layer — Amazon Location Service (replaces PostGIS):
  • CalculateRoute       → route planning and ETA
  • PutGeofence          → route corridor deviation detection
  • BatchUpdateDevicePosition → live GPS telemetry streaming
  • GetDevicePosition    → trusted contact monitoring view
  • SearchPlaceIndexForPosition → reverse geocoding waypoints
  • CalculateRouteMatrix → multi-point distance calculation
  • GetStaticMap         → offline map tile caching
```

---

## AWS Resources Deployed

| Resource | Name | Region |
|---|---|---|
| ALS Tracker | `shadowtrace-tracker` | ap-south-1 |
| ALS Route Calculator | `shadowtrace-route-calc` | ap-south-1 |
| ALS Geofence Collection | `shadowtrace-routes` | ap-south-1 |
| ALS Place Index | `shadowtrace-place-index` | ap-south-1 |
| DynamoDB Table | `shadowtrace-trips` | ap-south-1 |
| DynamoDB Table | `shadowtrace-locations` | ap-south-1 |
| DynamoDB Table | `shadowtrace-alerts` | ap-south-1 |
| DynamoDB Table | `shadowtrace-device-tokens` | ap-south-1 |
| SNS Topic | `ShadowTraceSNSTopic` | ap-south-1 |
| Step Functions | `ShadowTraceEmergencyWorkflow` | ap-south-1 |
| Cognito User Pool | `ShadowTraceUserPool` | ap-south-1 |
| Cognito Identity Pool | (unauthenticated: `geo:GetMap*`) | ap-south-1 |
| API Gateway | HTTP API with JWT authorizer | ap-south-1 |

---

## Core Features

### Smart Live Tracking
- Continuous real-time GPS tracking via Flutter `geolocator` package
- Location streamed every 10 seconds to `shadowtrace-tracker` via `BatchUpdateDevicePosition`
- Live location sharing with trusted contacts via ALS `GetDevicePosition`
- Background tracking via Android foreground service (`SafetyForegroundService.kt`)
- Real-time sync latency under 2 seconds via API Gateway WebSocket / Firebase fallback

### AI/ML-Based Safe Route Selection
- Route calculation via ALS `CalculateRoute` (TravelMode: Walking/Driving)
- Weather hazard detection via OpenWeatherMap API at route midpoint
- Dynamic rerouting on hazard flag (Thunderstorm, Snow, Tornado)
- Route safety score calculated from historical location data in `shadowtrace-locations`
- Dead-zone segment prediction and pre-entry warning notification
- ETA computed from ALS `TravelTime` field, updated dynamically

### Dead-Zone Failsafe
- Step Functions state machine starts on every trip
- Each GPS ping sends `SendTaskHeartbeat` to reset the 300-second timer
- On `States.HeartbeatTimeout`: fetches last known position via `GetDevicePosition`, publishes SNS emergency alert
- Flutter shows 60-second pre-alert countdown card with CANCEL button
- Vibration warning at 60 seconds remaining (configurable via feature flag)

### Emergency SOS
- Manual SOS button → POST `/sos` → Lambda → SNS + DynamoDB alert log
- Voice SOS: keyword detection ("help", "emergency", "danger") via `speech_to_text`
- Silent SOS: 5 rapid power-button presses via `SilentSosDetector.kt`
- All SOS paths converge on the same Lambda handler for consistent escalation

### Route Deviation Detection (Server-Side)
- After `CalculateRoute`, Lambda creates 200m geofence corridor via `PutGeofence`
- `AssociateTrackerConsumer` links tracker to geofence collection
- ALS publishes EXIT events to EventBridge automatically — zero polling
- EventBridge rule (source: `aws.geo`, EventType: EXIT) triggers `alert_dispatch` Lambda
- Alert dispatch publishes SNS with deviation coords to trusted contacts

### Trusted Contact Monitoring
- Authorized contacts log in with their own Cognito account
- Live traveler position fetched via ALS `GetDevicePosition`
- Displayed on MapLibre GL map with ALS tiles (SigV4 signed via Cognito unauthenticated role)
- Alert history shown per contact from `shadowtrace-alerts` table

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Android Native | Kotlin (MVVM + StateFlow) |
| Backend | Node.js AWS Lambda |
| API Layer | AWS API Gateway (HTTP API, JWT authorizer) |
| Auth | AWS Cognito User Pool + Identity Pool |
| Location & Maps | AWS Location Service (Tracker, RouteCalc, Geofence, PlaceIndex) |
| Map Rendering | MapLibre GL (`maplibre_gl` Flutter package) |
| Database | AWS DynamoDB (3 tables + device tokens) |
| Notifications | AWS SNS (SMS + push) |
| Dead-Zone Timer | AWS Step Functions (HeartbeatSeconds: 300) |
| Event Routing | AWS EventBridge (geofence EXIT events) |
| Weather | OpenWeatherMap API (free tier) |
| IaC | AWS CloudFormation (`backend/infra/shadowtrace_full_stack.yaml`) |
| Real-Time | API Gateway WebSocket API |

> **Note:** Amazon Location Service replaces the PostGIS/PostgreSQL spatial layer. `CalculateRoute`, `PutGeofence`, `SearchPlaceIndexForPosition`, and `CalculateRouteMatrix` cover all spatial query requirements natively on AWS.

> **Note:** AWS Step Functions replaces Celery for background task queue / dead-zone countdown timer logic.

---

## Project Structure

```
shadowtrace/
├── lib/                          # Flutter app
│   ├── config/
│   │   ├── app_config.dart       # API URLs, resource names, constants
│   │   └── feature_flags.dart    # Feature toggles (SILENT_SOS, OFFLINE_MAP, etc.)
│   ├── screens/
│   │   ├── home_screen.dart      # Trip start/end, active trip card
│   │   ├── live_tracking_screen.dart  # MapLibre map, live dot, route overlay
│   │   ├── voice_command_screen.dart  # speech_to_text SOS
│   │   ├── trusted_contacts_screen.dart
│   │   └── login_screen.dart
│   ├── services/
│   │   ├── location_service.dart      # Streams GPS → POST /location
│   │   ├── sos_service.dart           # POST /sos, voice SOS, cancel
│   │   ├── route_service.dart         # startTrip, endTrip, getDevicePosition
│   │   ├── auth_service.dart          # Cognito sign-in/sign-up/JWT
│   │   └── offline_map_cache.dart     # ALS GetStaticMap → SQLite tiles
│   └── widgets/
│       ├── dead_zone_countdown.dart   # 300s countdown with cancel
│       └── silent_sos_detector.dart   # Power-button ×5 detector
├── app/src/main/java/com/shadowtrace/safeassist/   # Android Kotlin
│   ├── MainActivity.kt
│   ├── SafetyForegroundService.kt
│   ├── StallDetector.kt
│   ├── DeadZoneTimerService.kt
│   ├── SilentSosDetector.kt
│   └── AlertDispatcher.kt
├── backend/
│   ├── lambda/
│   │   ├── shared.js                  # JWT validation, input sanitization, AWS clients
│   │   └── api/
│   │       ├── sos/index.js
│   │       ├── update_live_location/index.js
│   │       ├── dead_zone_timer/index.js
│   │       ├── route_calc/index.js
│   │       ├── alert_dispatch/index.js
│   │       ├── register_device_token/index.js
│   │       └── safety_score/index.js
│   ├── step-functions/
│   │   └── emergency_workflow.json    # ASL: HeartbeatSeconds:300 → SNS on timeout
│   ├── infra/
│   │   └── shadowtrace_full_stack.yaml  # Complete CloudFormation stack
│   └── tests/
│       ├── sos.test.js
│       ├── location.test.js
│       └── dead_zone.test.js
├── ARCHITECTURE.md
├── SCENARIOS.md
├── ROADMAP.md
├── DEPLOYMENT.md
├── SECURITY.md
└── .env.example
```

---

## API Endpoints

| Method | Path | Lambda | Auth |
|---|---|---|---|
| POST | `/location` | `update_live_location` | JWT |
| POST | `/sos` | `sos_handler` | JWT |
| POST | `/sos/cancel` | `sos_handler` | JWT |
| POST | `/trip/start` | `route_calc` | JWT |
| POST | `/trip/end` | `route_calc` | JWT |
| POST | `/heartbeat` | `dead_zone_timer` | JWT |
| GET | `/device-position/{userId}` | `update_live_location` | JWT |
| GET | `/safety-score` | `safety_score` | JWT |
| POST | `/device-token` | `register_device_token` | JWT |

---

## Dead-Zone Countdown Flow

```
Trip starts
    │
    ▼
Step Functions workflow begins (HeartbeatSeconds: 300)
    │
    ├── Every 10s: GPS ping → POST /location → SendTaskHeartbeat → timer resets
    │
    └── No ping for 300s (network dead zone):
            │
            ▼
        States.HeartbeatTimeout
            │
            ▼
        GetDevicePosition (last known coords)
            │
            ▼
        SNS → Trusted contacts: "DEAD ZONE ALERT: last seen at [lat, lng]"
            │
            ▼
        DynamoDB trip status → DEAD_ZONE_ALERT
```

Flutter shows a 60-second pre-alert countdown card (configurable via `PRE_ALERT_VIBRATION` feature flag). User can cancel by tapping the button, which calls `POST /heartbeat` to reset the Step Functions timer.

---

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for full setup instructions.

**Quick start:**

```bash
# 1. Deploy AWS infrastructure
cd backend/infra
aws cloudformation deploy \
  --template-file shadowtrace_full_stack.yaml \
  --stack-name shadowtrace-prod \
  --parameter-overrides Environment=prod OWMApiKey=YOUR_KEY \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1

# 2. Deploy Lambda functions
cd backend/lambda
npm install
zip -r functions.zip .
# (API Gateway + Lambda ARNs auto-configured via CloudFormation)

# 3. Run Flutter app
cd lib
flutter pub get
flutter run
```

---

## Environment Variables

See [.env.example](.env.example) for all required values. Key variables:

```
API_BASE_URL=https://<api-gw-id>.execute-api.ap-south-1.amazonaws.com
USER_POOL_ID=ap-south-1_XXXXXXXXX
CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
IDENTITY_POOL_ID=ap-south-1:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
OWM_KEY=<openweathermap-api-key>
SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:XXXXXXXXXXXX:ShadowTraceSNSTopic
TRACKER_NAME=shadowtrace-tracker
ROUTE_CALC_NAME=shadowtrace-route-calc
GEOFENCE_COLLECTION=shadowtrace-routes
```

---

## Testing

```bash
# Backend (Jest)
cd backend
npm test

# Android (Kotlin)
./gradlew test

# Flutter
flutter test
```

Test coverage: `sos.test.js`, `location.test.js`, `dead_zone.test.js`, `StallDetectorTest.kt`, Flutter widget tests for live tracking and SOS screens.

---

## In Scope

- Live location sharing to AWS backend
- Dynamic route safety analysis (weather + traffic integration)
- Network dead-zone predictive alerts and Step Functions timer logic
- Voice-activated SOS triggers
- Silent SOS via power-button sequence
- Trusted contact emergency alerts via SNS
- Remote situational monitoring (location view for trusted contacts)
- Server-side route deviation detection via ALS geofence + EventBridge

## Out of Scope

- Direct integration with police CAD systems
- Physical hardware / wearable panic buttons
- Offline peer-to-peer mesh networking
- Non-smartphone GPS tracking devices

---

## Future Enhancements

| Enhancement | Status | AWS Service Required |
|---|---|---|
| Silent SOS power-button sequence | Stub implemented (`SilentSosDetector.kt`) | No new service |
| Offline map caching for dead zones | Stub implemented (`offline_map_cache.dart`) | ALS `GetStaticMap` |
| Pre-alert vibration warning (60s cancel) | Implemented (`dead_zone_countdown.dart`) | — |
| Aggregated Safety Scores per route | Stub implemented (`safety_score/index.js`) | ALS `SearchPlaceIndexForPosition` + DynamoDB aggregation |

---

## Security

- All API endpoints protected by Cognito JWT authorizer on API Gateway
- Lambda functions validate JWT via `aws-jwt-verify` — no anonymous fallback
- Input sanitization on all Lambda handlers (field validation + lat/lng range checks)
- IAM roles follow least-privilege: SNS publish scoped to `!Ref ShadowTraceSNSTopic`
- Cognito Identity Pool unauthenticated role scoped to `geo:GetMap*` and `geo:GetPlace*` only
- End-to-end location data encrypted in transit (HTTPS) and at rest (DynamoDB encryption enabled)

See [SECURITY.md](SECURITY.md) for full details.

---

## Team

**PS-065 · AWS Development with DevOps**

| Name | Role |
|---|---|
| Mohansivakumar | Team Leader / Backend |
| Marla Bharghav Sai | Flutter / Frontend |
| Gowthu V V Satya Sai Datta Manikanta | Android / Kotlin |

---

## License

MIT License — see [LICENSE](LICENSE) for details.
