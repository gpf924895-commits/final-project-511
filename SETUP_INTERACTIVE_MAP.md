# Interactive Map Setup Guide

## 🗺️ Current Status

Your app **already has a fully functional interactive map** implemented! However, it won't display without a valid Google Maps API key.

### What's Already Working:
✅ Interactive map with zoom, pan, rotate, and tilt
✅ Multiple markers showing sacred places, entrances, and facilities
✅ GPS location tracking
✅ Navigation routes with polylines
✅ Distance calculations
✅ Legend and location details
✅ External Google Maps integration

### What's Missing:
❌ Google Maps API Key configuration

---

## 🔑 How to Set Up Google Maps API Key

### Step 1: Get Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Go to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **API key**
5. Copy the generated API key

### Step 2: Enable Required APIs

In Google Cloud Console, enable these APIs:
1. **Maps SDK for Android** ✅
2. **Maps SDK for iOS** ✅
3. **Geocoding API** ✅
4. **Directions API** ✅

To enable:
- Go to **APIs & Services** → **Library**
- Search for each API and click **ENABLE**

### Step 3: Configure Android

Open `android/app/src/main/AndroidManifest.xml` and replace:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

With your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD..." />
```

### Step 4: Configure iOS

1. Open `ios/Runner/AppDelegate.swift`
2. Add this import at the top:
```swift
import GoogleMaps
```

3. Add this line in the `application` function, before the `return` statement:
```swift
GMSServices.provideAPIKey("AIzaSyD...")
```

Your AppDelegate.swift should look like:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD...")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 5: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔒 Security Best Practices

### Restrict Your API Key

For production, restrict your API key to prevent unauthorized use:

1. In Google Cloud Console, go to **APIs & Services** → **Credentials**
2. Click on your API key
3. Under **Application restrictions**, select:
   - **Android apps**: Add your package name and SHA-1 fingerprint
   - **iOS apps**: Add your bundle identifier

To get your Android SHA-1:
```bash
cd android
./gradlew signingReport
```

### Monitor Usage

- Check your API usage in [Google Cloud Console](https://console.cloud.google.com/apis/dashboard)
- Set up billing alerts to avoid unexpected charges
- Google Maps API has a free tier ($200 monthly credit)

---

## 📱 Features Available After Setup

Once configured, your users can:

1. **View Interactive Map**
   - See the Prophet's Mosque with all important locations
   - Sacred places (Raudah, Prophet's grave, Abu Bakr, Umar)
   - Entrances (Main gate, King Fahd gate, Bab as-Salam)
   - Facilities (Library, Hospital)

2. **Navigate**
   - Tap any marker to see details
   - Get directions from current location
   - View routes on the map
   - Open in Google Maps for turn-by-turn navigation

3. **Track Location**
   - View current GPS location
   - Calculate distance to any point
   - See location name (city, country)

---

## 🐛 Troubleshooting

### Map Shows Blank/Gray Screen
- **Issue**: API key not configured or invalid
- **Solution**: Verify API key in both AndroidManifest.xml and AppDelegate.swift
- **Check**: Ensure Maps SDK for Android/iOS is enabled in Google Cloud Console

### "Location Permission Denied"
- **Issue**: User hasn't granted location permissions
- **Solution**: The app will show a dialog to request permissions
- **Manual**: Go to Settings → App → Permissions → Location → Allow

### Location Not Found
- **Issue**: GPS disabled or no signal
- **Solution**: Enable location services in device settings
- **Note**: Test on a physical device (emulators have limited GPS)

### "Can't Open Maps"
- **Issue**: Google Maps app not installed
- **Solution**: The app will open in browser if Maps app isn't available

### Build Errors After Adding Key
- **Solution**: 
  ```bash
  flutter clean
  rm -rf build/
  flutter pub get
  flutter run
  ```

---

## 💰 Cost Considerations

Google Maps API pricing:
- **Free tier**: $200 monthly credit (enough for ~28,000 map loads)
- **Map loads**: $7 per 1,000 loads after free tier
- **Directions**: $5 per 1,000 requests
- **Geocoding**: $5 per 1,000 requests

For a typical app with moderate usage, you'll likely stay within the free tier.

---

## 🎯 Next Steps

1. ✅ Get Google Maps API key from Cloud Console
2. ✅ Enable required APIs (Maps SDK, Geocoding, Directions)
3. ✅ Add API key to `android/app/src/main/AndroidManifest.xml`
4. ✅ Add API key to `ios/Runner/AppDelegate.swift`
5. ✅ Run `flutter clean && flutter pub get`
6. ✅ Test on a physical device
7. ✅ Restrict API key for production
8. ✅ Monitor usage in Cloud Console

---

## 📞 Need Help?

If you encounter any issues:
1. Check the [Google Maps Platform documentation](https://developers.google.com/maps/documentation)
2. Verify all APIs are enabled in Cloud Console
3. Check API key restrictions aren't blocking your app
4. Review the console logs for specific error messages

---

**Note**: The interactive map is already fully implemented in your app. You only need to configure the API key to make it visible!

