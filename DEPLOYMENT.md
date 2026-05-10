# ShadowTrace Deployment Guide

## 1) Local Setup
1. Copy `.env.example` to `.env` and fill in:
   - `AWS_COGNITO_ISSUER_URL`
   - `AWS_COGNITO_CLIENT_ID`
   - `AWS_COGNITO_REDIRECT_URI`
   - `AWS_COGNITO_LOGOUT_URI`
   - `AWS_REGION`
   - `AWS_API_GATEWAY_URL`
   - `AWS_LOCATION_MAP_NAME`
   - `AWS_LOCATION_TRACKER_NAME`
   - Firebase keys
2. Ensure Firebase project is created and `google-services.json` / `GoogleService-Info.plist` are added.
3. Set `OPENAI_BACKEND_PROXY_URL` to your API Gateway URL and keep OpenAI credentials on the backend only.
4. Set `API_GATEWAY_CERT_SHA256` once your backend TLS certificate is stable.
5. Configure Cognito Hosted UI callback and sign-out URLs for the `shadowtrace://` scheme used by AppAuth.

### Cognito Hosted UI values
Use these exact values in the Cognito app client:
- Callback URL: `shadowtrace://callback`
- Sign-out URL: `shadowtrace://logout`
- Allowed OAuth flows: Authorization code grant
- Allowed OAuth scopes: `openid`, `profile`, `email`, `phone`
- Identity provider: Amazon Cognito User Pool

In the app client settings, ensure:
- `AWS_COGNITO_CLIENT_ID` matches the app client ID.
- `AWS_COGNITO_ISSUER_URL` points to your user pool issuer, for example `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXXXX`.
- `AWS_COGNITO_REDIRECT_URI` is set to `shadowtrace://callback`.
- `AWS_COGNITO_LOGOUT_URI` is set to `shadowtrace://logout`.

For Android and iOS:
- Android uses the `shadowtrace` redirect scheme in `android/app/build.gradle` and `AndroidManifest.xml`.
- iOS registers the `shadowtrace` URL scheme in `Info.plist`.

## 2) AWS Backend
Recommended services:
- Cognito for auth
- API Gateway for mobile endpoints
- Lambda for business logic
- DynamoDB for user/incident/device token storage
- SNS for alert fan-out
- Amazon Location Service for maps and trackers

Deploy order:
1. Deploy DynamoDB tables using `backend/infra/shadowtrace_full_stack.yaml` or split templates.
2. Deploy Lambda functions in `backend/lambda/`.
3. Create API Gateway routes for `/login`, `/register`, `/sos`, `/save_incident`, `/get_guardians`, `/update_live_location`, `/push_notification`, `/ai_request`.
4. Configure IAM roles from `backend/infra/lambda_device_tokens_iam.json` and the template.

## 3) Amazon Location Service
1. Create map and tracker resources in AWS Location Service.
2. Set `AWS_LOCATION_MAP_NAME` and `AWS_LOCATION_TRACKER_NAME` in `.env`.
3. Point `AWS_API_GATEWAY_URL` to your proxy API.

## 4) Firebase
1. Enable Cloud Messaging.
2. Add the Android and iOS app configs.
3. Configure FCM server-side permissions for notifications if needed.
4. Cognito now handles login and sign-up through the Hosted UI, so no Firebase Auth provider setup is required for authentication.

## 5) Android Release
Run:
```bash
flutter build apk --release
```

For Play Store, also create an AAB:
```bash
flutter build appbundle --release
```

## 6) iOS Release
Run:
```bash
flutter build ios --release
```

Open Xcode, sign the app, and archive for App Store submission.

## 7) CI/CD Suggestions
- `/.github/workflows/flutter_ci.yml` runs Flutter analyze, tests, and Android release build.
- `/.github/workflows/aws_backend_deploy.yml` validates and deploys the AWS backend with SAM.
- Keep secrets in GitHub Secrets and AWS Systems Manager Parameter Store.
