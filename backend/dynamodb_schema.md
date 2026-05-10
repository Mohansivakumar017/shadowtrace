# DynamoDB Schema

## Users
- `userId` (PK, S)
- `email` (S)
- `phone` (S)
- `role` (S)
- `createdAt` (S)

## Guardians
- `guardianId` (PK, S)
- `userId` (GSI, S)
- `name` (S)
- `phone` (S)
- `relationship` (S)

## Incidents
- `incidentId` (PK, S)
- `userId` (GSI, S)
- `type` (S)
- `status` (S)
- `location` (M)
- `createdAt` (S)

## LiveTracking
- `deviceId` (PK, S)
- `userId` (GSI, S)
- `position` (M)
- `updatedAt` (S)

## EmergencyLogs
- `logId` (PK, S)
- `userId` (GSI, S)
- `eventType` (S)
- `payload` (M)
- `createdAt` (S)

## Notifications
- `notificationId` (PK, S)
- `userId` (GSI, S)
- `title` (S)
- `body` (S)
- `read` (BOOL)
- `createdAt` (S)

## Routes
- `routeId` (PK, S)
- `userId` (GSI, S)
- `riskScore` (N)
- `path` (L)
- `createdAt` (S)

## DeviceTokens
- `token` (PK, S)
- `userId` (GSI, S)
- `createdAt` (S)
