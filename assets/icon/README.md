# App Icon Setup Instructions

## Steps to Add Your App Icon:

1. **Prepare your icon image:**
   - Create or obtain a 1024x1024 PNG image for your app icon
   - The icon should represent "Al Rida Transportation" (e.g., a bus, transport vehicle, or company logo)
   - Save it as `app_icon.png` in this folder (`assets/icon/`)

2. **For Android Adaptive Icon (optional but recommended):**
   - Create a foreground image: `app_icon_foreground.png` (1024x1024 PNG)
   - This should be your logo/icon with transparent background
   - The background color is set to `#2196F3` (blue) in pubspec.yaml

3. **Install the package and generate icons:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Clean and rebuild your app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Current Configuration:

- **App Name:** Al Rida Transportation
- **Icon Path:** assets/icon/app_icon.png
- **Adaptive Icon Background:** #2196F3 (Material Blue)
- **Adaptive Icon Foreground:** assets/icon/app_icon_foreground.png

## Icon Specifications:

- **Main Icon:** 1024x1024 px, PNG format
- **Foreground (Adaptive):** 1024x1024 px, PNG with transparency
- **Recommended safe area:** Center 66% of the icon (to avoid clipping on some devices)

## Quick Icon Creation Tips:

If you don't have an icon yet, you can:
1. Use a design tool like Canva, Figma, or Adobe Illustrator
2. Include elements like:
   - A bus or vehicle icon
   - The company initials "AR" or "ART"
   - Transportation-related symbols
3. Use your brand colors (e.g., blue #2196F3)
4. Ensure good contrast and visibility at small sizes

## After Adding Your Icon:

Once you've placed your icon files in this folder, run:
```bash
flutter pub run flutter_launcher_icons
```

This will automatically generate all the required icon sizes for Android and iOS.
