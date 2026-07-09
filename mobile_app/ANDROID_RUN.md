# PAN LATE PYAR Android Run Guide

## Current Backend URL

The app reads its PHP API base URL from:

`lib/constants/api_config.dart`

Default emulator URL:

```text
http://10.0.2.2/stationery-shop-project/backend/api
```

For a physical Android phone, replace `10.0.2.2` with your Windows computer's
local IPv4 address, for example:

> Run the command from the Flutter project folder, not from the parent project root.

```powershell
cd E:\XAMPP\htdocs\stationery-shop-project\mobile_app
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2/stationery-shop-project/backend/api
```

## Required Android Setup

Flutter is installed, but this Windows machine still needs the Android SDK.

1. Install Android Studio.
2. Open Android Studio once.
3. Install:
   - Android SDK Platform
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Emulator, optional
4. Run:

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

## Run On A Physical Phone

1. Enable Developer Options on your Android phone.
2. Enable USB debugging.
3. Connect the phone by USB.
4. Accept the USB debugging prompt on the phone.
5. From `mobile_app`, run:

```powershell
cd E:\XAMPP\htdocs\stationery-shop-project\mobile_app
flutter devices
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IPV4/stationery-shop-project/backend/api
```

## Build A Debug APK

From `mobile_app`, run:

```powershell
cd E:\XAMPP\htdocs\stationery-shop-project\mobile_app
flutter build apk --debug --dart-define=API_BASE_URL=http://YOUR_PC_IPV4/stationery-shop-project/backend/api
```

If Android Studio or Gradle reports `There is not enough space on the disk`, free up space on the C: drive or redirect Gradle/temp files to a drive that has room, for example:

```powershell
$env:GRADLE_USER_HOME='E:\.gradle'
$env:TEMP='E:\temp'
$env:TMP='E:\temp'
```

The APK will be created at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```
