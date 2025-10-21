# SMS Transaction

A Flutter app that parses SMS messages to extract transaction details and stores them locally.

This fork includes:
- Encrypted Hive storage for transactions.
- Background SMS processing with an isolate entrypoint.
- Local notifications when a transaction is detected.
- Settings toggle to enable/disable background processing.
- A Statistics screen with a "Delete all data" option.

## Quick links
- Prompt reference: `PROMPT_REFERENCE.md` (how AI was used to build and iterate this project)
- Main screens: `lib/screens/home_screen.dart`, `lib/screens/stats_screen.dart`, `lib/screens/settings_screen.dart`
- DB helper: `lib/db/hive_helper.dart`
- Notification service: `lib/services/notification_service.dart`
- SMS/background service: `lib/services/background_service.dart` or `lib/services/sms_service.dart`

---

## Requirements
- Flutter SDK (stable channel)
- Android SDK & toolchain (for Android builds)
- A device or emulator with SMS support (for end-to-end testing)

Recommended Java: OpenJDK 11+ (the project uses Java 11 compatibility and core-library desugaring where needed)

---

## Setup

1. Install dependencies

```bash
flutter pub get
```

2. Android prerequisites

- Ensure your `local.properties` points to Android SDK: `sdk.dir=/path/to/Android/Sdk`
- If you build release APKs, make sure you have signing config in `android/app` or follow Flutter documentation to sign your app.

3. Run the app (debug)

```bash
flutter run
```

4. Build release APK

```bash
flutter build apk --release
```

The repository includes Gradle changes enabling core library desugaring and a dependency on `com.android.tools:desugar_jdk_libs:2.1.4` to satisfy Android AAR metadata checks for some plugins (e.g., `flutter_local_notifications`).

---

## Testing & QA checklist (manual)

1. Launch the app on a device/emulator with SMS capability.
2. Grant SMS and notification permissions when prompted.
3. In Settings, ensure the background-service toggle is set to ON.
4. Send or receive an SMS that matches the app's transaction parsing rules (or use the "Scan inbox" action in Home screen to parse existing messages).
5. Confirm a local notification appears when a transaction is parsed.
6. Tap the notification: the app should open and (if implemented) navigate to the parsed transaction details.
7. Open Stats and use "Delete all data" — confirm it clears stored transactions after confirmation.
8. Toggle the background-service OFF and verify that new incoming SMSes are not parsed in the background.

---

## Notes for developers

- Avoid using `BuildContext` across async gaps; cache `ScaffoldMessenger`/`Navigator` and check `mounted` before calling setState or showing snack bars.
- The encryption key for Hive is stored with `flutter_secure_storage` — review `lib/db/hive_helper.dart` for implementation details.
- If you update dependencies, re-run `flutter analyze` and `flutter build apk -v` to catch issues early.

---

## Repro steps for the build failure that was fixed

If you encounter Gradle AAR metadata failures similar to earlier problems with `flutter_local_notifications`, ensure your `android/app/build.gradle.kts`:
- enables core library desugaring (compile options) and
- adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` (or newer) in the dependencies block.

---

## Contributing

If you want to extend this project (add new parsers, sync/backups, or automated tests), please open an issue or submit a PR. Include `flutter analyze` output and reproducible steps.

---

## Acknowledgements

Built with AI-assisted development and tooling. See `PROMPT_REFERENCE.md` for the prompt history and iteration details.
