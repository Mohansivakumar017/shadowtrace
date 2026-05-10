# Backend Setup (AWS Serverless)

This folder contains a skeleton for AWS serverless resources used by ShadowTrace.

Key components to implement and deploy:
- Cognito User Pool & Identity Pool (phone/email auth)
- API Gateway + Lambda functions (Node.js / Python)
- DynamoDB tables: Users, Guardians, Incidents, LiveTracking, EmergencyLogs, Notifications, Routes, DeviceTokens
- SNS topics for critical alerts
- S3 for media evidence storage
- CloudWatch logs and Step Functions for workflows

Amazon Location Service:
- Use Amazon Location Service for maps, geofencing, trackers, and route analysis.
- Provide a backend proxy (Lambda) to call Amazon Location APIs (avoid storing AWS secrets in the mobile app).
- Example Lambda proxies are under `backend/lambda/location_proxy/`.

Infrastructure (CloudFormation):
- `backend/infra/device_tokens_table.yaml` provides a CloudFormation template for the `DeviceTokens` table.
- `backend/infra/lambda_device_tokens_iam.json` has a minimal IAM policy for Lambdas that write tokens.

API surface:
- `backend/lambda/api/login/index.js`
- `backend/lambda/api/register/index.js`
- `backend/lambda/api/sos/index.js`
- `backend/lambda/api/save_incident/index.js`
- `backend/lambda/api/get_guardians/index.js`
- `backend/lambda/api/update_live_location/index.js`
- `backend/lambda/api/push_notification/index.js`
- `backend/lambda/api/ai_request/index.js`

Schema guide:
- `backend/dynamodb_schema.md`

Deployment note:
- Prefer AWS SAM or CloudFormation to deploy the lambdas, API Gateway routes, DynamoDB tables, and SNS topic.

See `lambda/` for function examples and `infra/` for IaC templates (add Terraform/CloudFormation as needed).
