# Google Maps API Setup Instructions

## Free Tier Usage
Google Maps Platform offers $200 free credit per month, which is more than enough for this app's usage pattern with optimized location updates.

## Step 1: Get Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - (Optional) **Geocoding API** for address lookups
4. Go to **Credentials** > **Create Credentials** > **API Key**
5. Copy your API key

## Step 2: Restrict Your API Key (Important for Free Tier)

### For Android:
1. Click on your API key
2. Under **Application restrictions**, select **Android apps**
3. Add your package name: `com.alrida.al_rida_app`
4. Get your SHA-1 certificate fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
5. Add the SHA-1 fingerprint

### For iOS:
1. Create a separate API key for iOS
2. Under **Application restrictions**, select **iOS apps**
3. Add your bundle identifier (from `ios/Runner.xcodeproj`)

## Step 3: Add API Keys to Your App

### Android:
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your Android API key

### iOS:
1. Open `ios/Runner/Info.plist`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your iOS API key

## Step 4: API Usage Restrictions (Keep it FREE)

In Google Cloud Console, for each API key:
1. Go to **API restrictions**
2. Select **Restrict key**
3. Only enable:
   - Maps SDK for Android
   - Maps SDK for iOS
4. This prevents unauthorized usage

## Optimization for Free Tier

The app is configured to minimize API calls:
- Location updates are throttled (every 30 seconds minimum)
- Map loads only when viewing driver location
- No real-time continuous tracking for students (manual refresh)
- Cached location data to reduce Firestore reads

## Monitoring Usage

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Dashboard**
3. Monitor your usage to ensure you stay within free tier

## Expected Monthly Usage (Estimate)
- **Active Drivers**: 10-20
- **Location Updates**: ~30 per hour per driver = ~14,400 updates/month
- **Map Loads**: Student views (~5 times/day) = ~3,000 views/month
- **Total Cost**: Well within $200 free credit

## Security Best Practices
✅ API keys restricted by app package/bundle
✅ API restrictions enabled
✅ Usage quotas monitored
✅ Keys not committed to public repositories (use environment variables in production)
