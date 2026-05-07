# SafeAssist (shadowtrace)

Kotlin Android implementation of an intelligent monitoring and smart assistant system focused on personal safety.

## Implemented core features
- Trip start/stop flow with foreground monitoring service
- Trusted contacts add/remove with local persistence
- Continuous location tracking + stall detection
- Automatic escalation to emergency SMS alerts
- Manual SOS trigger
- Voice phrase trigger for emergency actions

## Tech choices
- Kotlin + Jetpack Compose
- Android foreground service + Fused Location Provider
- SharedPreferences (JSON) for local persistence

## Build
```bash
./gradlew test
./gradlew assembleDebug
```

## Notes
- Runtime permissions are requested in app startup.
- IMEI-based tracking is intentionally not implemented due to modern Android privacy/security restrictions.
