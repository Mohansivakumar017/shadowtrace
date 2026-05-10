# ShadowTrace – Personal Safety Travel App

ShadowTrace is a personal safety platform that provides real-time tracking, intelligent route monitoring, automatic dead-zone detection, and emergency response coordination using AWS native services.

## 🎯 Core Features

### 🔴 Live Tracking
- Real-time GPS tracking every 10 seconds
- Location updates via AWS Location Service Tracker
- Background tracking support
- Live position sharing with trusted contacts

### 🧭 Intelligent Route Planning
- AWS Location Service CalculateRoute integration
- 200m safety corridor geofencing around planned routes
- Weather hazard detection via OpenWeather API
- Safety scoring based on historical deviations
- ETA calculation for destination arrival

### ⏰ Dead Zone Detection
- Automatic 300-second timeout on location updates
- Visual countdown warning at 60 seconds
- Haptic feedback option (PRE_ALERT_VIBRATION)
- Automatic SOS trigger on complete timeout
- Step Functions orchestration for reliable timing

### 🆘 Emergency Response
- Manual SOS button (red FAB)
- Voice command SOS ("help", "SOS", "emergency", "danger")
- Silent SOS (5 rapid power button presses)
- Instant guardian notifications via SNS
- Route deviation alerts via EventBridge/Geofence EXIT events

### 🛡️ Guardian Dashboard
- Real-time location monitoring of protected users
- Route deviation notifications
- Dead zone alerts with last known position
- Emergency escalation tracking
- SOS alert history

## 🏗️ System Architecture

```
Flutter Mobile App
  ↓ (HTTP + JWT)
API Gateway (HTTP, JWT Authorizer)
  ↓
Lambda Functions:
  - sos: Trigger emergency alerts
  - update_live_location: Location streaming
  - dead_zone_timer: Timeout detection
  - route_calc: Path planning + weather analysis
  - alert_dispatch: Guardian notifications
  - safety_score: Historical analysis
  ↓
AWS Services:
  - Cognito: Authentication (User Pool + Identity Pool)
  - DynamoDB: Data persistence (trips, locations, alerts, contacts)
  - Location Service: Tracker, RouteCalculator, GeofenceCollection, PlaceIndex
  - SNS: Guardian notifications
  - Step Functions: Dead-zone workflow orchestration
  - EventBridge: Geofence EXIT → alert routing
  - CloudFormation: Infrastructure as Code
```

## 📊 Data Flow

### Trip Initiation
1. User enters origin/destination on HomeScreen
2. POST /route → RouteCalcLambda
3. RouteCalcLambda:
   - Calls ALS CalculateRoute (Esri data source)
   - Fetches weather data (OpenWeatherMap free tier)
   - Creates 200m buffer geofence
   - Stores trip with taskToken
4. Returns polyline, ETA, hazardFlag, tripId

### Live Tracking
1. LocationService.startTracking(tripId)
2. Geolocator stream emits position every 10s
3. POST /location with lat, lng, tripId, timestamp
4. LocationLambda:
   - Updates ALS Tracker via BatchUpdateDevicePosition
   - Logs to shadowtrace-locations table
   - **Sends heartbeat to Step Functions** (resets 300s timer)

### Dead Zone Scenario
1. No location update for 300 seconds
2. Step Functions HeartbeatTimeout fires
3. DeadZoneLambda invoked:
   - Calls ALS GetDevicePosition (last known location)
   - Publishes SNS alert
   - Updates trip status to DEAD_ZONE_ALERT
4. Guardians receive notification with stale coordinates

### Route Deviation
1. User location exits 200m geofence buffer
2. ALS fires EXIT event → EventBridge rule
3. AlertDispatchLambda invoked:
   - Fetches active trip
   - Gets trusted contacts
   - Publishes SNS deviation alert
4. Guardians notified of off-route behavior

## 🔐 Authentication & Authorization

- **Cognito User Pool**: Email/password authentication
- **Cognito Identity Pool**: Unauthenticated access for maps (geo:GetMap*)
- **JWT Tokens**: API Gateway validates ID tokens before routing to Lambda
- **Least Privilege**: Lambda execution role scoped to specific resources (SNS topic, DynamoDB tables, ALS services)

## 📱 Tech Stack

