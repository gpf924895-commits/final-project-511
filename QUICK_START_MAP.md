# 🚀 Quick Start: Enable Interactive Map

## Your app already has the interactive map! Just add your API key.

---

## ⚡ 3 Simple Steps

### 1️⃣ Get Google Maps API Key

1. Go to: https://console.cloud.google.com/
2. Create a project (or use existing)
3. Go to: **APIs & Services** → **Credentials** → **+ CREATE CREDENTIALS** → **API key**
4. Copy your key (starts with `AIzaSy...`)

### 2️⃣ Enable Required APIs

In Google Cloud Console, go to **APIs & Services** → **Library** and enable:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS  
- ✅ Geocoding API
- ✅ Directions API

### 3️⃣ Add API Key to Your App

#### For Android:
Open: `android/app/src/main/AndroidManifest.xml`

**Find line 41** (currently):
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

**Replace with:**
```xml
android:value="AIzaSyYOUR_ACTUAL_KEY_HERE" />
```

#### For iOS:
Open: `ios/Runner/AppDelegate.swift`

**Find line 12** (currently):
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

**Replace with:**
```swift
GMSServices.provideAPIKey("AIzaSyYOUR_ACTUAL_KEY_HERE")
```

---

## 🔄 Rebuild & Test

```bash
flutter clean
flutter pub get
flutter run
```

**Test on a physical device** (GPS doesn't work well on emulators)

---

## ✨ What You'll Get

Once configured, your users can:

### 📍 Interactive Map Features:
- **Zoom, pan, rotate, tilt** the map
- **Tap markers** to see location details
- **View sacred places**: Raudah, Prophet's grave, Abu Bakr, Umar graves
- **Find entrances**: Main gate, King Fahd gate, Bab as-Salam
- **Locate facilities**: Library, Hospital

### 🧭 Navigation Features:
- **Current location** tracking with GPS
- **Distance calculation** to any point
- **Route visualization** with polylines
- **Turn-by-turn directions** via Google Maps app
- **Location name** display (city, country)

### 🎨 UI Features:
- **Color-coded markers**: Red (sacred), Green (entrances), Blue (facilities)
- **Interactive legend**
- **Quick action buttons**: My Location, Focus on Mosque, Open in Google Maps
- **Location info panel** at bottom
- **Permission handling** with user-friendly dialogs

---

## 🆓 Free Tier

Google Maps API includes **$200/month free credit** which covers:
- ~28,000 map loads per month
- ~40,000 direction requests per month
- ~40,000 geocoding requests per month

For most apps, you'll stay within the free tier.

---

## ⚠️ Common Issues

### Blank/Gray Map?
- ❌ API key not added correctly
- ✅ Double-check both files have the same API key
- ✅ Make sure APIs are enabled in Cloud Console

### Map Loads But Location Doesn't Work?
- ✅ Grant location permissions when app asks
- ✅ Enable GPS on device
- ✅ Test on physical device (not emulator)

### Build Error After Changes?
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

---

## 📱 Current Implementation

Your app already has a **complete mosque map page** at:
- `lib/screens/mosque_map_page.dart` - Full map implementation
- `lib/widgets/mosque_map_preview.dart` - Home page preview widget
- `lib/provider/location_provider.dart` - Location management

The map includes:
- 9 pre-configured locations within the Prophet's Mosque
- GPS integration for user location
- Polyline routing between points
- Marker clustering by type
- Distance calculations
- Arabic language support
- Full permission handling
- Error handling and user feedback

**You just need to add the API key!**

---

## 📋 Checklist

- [ ] Get API key from Google Cloud Console
- [ ] Enable: Maps SDK for Android
- [ ] Enable: Maps SDK for iOS
- [ ] Enable: Geocoding API
- [ ] Enable: Directions API
- [ ] Update `android/app/src/main/AndroidManifest.xml` (line 41)
- [ ] Update `ios/Runner/AppDelegate.swift` (line 12)
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Test on physical device
- [ ] Grant location permissions when prompted
- [ ] Verify map loads and shows markers
- [ ] Test navigation to a marker
- [ ] Test external Google Maps link

---

**That's it! Your interactive map will be fully functional.** 🎉

