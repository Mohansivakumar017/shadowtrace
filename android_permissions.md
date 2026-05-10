Android permissions and manifest entries to add for ShadowTrace:

Add the following permissions to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FLASHLIGHT" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

Also add the following inside the `<application>` tag to support Firebase messaging full-screen intents and background services:

<service android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false" />

Follow the Firebase Android setup steps and place `google-services.json` in `android/app/`.
