# ShadowTrace AI Roadmap — Phase 2 & Beyond

This document maps all planned enhancements to specific AWS services for seamless integration with the existing architecture.

## Phase 2 (Q3 2026) — Enterprise Features

### 1. Smartwatch Integration & Wearable IoT

**Goal**: Extend to Apple Watch, Wear OS, and custom IoT devices

| Component | AWS Service | Implementation |
|---|---|---|
| Device registration | IoT Core Thing | One Thing per wearable + custom attributes |
| Real-time telemetry | IoT Core MQTT | Subscribe to `shadowtrace/wearable/{deviceId}/telemetry` |
| Aggregated data | Kinesis Data Streams | Stream location + HR + motion to Kinesis |
| Processing | Lambda | Consume Kinesis stream, detect anomalies (HR spike, fall detection) |
| Storage | DynamoDB | `shadowtrace-wearable-data` table (TTL: 90 days) |
| Alerts | SNS | Publish "Fall detected" → trusted contacts |

**Code Path**:
```dart
// lib/services/wearable_service.dart
final wearableData = await getWearableData(deviceId);
if (wearableData.fallDetected) {
  triggerSOS(triggerType: 'fall_detected');
}
```

**Status**: Requires AWS IoT Greengrass Agent on device for offline support

---

### 2. AI Predictive Risk Analysis

**Goal**: ML model predicts hazard likelihood based on historical routes + weather + time of day

| Component | AWS Service | Implementation |
|---|---|---|
| Training data | S3 + DynamoDB | Historical trips, alerts, weather, geofence exits |
| Model training | SageMaker | Built-in XGBoost algorithm on tabular data |
| Model hosting | SageMaker Endpoint | Real-time inference (10ms latency) |
| Inference Lambda | Lambda | Calls `/predict-risk` with route + weather + time |
| Model monitoring | CloudWatch + ModelMonitor | Track prediction drift, retraining triggers |
| Feature store | DynamoDB | Pre-computed features (crime rate, accident history) |

**Code Path**:
```dart
// lib/screens/home_screen.dart
final prediction = await RouteService.predictRisk(origin, destination);
if (prediction.hazardScore > 0.7) {
  displayWarning('This route is high-risk');
}
```

**Model Features**:
- Time of day (rush hour multiplier)
- Day of week (weekend safety)
- Historical accident count in corridor
- Weather hazard likelihood
- Route type (highway vs. residential)
- Device type (phone battery %)

---

### 3. Offline Emergency SMS Fallback

**Goal**: Send emergency SMS if internet fails (no push notifications possible)

| Component | AWS Service | Implementation |
|---|---|---|
| SMS provider | Amazon SNS (native SMS) or Twilio | Fallback chain: FCM → SNS SMS → Twilio |
| Retry logic | Step Functions | Exponential backoff over 5 minutes |
| Cost optimization | Lambda | Detect offline mode, switch to SMS automatically |
| International | Twilio addon | Non-US numbers via Twilio SIP trunk |

**Code Path**:
```dart
// lib/services/notification_service.dart
if (connectivity.isOffline) {
  sendViaSMS(contact.phone, "SOS: ${location.lat},${location.lng}");
} else {
  sendViaPushNotification(contact); // FCM
}
```

**SMS Format**: `"SOS ALERT: 17.4065°N, 78.4772°E http://maps.google.com/?q=17.4065,78.4772"`

---

### 4. Voice AI Safety Assistant (Conversational)

**Goal**: Talk to an AI assistant about your route safety (hands-free UX)

| Component | AWS Service | Implementation |
|---|---|---|
| Speech input | Transcribe (real-time streaming) | Captures user speech continuously |
| NLU | Amazon Lex | Intent: `AskSafetyQuestion`, `RequestAlternativeRoute` |
| Response generation | LLM (Claude via Bedrock) | Generates conversational response |
| Text-to-speech | Polly | Converts response to audio (Emma or Joanna voice) |
| Session state | DynamoDB | Context stored per user (current location, trip) |

**Code Path**:
```dart
// lib/screens/voice_assistant_screen.dart
final response = await lex.postText(
  botName: 'ShadowTraceAssistant',
  botAlias: 'PROD',
  userId: userId,
  inputText: transcribedText,
);
polly.synthesizeSpeech(response).play();
```

**Example Conversation**:
```
User: "Is this route safe at night?"
Assistant: "You're planning Route 101 North. Night safety score is 62/100 
due to 3 incidents in the past month. I recommend taking Highway 95 instead, 
which has a score of 84/100. Would you like me to update your route?"
```

