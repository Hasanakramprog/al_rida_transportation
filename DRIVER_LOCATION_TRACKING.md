# Driver Location Tracking Feature

## Overview
Real-time driver location sharing feature allowing drivers to share their location with students using Google Maps API (free tier optimized).

## Features

### For Drivers
- **Toggle Location Sharing** - Simple switch in Driver Dashboard to start/stop sharing location
- **Automatic Updates** - Location updates every 30 seconds (optimized for battery life and free tier)
- **Movement Threshold** - Only updates when driver moves 10+ meters (reduces API calls)
- **Background Support** - Continues tracking with proper permissions
- **Auto-Stop on Logout** - Location sharing stops automatically when driver logs out

### For Students
- **Track Driver Button** - One-click access to driver's real-time location
- **Google Maps View** - Interactive map showing driver's current position
- **Manual Refresh** - Students manually refresh to see updates (reduces Firestore reads)
- **Status Indicators** - Shows if driver is online, last update time
- **Stale Location Detection** - Alerts if location is more than 5 minutes old
- **Zone-Based Assignment** - Automatically finds driver for student's zone

## Technical Implementation

### Firestore Optimization
```dart
// Throttled updates (30-second minimum interval)
// Atomic location updates to driver profile
await _firestore.collection('drivers').doc(driverId).update({
  'location': driverLocation.toMap(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Battery Optimization
- **Distance Filter**: Only tracks when moving 10+ meters
- **Time Throttling**: Maximum one update every 30 seconds
- **GPS Accuracy**: High accuracy only when needed
- **Smart Caching**: Students see cached data with manual refresh

### Free Tier Usage
- **Estimated Monthly API Calls**: ~14,400 location updates per driver
- **Map Loads**: ~3,000 student views per month
- **Cost**: Well within Google's $200 free credit
- **API Restrictions**: Locked to Android/iOS app bundles

## Setup Instructions

### 1. Get Google Maps API Key
See [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) for detailed instructions.

### 2. Add API Keys

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>GMSApiKey</key>
<string>YOUR_IOS_API_KEY</string>
```

### 3. Permissions Already Configured
- ✅ Android location permissions added
- ✅ iOS location usage descriptions added
- ✅ Background location support enabled

### 4. Test the Feature

**As Driver:**
1. Login as driver
2. Go to Driver Dashboard
3. Toggle "Location Sharing" switch ON
4. Grant location permissions when prompted
5. Location updates every 30 seconds

**As Student:**
1. Login as student
2. Go to Student Dashboard
3. Click "Track Driver" button
4. View driver's location on map
5. Use refresh button to update location

## File Structure

```
lib/
├── models/
│   └── driver.dart                    # Added DriverLocation model
├── services/
│   └── location_service.dart          # NEW: Location tracking service
├── screens/
│   ├── home/
│   │   ├── driver_home.dart          # Added location sharing toggle
│   │   └── student_home.dart         # Added track driver button
│   └── student/
│       └── driver_location_screen.dart # NEW: Map view screen
└── ...
```

## Architecture Patterns Used

### State Management
- **StatefulWidget with Caching** - Location data cached locally
- **Manual Refresh** - No real-time streams for students (minimize reads)
- **Optimistic Updates** - UI updates immediately, syncs in background

### Firestore Updates
- **Atomic Writes** - Location updates use direct field updates
- **Throttled Writes** - 30-second minimum interval
- **Conditional Updates** - Only write if moved significantly

### Error Handling
```dart
// Graceful error handling with user feedback
try {
  await _locationService.startLocationSharing(driverId);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

## Cost Monitoring

Monitor your Google Maps API usage:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Dashboard**
3. View usage metrics for:
   - Maps SDK for Android
   - Maps SDK for iOS

## Security Considerations

✅ API keys restricted by app package/bundle IDs  
✅ Firestore security rules apply to location data  
✅ Location only visible when driver explicitly shares  
✅ Auto-stop on logout prevents stale tracking  
✅ No permanent location history stored

## Performance Metrics

- **Location Update Frequency**: Every 30 seconds
- **Battery Impact**: Minimal (high accuracy only when moving)
- **Network Usage**: ~1KB per location update
- **Firestore Reads**: 1 read per manual student refresh
- **Firestore Writes**: Max 120 writes/hour per driver (2/minute)

## Future Enhancements

- [ ] Route history for completed trips
- [ ] ETA calculations to student pickup points
- [ ] Push notifications when driver is nearby
- [ ] Geofencing for automatic zone detection
- [ ] Trip recording and replay

## Troubleshooting

### "Location permission denied"
- Check app has location permissions in device settings
- Request background location permission (Android 10+)

### "Location not updating"
- Ensure GPS is enabled on driver's device
- Check if driver has toggled location sharing ON
- Verify internet connection

### "Map not loading"
- Verify Google Maps API key is correct
- Check API key restrictions in Google Cloud Console
- Ensure Maps SDK for Android/iOS is enabled

### "Driver not found"
- Verify student and driver are in same zone
- Check driver profile exists in Firestore
- Ensure driver is marked as active

## Dependencies

```yaml
dependencies:
  geolocator: ^13.0.2         # Location tracking
  google_maps_flutter: ^2.10.0 # Map display
  permission_handler: ^11.3.1  # Permission management
```

## Related Documentation

- [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) - API key setup
- [DATABASE_SETUP.md](DATABASE_SETUP.md) - Firestore configuration
- [.github/copilot-instructions.md](.github/copilot-instructions.md) - Project patterns