### Frontend (Flutter)
- **maplibre_gl** — Maps with ALS tile layer
- **geolocator** — GPS positioning
- **speech_to_text** — Voice commands
- **amplify_flutter + amplify_auth_cognito** — AWS authentication
- **http** — API calls
- **sqflite** — Offline map caching
- **vibration** — Haptic feedback
- **local_notifications** — Push notifications

### Backend (Node.js Lambda)
- **aws-sdk v3** — AWS service integration
- **aws-jwt-verify** — Token validation without Cognito API calls
- **https** — OpenWeatherMap API calls

### Infrastructure (CloudFormation)
- **Cognito User Pool & Identity Pool**
- **DynamoDB Tables** (trips, locations, alerts, device-tokens)
- **Lambda Functions** (6 total: sos, location, dead-zone, route-calc, alert-dispatch, safety-score)
- **API Gateway HTTP API** with JWT authorizer
- **Location Service** (Tracker, RouteCalculator, GeofenceCollection, PlaceIndex)
- **SNS Topic** for alerts
- **Step Functions** state machine for dead-zone orchestration
- **EventBridge Rule** for geofence EXIT events

## 🚀 Deployment

### Prerequisites
```bash
# Install dependencies
cd backend && npm install
cd ../app && flutter pub get

# Configure AWS credentials
aws configure

# Set environment variables
cp .env.example .env
# Edit .env with your Cognito IDs, OpenWeatherMap key, etc.
```

### Deploy Infrastructure
```bash
aws cloudformation create-stack \
  --stack-name shadowtrace-stack \
  --template-body file://backend/infra/shadowtrace_full_stack.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
               ParameterKey=OWMApiKey,ParameterValue=YOUR_KEY \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1
```

### Deploy Lambda Functions
```bash
# Package and upload each Lambda
cd backend/lambda/api/sos
zip -r function.zip .
aws lambda update-function-code --function-name sos --zip-file fileb://function.zip
```

### Deploy Flutter App
```bash
cd lib
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design, data flow diagrams, service interactions
- **[SCENARIOS.md](SCENARIOS.md)** — Real-world use cases mapped to code paths

## 🔧 Configuration

### Deployed Resources (Region: ap-south-1)

| Service | Name |
|---------|------|
| Cognito User Pool | shadowtrace-pool |
| Tracker | shadowtrace-tracker |
| Route Calculator | shadowtrace-route-calc |
| Geofence Collection | shadowtrace-routes |
| Place Index | shadowtrace-place-index |
| SNS Topic | shadowtrace-sns |
| Step Functions | ShadowTraceEmergencyWorkflow |

### Environment Variables

See [.env.example](.env.example) for complete list. Key variables:

```bash
AWS_REGION=ap-south-1
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXX
SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:ACCOUNT:shadowtrace-sns
EMERGENCY_WORKFLOW_ARN=arn:aws:states:ap-south-1:ACCOUNT:stateMachine:ShadowTraceEmergencyWorkflow
OWM_KEY=your_openweathermap_api_key
```

## 📊 Feature Flags

Configure in `lib/config/feature_flags.dart`:

- `SILENT_SOS_ENABLED` — 5-press power button SOS (requires hardware_buttons)
- `OFFLINE_MAP_CACHE` — Cache map tiles locally (sqflite)
- `PRE_ALERT_VIBRATION` — Haptic feedback at dead zone 60s warning
- `SAFETY_SCORES_ENABLED` — Route safety analysis

## 🧪 Testing

```bash
# Backend unit tests
cd backend && npm test