---

### 5. Biometric Authentication (Liveness + Face Recognition)

**Goal**: Multi-factor auth: SMS code + liveness check (prevents deepfakes)

| Component | AWS Service | Implementation |
|---|---|---|
| Face detection | Rekognition Face Liveness | Live selfie to verify real person |
| Face comparison | Rekognition Compare | Match against enrolled photo |
| MFA backend | Cognito | Custom Lambda trigger: `CustomMessage` + `CustomAuth` |
| Biometric storage | DynamoDB + S3 | Encrypted face embeddings (never raw images) |
| Audit log | CloudTrail | Track all auth attempts for compliance |

**Code Path**:
```dart
// lib/screens/login_screen.dart
final isLive = await Rekognition.detectFaceLiveness(selfieImage);
if (!isLive) {
  showError('Liveness check failed. Please try again.');
  return;
}
```

**Compliance**: Meets NIST 800-63B L2 (multi-factor) + GDPR (facial data privacy)

---

### 6. Government Emergency API Integration

**Goal**: Direct integration with DIAL 112 / PSAP (Public Safety Answering Point)

| Component | AWS Service | Implementation |
|---|---|---|
| Event bus | EventBridge | Partner event bus for government APIs |
| Data transformation | Lambda | Transform ShadowTrace alert → PSAP format (CAD feed) |
| API gateway | API Gateway | Rate-limited endpoint for gov agencies |
| Compliance | Secrets Manager | Store gov API credentials securely |
| Audit | CloudWatch Logs + S3 | Immutable audit trail (10-year retention) |

**Code Path**:
```dart
// backend/lambda/api/psap_integration/index.js
exports.handler = async (event) => {
  const sosAlert = event.detail;
  const psapPayload = {
    incidentType: 'MEDICAL_EMERGENCY', // or ROBBERY, ASSAULT, etc.
    location: {lat: sosAlert.lat, lng: sosAlert.lng},
    callerPhone: sosAlert.userId,
    audioStreamUrl: sosAlert.audioStreamUrl,
  };
  await callGovernmentPSAPAPI(psapPayload);
};
```

**Status**: Requires security audit + MOU with government agencies per country

---

### 7. Crime Zone Prediction

**Goal**: Real-time crime risk prediction using historical data + external data feeds

| Component | AWS Service | Implementation |
|---|---|---|
| Data source | S3 + Data Exchange | Subscribe to crime statistics (Policestat, CityGov) |
| ML model | SageMaker | Spatiotemporal model (GRU + attention) |
| Real-time query | Lambda + DynamoDB | Geohash-based lookup for O(1) prediction |
| Visualization | QuickSight | Dashboard: crime hotspots, temporal trends |
| Alerts | SNS | "High-crime zone detected: 7 robberies in past month" |

**Code Path**:
```dart
// lib/services/crime_prediction_service.dart
final crimeRisk = await predictCrimeRisk(lat: 17.4065, lng: 78.4772);
if (crimeRisk.riskLevel == 'CRITICAL') {
  showBanner('⚠️ This area has elevated crime risk. Consider an alternative route.');
}
```

**Data Integration**:
- NYC NYPD Complaint Data (AWS Data Exchange)
- Chicago Police Open Data
- National Crime Victimization Survey (NCVS)
- Real-time 911 dispatch feeds (optional)

---

## Phase 3 (Q4 2026) — Enterprise & Government

### 8. Web Admin Dashboard

**Goal**: Trusted contacts manage alerts; admins view analytics

| Component | AWS Service | Implementation |
|---|---|---|
| Frontend | Amplify + React + Material-UI | Hosted on Amplify (CDN + auto-deploy) |
| Auth | Cognito User Groups | `admin`, `contact`, `analyst` roles |
| API | API Gateway (existing) | Reuse `/trigger-alert`, `/contacts`, etc. |
| Analytics | Quicksight + Athena | Query S3 Parquet logs for dashboards |
| Alerting | SNS + EventBridge | Alert admin if SOS spike (>5 in 10 min) |

**Dashboard Pages**:
- **User**: View active trips, edit trusted contacts, settings
- **Contact**: Accept alerts, provide location, mark resolved
- **Admin**: Analytics, user statistics, system health

---

### 9. Smart Surveillance Integration

**Goal**: Integrate with public CCTV + doorbell cameras at incident scene

