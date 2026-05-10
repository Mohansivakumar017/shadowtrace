iOS permission entries to add to `ios/Runner/Info.plist`:

<key>NSLocationWhenInUseUsageDescription</key>
<string>Allow location access to enable live tracking and emergency services.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Allow background location tracking for emergency features.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Needed for voice assistant and voice activation.</string>
<key>NSCameraUsageDescription</key>
<string>Needed for evidence capture and fake call features.</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>audio</string>
  <string>fetch</string>
</array>

Also configure push notifications and add the appropriate capabilities in Xcode.
