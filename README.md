# **Koshik: Smart Hisāb**

> **Your personal expense tracker that works automatically — from your SMS inbox.**
> Koshik reads your bank or wallet transaction messages (securely and privately on your device), extracts spending and income details, and organizes them for easy tracking.
> You can view daily, weekly, and monthly statistics, get notified for new transactions, and even pause background scanning anytime from settings.
> All your data stays **encrypted and local** — nothing ever leaves your phone.

---

## 📱 Overview

**Koshik: Smart Hisāb** is a Flutter-based expense tracking app that automatically parses SMS messages to extract transaction details and stores them securely on your device.

This version includes:

-   🔒 Encrypted Hive storage for transactions
-   ⚙️ Background SMS processing with isolate entrypoint
-   🔔 Local notifications for new transactions
-   🧭 Settings toggle to enable/disable background service
-   📊 Statistics screen with "Delete all data" option

---

## 🚀 Quick Links

-   **Prompt reference:** [`PROMPT_REFERENCE.md`](PROMPT_REFERENCE.md) — how AI was used to build and iterate this project
-   **Main screens:**
    -   `lib/screens/home_screen.dart`
    -   `lib/screens/stats_screen.dart`
    -   `lib/screens/settings_screen.dart`
-   **DB helper:** `lib/db/hive_helper.dart`
-   **Notification service:** `lib/services/notification_service.dart`
-   **SMS/background service:**
    -   `lib/services/background_service.dart`
    -   `lib/services/sms_service.dart`

---

## 🧩 Requirements

-   Flutter SDK (stable channel)
-   Android SDK & toolchain (for Android builds)
-   Device/emulator with SMS support (for end-to-end testing)
-   Recommended Java: **OpenJDK 11+** (project targets Java 11 with desugaring enabled)

---

## ⚙️ Setup

1. **Install dependencies**

    ```bash
    flutter pub get
    ```

2. **Android prerequisites**

    - Ensure your `local.properties` points to the Android SDK:
        ```properties
        sdk.dir=/path/to/Android/Sdk
        ```
    - For release builds, configure app signing as per Flutter’s [official documentation](https://docs.flutter.dev/deployment/android#signing-the-app).

3. **Run the app (debug)**

    ```bash
    flutter run
    ```

4. **Build release APK**
    ```bash
    flutter build apk --release
    ```

> Gradle is configured for **core library desugaring** and includes
> `com.android.tools:desugar_jdk_libs:2.1.4` for compatibility with certain plugins like `flutter_local_notifications`.

---

## 🧪 Manual Testing Checklist

1. Launch app on an SMS-capable device/emulator.
2. Grant **SMS** and **notification** permissions when prompted.
3. Ensure background-service toggle is ON (Settings).
4. Send/receive a transaction SMS or use “Scan inbox” on Home screen.
5. Verify that:
    - A local notification appears for the parsed transaction.
    - Tapping the notification opens the app and shows transaction details.
6. Go to **Stats → Delete all data**, confirm deletion.
7. Turn OFF background-service and verify new SMS are not parsed.

---

## 🧠 Developer Notes

-   Avoid using `BuildContext` across async gaps; cache `ScaffoldMessenger`/`Navigator` where necessary.
-   The Hive encryption key is managed via `flutter_secure_storage` — see `lib/db/hive_helper.dart`.
-   After dependency updates, always run:
    ```bash
    flutter analyze
    flutter build apk -v
    ```

---

## 🧰 Build Troubleshooting

If you encounter Gradle AAR metadata issues (e.g., with `flutter_local_notifications`), ensure `android/app/build.gradle.kts`:

-   Enables **core library desugaring** under `compileOptions`
-   Adds:
    ```kotlin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    ```

---

## 🤝 Contributing

Want to enhance Koshik? (e.g., add new SMS parsers, backups, or analytics)
Open an issue or submit a PR with:

-   `flutter analyze` results
-   Reproducible steps

---

## 🙏 Acknowledgements

Built with **AI-assisted development** and thoughtful iteration.
See [`PROMPT_REFERENCE.md`](PROMPT_REFERENCE.md) for the complete prompt history.