| Component | AWS Service | Implementation |
|---|---|---|
| Video intake | Kinesis Video Streams | Real-time video from CCTV at alert location |
| Processing | Rekognition Video | Object detection (weapons, vehicle), person tracking |
| Storage | S3 + Glacier | 30-day hot, 7-year cold archive (compliance) |
| Analysis | Step Functions | Orchestrate: detect → analyze → transcribe → store |
| Results | DynamoDB | Store analysis: "3 people, 1 vehicle, no weapons" |

**Code Path**:
```javascript
// backend/lambda/video_analyzer/index.js
const labels = await rekognition.startLabelDetection({
  Video: { S3Object: { Bucket: 'cctv-bucket', Name: `${alertId}.mp4` } }
});
// Labels: Person, Vehicle, Crowd, Gun, Knife, Fire, etc.
```

**Privacy**: Only processes frame-level aggregates, not faces (GDPR compliant)

---

### 10. Cross-Platform Scalability Overhaul

**Goal**: Scale to 1M+ concurrent users; reduce costs by 40%

| Component | AWS Service | Current → Improved |
|---|---|---|
| IaC | CloudFormation → AWS CDK | Type-safe, versioned infrastructure |
| Auto-scaling | Manual Lambda sizing → Compute Optimizer | Automatic right-sizing |
| Caching | None → ElastiCache + CloudFront | 90% cache hit on static routes |
| Database | DynamoDB (on-demand) → Provisioned + DynamoDB DAX | Consistent <10ms reads |
| Multi-region | us-east-1 only → Multi-region active-active | Global latency <100ms |
| Cost optimization | Basic monitoring → Trusted Advisor + Cost Anomaly Detection | Automated cost alerts |

**Architecture Diagram** (Post-optimization):
```
┌─────────────────────────────────────────────────────────┐
│  CloudFront (global edge caching)                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  API Gateway (regional + global accelerator)           │
│  (50M requests/month → 5M/month via cache)             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────┬──────────────────┬──────────────────┐
│  Lambda (ARM64   │  Lambda (ARM64   │  Lambda (ARM64   │
│  optimized)      │  optimized)      │  optimized)      │
│  us-east-1       │  eu-west-1       │  ap-southeast-1  │
└──────────────────┴──────────────────┴──────────────────┘
                          ↓
┌──────────────────┬──────────────────┬──────────────────┐
│  DynamoDB +      │  DynamoDB +      │  DynamoDB +      │
│  DAX             │  DAX             │  DAX             │
│  (provisioned)   │  (provisioned)   │  (provisioned)   │
└──────────────────┴──────────────────┴──────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Global Tables (cross-region replication <1s)          │
└─────────────────────────────────────────────────────────┘
```

**Cost Savings**:
- CloudFront caching: 40% reduction in Lambda invocations
- DAX: 80% reduction in DynamoDB read capacity
- ARM64 Lambda: 20% cost reduction vs. x86_64
- Reserved capacity: 30% savings on predictable load

---

## Implementation Timeline

| Phase | Quarter | Features | Team Size | Budget |
|---|---|---|---|---|
| Current | Q2 2026 | Core SOS, voice, geofence, weather | 2 engineers | $5K/mo |
| Phase 2 | Q3 2026 | Wearable, AI, SMS fallback, voice assistant | 4 engineers | $15K/mo |
| Phase 3 | Q4 2026 | Gov integration, CCTV, multi-region scale | 6 engineers | $30K/mo |

---

## Success Metrics

By end of Phase 3:

| Metric | Target | Current |
|---|---|---|
| User adoption | 100K active users | 1K (beta) |
| Alert response time | <30 seconds | 2 seconds ✅ |
| Uptime SLA | 99.99% | 99.95% |
| Cost per active user | <$0.10/month | $0.50/month |
| Incident prevention rate | 60% | TBD (Phase 2) |
| Government integration | 50+ PSAPs | 0 (Phase 3) |

---

## Tech Debt Cleanup

### Before Phase 2:
- [ ] Migrate from CloudFormation → CDK for all infrastructure
- [ ] Add distributed tracing (X-Ray) to all Lambda functions
- [ ] Implement request validation schema (JSON Schema)
- [ ] Add comprehensive integration tests (Pytest for Lambda)
- [ ] Set up CI/CD pipeline (GitHub Actions → CodePipeline)

### Ongoing:
- [ ] Security scanning: Snyk + SonarQube
- [ ] Dependency updates: Dependabot + Renovate
- [ ] Performance profiling: CloudWatch Logs Insights queries
- [ ] Cost tracking: AWS Budgets + anomaly detection
