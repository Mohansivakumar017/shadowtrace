# ShadowTrace: AI-Powered Emergency Safety System

ShadowTrace is an intelligent emergency response platform that utilizes multi-stage escalation and AI monitoring to protect users.

## 🚀 Tech Stack

- **Frontend**: Flutter (Riverpod, GoRouter, Google Maps)
- **Backend**: AWS (Lambda, API Gateway, Step Functions, DynamoDB, SNS)
- **Notifications**: Firebase Cloud Messaging (FCM) + Flutter Local Notifications

---

## 🛠️ Setup Instructions

### Frontend (Flutter)
1. Install Flutter (Latest Stable).
2. Run `flutter pub get` to install dependencies.
3. Configure **Firebase**:
   - Place `google-services.json` in `android/app/`.
   - Place `GoogleService-Info.plist` in `ios/Runner/` (if using iOS).
4. Configure **Google Maps**:
   - Add your API Key to `AndroidManifest.xml`.
5. Run the app: `flutter run`.

### Backend (AWS)
1. **DynamoDB**: Create two tables:
   - `ShadowTraceAlerts`: Partition key `alertId`.
   - `ShadowTraceUsers`: Partition key `userId`.
2. **Lambda Functions**: Deploy the code from `backend/lambdas/` to AWS Lambda.
3. **API Gateway**: Create a REST API and map routes to the corresponding Lambdas.
4. **Step Functions**: Import the JSON from `backend/step-functions/` to create the workflow state machine.
5. **SNS**: Configure SNS for SMS delivery and grant Lambda permissions.

---

## 🛡️ Emergency Workflow

1. **SOS Trigger**: User initiates a critical alert.
2. **Monitoring**: System sends a push notification every 30 seconds for 3 attempts.
3. **Escalation**: If no response is received:
   - Guardian receives an emergency SMS via SNS.
   - High-decibel local siren notification activates.
   - Real-time GPS tracking is broadcast to the cloud.

---

## 📁 Project Structure

```
lib/
├── core/           # Core constants and themes
├── config/         # Routing and service configurations
├── services/       # Notification and Location services
├── screens/        # UI Pages (Dashboard, Tracking, Alert)
├── theme/          # Futuristic styling
backend/
├── lambdas/        # Node.js backend logic
├── step-functions/ # Emergency workflow definitions
```