# Flutter widget tests
cd lib && flutter test
```

## 📝 License

Proprietary — Personal Safety Project


### AWS Lambda
Serverless backend logic for:
- SOS processing
- Weather forecasting
- Route analysis
- Location verification
- Emergency workflows

### Amazon API Gateway
REST APIs for:
- Live tracking
- Emergency alerting
- Route monitoring
- Weather services
- User verification

### Amazon SNS
Used for:
- Emergency notifications
- OTP verification
- SMS alerts
- Guardian alert broadcasting

### Amazon Cognito
Authentication and authorization system:
- Secure login/signup
- OTP verification
- JWT authentication
- User session management

### Amazon DynamoDB
Stores:
- User live locations
- Tracking history
- SOS events
- Emergency logs
- Stationary detection records

### AWS Location Service
Provides:
- Maps integration
- Live navigation
- Route generation
- Real-time location visualization
- Tracking visualization

### CloudWatch
- API monitoring
- Lambda logs
- Performance tracking
- Error diagnostics

---

# 📲 Live Multi-User Sharing

Users can share their:
- Live location
- Route progress
- ETA
- Emergency status

with:
- Parents
- Guardians
- Friends
- Emergency contacts

Features include:
- Multi-user live monitoring
- Shared tracking dashboard
- Emergency broadcast system

---

# 🔐 Security Features

- JWT-based authentication
- AWS Cognito secure sessions
- OTP verification
- Encrypted API communication
- Role-based access
- Secure cloud infrastructure

---

# 🧩 Technology Stack

## Frontend
- Flutter
- Kotlin (Android modules)
- Jetpack Compose

## Backend
- AWS Lambda
- API Gateway
- Node.js
- Python FastAPI

## Database
- DynamoDB
- PostgreSQL
- PostGIS

## Cloud Services
- AWS SNS
- AWS Cognito
- AWS Location Service
- AWS IoT Core
- Firebase Realtime Database

## AI/ML
- Safe route prediction
- Intelligent route analysis
- Weather-aware path optimization
- Emergency behavior analysis

---

# 🔗 API Endpoints

## Emergency APIs

### Trigger Emergency Alert
POST
```bash
/respond-alert
```

### SOS Alert API
POST
```bash
/trigger-alert
```

### Live Location API
POST
```bash
/location
```

---

# 🌐 API Gateway URLs

```bash
https://ycr7hmmo89.execute-api.us-east-1.amazonaws.com/dev
```

```bash
https://bt0afo9upa.execute-api.us-east-1.amazonaws.com/dev
```

---

# 🛠 Project Architecture

The system follows a cloud-native serverless architecture.

## Workflow
1. Mobile app continuously tracks user location
2. AWS Location Service processes mapping and routes
3. Lambda functions analyze movement and route safety
4. AI engine predicts best and safest path
5. DynamoDB stores telemetry and travel history
6. SNS sends alerts during emergencies
7. Guardians receive live tracking and emergency notifications

---

# 📌 Advanced Features

## Dead-Zone Detection
- Detects low network coverage areas
- Sends predictive safety alerts
- Starts emergency countdown timer

## Smart Emergency Escalation
- Automatic emergency triggering
- Voice-assisted activation
- Location inactivity monitoring

## Real-Time Notifications
- Push notifications
- SMS alerts
- Emergency broadcasts

---

# 📂 Project Structure

```bash
shadowtrace/
│
├── frontend/
│   ├── flutter_app/
│   └── android_modules/
│
├── backend/
│   ├── lambda/
│   ├── api_gateway/
│   ├── dynamodb/
│   ├── cognito/
│   └── sns/
│
├── ai_ml/
│   ├── route_prediction/
│   └── safety_analysis/
│
├── docs/
└── README.md
```

---

# ⚙ Setup Instructions

## Clone Repository
```bash
git clone https://github.com/Mohansivakumar017/shadowtrace
```

## Install Dependencies
```bash
flutter pub get
```

## Configure Environment Variables
Create `.env` file:

```env
AWS_REGION=
COGNITO_POOL_ID=
COGNITO_CLIENT_ID=
AWS_LOCATION_MAP=
SNS_TOPIC_ARN=
OPENWEATHER_API_KEY=
```

---

# ▶ Run Project

```bash
flutter run
```

---

# 📈 Future Enhancements

- Offline map caching
- Power-button silent SOS trigger
- AI danger-zone prediction
- Smart wearable integration
- Real-time crime analytics
- Emergency video/audio streaming
- Satellite emergency mode

---

# 👨‍💻 Developed For
AWS Development with DevOps Project Review

## Team
PS-065

## Project Title
ShadowTrace Travel AI

---

# 📜 Conclusion

ShadowTrace AI is a next-generation intelligent safety ecosystem that combines AI, cloud computing, live monitoring, emergency automation, and smart route intelligence into a single scalable platform.

The system focuses on:
- Proactive safety
- Intelligent emergency detection
- Real-time communication
- AI-assisted travel monitoring
- Cloud-native scalability

It provides a complete smart safety solution for modern travel and personal protection scenarios.
