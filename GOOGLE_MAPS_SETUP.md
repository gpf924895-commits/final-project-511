# Google Maps Setup Guide

## Required Setup for Mosque Map Feature

To enable the interactive mosque map with GPS navigation, you need to set up Google Maps API keys for both Android and iOS platforms.

### 1. Get Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
   - **Directions API**

### 2. Configure Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### 3. Configure iOS

1. Open `ios/Runner/AppDelegate.swift`
2. Add the following import at the top:
```swift
import GoogleMaps
```

3. Add the following line in the `application` function:
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### 4. API Key Restrictions (Recommended)

For security, restrict your API key:

1. **Android**: Restrict by package name and SHA-1 fingerprint
2. **iOS**: Restrict by bundle identifier
3. **Server**: Restrict by IP address if needed

### 5. Test the Implementation

After setting up the API keys:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Build and test on a physical device (GPS doesn't work on simulators)

### Features Included

✅ **Interactive Mosque Map**
- Real-time GPS location tracking
- Sacred places markers (Raudah, Prophet's grave, etc.)
- Entrance and facility markers
- Distance calculations

✅ **Navigation Features**
- Turn-by-turn directions via Google Maps
- Route visualization on the map
- Current location display

✅ **User-Friendly Interface**
- Arabic language support
- Legend for different location types
- Permission handling
- Error handling and user feedback

### Important Notes

- **Location Permissions**: The app will request location permissions on first use
- **Physical Device Required**: GPS features require a physical device with location services enabled
- **Internet Connection**: Required for map tiles and navigation features
- **API Quotas**: Monitor your Google Maps API usage to avoid unexpected charges

### Troubleshooting

1. **Map not loading**: Check API key configuration
2. **Location not found**: Ensure location permissions are granted
3. **Navigation not working**: Verify Directions API is enabled
4. **Build errors**: Run `flutter clean` and `flutter pub get`

### Cost Considerations

- Google Maps API has usage limits and charges
- Consider implementing caching for frequently accessed locations
- Monitor usage in Google Cloud Console
