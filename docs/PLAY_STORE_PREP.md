# Play Store Preparation — Darazinda Connect

## Application identity
- **Package name / application ID**: `pk.darazindaconnect.app`
  — verify availability on the Google Play Console before final
  publication (package names are globally unique and permanent once
  published).
- **App name**: Darazinda Connect
- **Subtitle**: Signal Mapping & Complaint App

## Short description (≤80 characters)
> Measure signal, map connectivity & report network problems in Darazinda.

## Full description (draft)

> Darazinda Connect helps residents of Darazinda Tehsil measure, map,
> and report mobile network problems — turning individual experiences
> into evidence that can drive real improvements.
>
> **What it does**
> • Test your real signal strength, download/upload speed, and latency
> • Record the exact GPS location of every measurement
> • See a live community map of connectivity across the Tehsil, color-
>   coded by signal quality
> • Identify areas with a probable, evidence-backed connectivity
>   problem (never based on a single test)
> • Compare mobile operators using real, crowdsourced measurements
> • Submit a detailed problem report — automatically attached with your
>   location, operator, and latest network readings
> • Generate a professional PDF evidence report for any submission
> • Works fully offline: everything you record is saved on your device
>   and synced automatically once you're back online
> • Available in English and Urdu
>
> **What it does NOT do**
> Darazinda Connect measures and reports network conditions. It cannot
> and does not boost, extend, or improve your cellular signal — no
> mobile app can. It also does not automatically file an official
> complaint with any telecom operator or government body; reports are
> community evidence that you can export and share yourself.
>
> **Your privacy**
> Darazinda Connect only requests the permissions it needs to measure
> and map connectivity: location (to record where a measurement was
> taken), phone state (to read your operator, network type, and signal
> strength — never your phone number or call history), network state,
> and camera (only if you choose to attach a photo to a report). We
> never collect your contacts, SMS, or call history, and we never track
> your location in the background.

## Permission disclosures (for the Play Console "Data safety" form)

| Permission | Why it's needed | Optional? |
|---|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Tag each measurement/report with the GPS coordinates it was taken at — the core evidence this app collects | No — required for the core feature |
| `READ_PHONE_STATE` | Read the current operator name, network generation (2G/3G/4G/5G), and signal strength | No — required for the core feature, but the app still functions (with those fields shown as "Not available") if denied |
| `INTERNET` / `ACCESS_NETWORK_STATE` | Run the download/upload/latency test and sync offline data when connectivity returns | No — the app can still record GPS + telephony data offline without it |
| `CAMERA` / `READ_MEDIA_IMAGES` | Attach an optional photo to a problem report | Yes — entirely optional |

No contacts, SMS, call log, microphone, or background-location
permissions are requested anywhere in the app.

## Privacy policy requirements
A hosted privacy policy is required by Google Play before publishing
any app that requests location and phone-state permissions. It must
cover, at minimum:
- What data is collected (GPS coordinates, operator/network/signal
  readings, optional report description/photo, optional email if the
  user registers an account).
- That anonymous/guest usage is supported and tags data with a random
  device identifier, not a hardware ID.
- That data is stored in Firebase (Google Cloud infrastructure) and
  used to build the public community connectivity map and statistics.
- How a user can request deletion of their data (in-app: Settings →
  Delete Account/Data for local data; contact
  `support@darazindaconnect.app` for deletion of already-synced data).
- That the app does not sell personal data to third parties.

A placeholder URL (`AppConstants.privacyPolicyUrl`) is wired into
Settings; replace it with the real published policy URL before
release.

## Screenshots (to produce before submission)
Minimum per Play Store requirements: 2 phone screenshots (16:9 or 9:16),
recommended 6-8 covering:
1. Onboarding — "Measure Your Network"
2. Dashboard with a completed measurement
3. Network Test results screen
4. Signal Map with colored pins + legend
5. Report Problem form
6. Probable Connectivity Problem list
7. PDF report preview
8. Urdu (RTL) version of the dashboard

## Feature graphic specification
1024×500 px, PNG or JPG, no transparency. Should show the app name,
tagline ("Measure • Map • Report • Improve Connectivity"), and a
stylized signal-map visual in the blue/cyan brand palette
(`AppColors.primaryBlue` `#0B5FA5` / `AppColors.accentCyan` `#00B8D9`).

## Release build configuration checklist
- [ ] Replace `android/app/build.gradle`'s `signingConfig
      signingConfigs.debug` with a real release keystore
      (`key.properties`, gitignored — see `.gitignore`).
- [ ] Run `flutterfire configure` against the real production Firebase
      project; confirm `firebase_options.dart` and
      `android/app/google-services.json` contain real values (not the
      `REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT` placeholders
      currently committed).
- [ ] Bump `version` in `pubspec.yaml` (`versionName+versionCode`).
- [ ] Confirm `minifyEnabled true` / `shrinkResources true` (already
      set) don't strip anything needed by reflection-based plugins —
      run a release build and smoke-test before submitting.
- [ ] Verify the `pk.darazindaconnect.app` application ID is available
      / owned on the Play Console.
- [ ] Publish the privacy policy and paste its final URL into
      `AppConstants.privacyPolicyUrl` and the Play Console listing.
- [ ] Complete the Play Console "Data safety" section using the table
      above.
- [ ] Set the content rating questionnaire (civic-utility app — no
      user-generated content moderation concerns beyond the optional
      report photo/description, which should be disclosed).
