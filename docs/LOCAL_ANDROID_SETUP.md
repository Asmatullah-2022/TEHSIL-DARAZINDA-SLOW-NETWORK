# Local Android Setup — Windows (Beginner Guide)

This guide is for **your own Windows computer**, not for this cloud
session. The environment Claude runs in is a temporary Linux
container — it has Flutter, but no Android SDK and no phone, and it
cannot install anything on your computer. Everything below happens on
your machine, step by step.

Total time: 45–90 minutes, mostly waiting for downloads/installs.

---

## 1. Install Flutter

1. Go to https://docs.flutter.dev/get-started/install/windows
2. Download the Flutter SDK zip (the page always links the latest
   stable release).
3. Extract it somewhere with **no spaces or special characters** in
   the path, e.g. `C:\src\flutter` (do **not** extract into
   `C:\Program Files\`, permissions there cause problems).
4. That's it for this step — don't run anything yet.

## 2. Install Android Studio

1. Download from https://developer.android.com/studio
2. Run the installer, keep all default options.
3. On first launch, it opens a "Setup Wizard" — choose **Standard**
   installation. This automatically installs the Android SDK,
   Android SDK Platform-Tools, and an emulator image for you (this
   covers steps 3 and 4 below).
4. Let it finish downloading — this is the slow part (a few GB).

## 3. Install Android SDK (if not done automatically)

If step 2's wizard already installed the SDK, skip this.

Otherwise, inside Android Studio: **More Actions → SDK Manager**
(or **File → Settings → Languages & Frameworks → Android SDK**).
- **SDK Platforms** tab: check the latest Android version (e.g.
  "Android 14.0 (UpsideDownCake)").
- **SDK Tools** tab: check **Android SDK Build-Tools**,
  **Android SDK Command-line Tools (latest)**, and
  **Android SDK Platform-Tools**.
- Click **Apply** and let it install.

## 4. Install Android SDK Platform-Tools

This is `adb` (the tool that talks to your phone). It's included in
step 3's "SDK Tools" list above — if you checked
**Android SDK Platform-Tools**, you already have it. No separate
action needed.

## 5. Configure environment variables

1. Find your Android SDK path. In Android Studio: **File → Settings
   → Languages & Frameworks → Android SDK** — the path is shown at
   the top (usually `C:\Users\<you>\AppData\Local\Android\Sdk`).
2. Open Windows Settings → search "environment variables" → **Edit
   the system environment variables** → **Environment Variables...**
3. Under **User variables**, click **New...** and add:
   - Variable name: `ANDROID_HOME`
   - Variable value: the path from step 1
4. Edit the `Path` variable (User variables) → **New** → add:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
5. Also add Flutter to `Path`: `New` → the `bin` folder inside where
   you extracted Flutter, e.g. `C:\src\flutter\bin`
6. Click OK on every dialog, then **close and reopen** any terminal
   windows (PowerShell/Command Prompt) so they pick up the change.
7. Verify: open a new PowerShell window and run:
   ```powershell
   flutter --version
   adb --version
   ```
   Both should print version info, not "command not found".

## 6. Accept Android licenses

In PowerShell:
```powershell
flutter doctor --android-licenses
```
Press `y` and Enter for each license prompt (there are several).

## 7. Configure an emulator (optional, for testing without a phone)

1. In Android Studio: **More Actions → Virtual Device Manager**
   → **Create Device**.
2. Pick a phone (e.g. Pixel 7) → Next → pick a system image (e.g.
   the latest one you downloaded in step 3, marked "Recommended") →
   Next → Finish.
3. Click the ▶ (play) icon next to the device to boot it.

You can skip this entirely and use a real phone instead (recommended
for Darazinda Connect, since it needs real cellular signal — an
emulator has no SIM and reports fake/no telephony data).

## 8. Connect a physical Android phone

A real phone is **strongly preferred** for this app specifically,
because the whole point is reading real signal strength/operator data
from a real SIM — an emulator cannot provide that.

1. Plug the phone into your PC with a USB cable that supports data
   transfer (some cheap cables are charge-only).
2. On first connection, your phone may show a popup asking to allow
   USB debugging from this computer — you'll approve this after step
   10 below (enabling Developer Options/USB debugging comes first).

## 9. Enable Developer Options on the phone

1. Phone Settings → **About phone**.
2. Find **Build number** (sometimes under "Software information").
3. Tap it **7 times** quickly. You'll see "You are now a developer!"
4. Go back to Settings — a new **Developer options** menu now appears
   (usually under "System" or at the bottom of the main Settings
   list).

## 10. Enable USB debugging

1. Settings → **Developer options**.
2. Turn on **USB debugging**.
3. Reconnect the USB cable if needed. A popup appears on the phone:
   **"Allow USB debugging?"** — check "Always allow from this
   computer" and tap **Allow**.

## 11. Verify the device is detected

In PowerShell, from anywhere:
```powershell
flutter devices
```
You should see your phone listed with a device ID, e.g.:
```
Pixel 7 (mobile) • ABCD1234 • android-arm64 • Android 14 (API 34)
```
If it says "No devices detected", check: USB debugging is on, the
cable supports data, and you tapped "Allow" on the phone's popup.

## 12. Run flutter doctor

```powershell
flutter doctor
```
Every line should show `[✓]`. If Android toolchain still shows `[✗]`,
re-check step 5 (`ANDROID_HOME`) and step 6 (licenses). Chrome/Visual
Studio warnings are fine to ignore — this project doesn't need web or
Windows desktop builds.

---

## Now run Darazinda Connect

From the project folder (where you cloned/downloaded this repo):
```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```
`flutter run` with your phone connected and unlocked will install and
launch the app on it directly.

If anything in this list doesn't work exactly as described, that's
useful — tell me the exact command and the exact error text, and we'll
fix it together rather than guessing.
