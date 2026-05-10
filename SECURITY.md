# ShadowTrace Security Notes

## Authentication
- Use Cognito Hosted UI with JWT-based sessions.
- Refresh tokens on a secure schedule.
- Validate tokens at API Gateway or Lambda.
- Treat guest sessions as limited-access sessions for monitoring and SOS alerts only.

## Local Storage
- Store sensitive values in `flutter_secure_storage`.
- Avoid plain-text storage in shared preferences.

## Network Security
- Use HTTPS only.
- Enable certificate pinning for production API calls through `API_GATEWAY_CERT_SHA256` once the backend certificate set is stable.
- Keep AWS credentials off the mobile client; use backend proxy endpoints for AWS Location Service and AI requests.
- Do not ship OpenAI API keys in the app. Route AI traffic through the backend `/ai_request` endpoint.

## Device Verification
- Bind device tokens to user IDs in DynamoDB.
- Reject unknown device IDs and suspicious token rotations.

## IAM
- Use least-privilege roles for Lambda and API Gateway.
- Separate read and write permissions for incident data.

## App Hardening
- Enable Android backup exclusions for sensitive data.
- Enable iOS background mode restrictions appropriately.
- Protect emergency and guardian endpoints with auth checks.
