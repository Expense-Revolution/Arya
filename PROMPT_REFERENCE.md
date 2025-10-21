# Prompt Reference — SMS Transaction (Flutter)

> This file documents how the SMS Transaction Flutter project was created and iterated using AI-driven prompts and developer guidance. Use it to reproduce, extend, or audit the AI-assisted work.

---

## Project Overview

SMS Transaction is a Flutter mobile app that parses SMS messages to extract financial transactions and stores them locally. It includes:

- Background SMS detection (foreground + background isolate entrypoint).
- Local, encrypted storage using Hive with an encryption key persisted securely (flutter_secure_storage).
- Local notifications when a transaction is detected (flutter_local_notifications).
- Settings to enable/disable background SMS processing and request battery-optimization exemptions.
- A statistics screen with a "Delete all data" action.

Why it was created
- To automatically capture expense/payment records from incoming SMS messages and provide a lightweight local tracker for transactions without requiring manual entry.

Technology stack
- Flutter (Dart)
- Hive (encrypted) for local persistence
- flutter_secure_storage to store encryption key
- flutter_local_notifications for notifications
- another_telephony (or similar) for SMS access and background message handling
- device_info_plus, permission_handler for battery optimization helper and permissions
- Gradle / Android toolchain for packaging; Java 11 compatibility and core-library desugaring configuration

---

## AI Prompt Context

Original goals (user-facing requests that drove the work):
1. Migrate storage from sqflite to Hive with encryption.
2. Add an option to delete all data in the statistics page.
3. Add a way to enable/disable the background service from Settings.
4. Show a local notification when an SMS is detected and parsed as a transaction.
5. Analyze and fix analyzer warnings and build issues.
6. Resolve a release build failure caused by Android AAR metadata / desugaring requirements.

Key constraints & design goals:
- Keep data encrypted at rest using Hive + a secure key store.
- Preserve UX: immediate UI updates when new transactions are parsed, and a manual "scan inbox" option.
- Avoid BuildContext across async gaps; add mounted checks and cache ScaffoldMessenger/Navigator references.
- Maintain a minimal, dependency-light approach on Android — resolve Gradle requirements (desugaring) where needed.

---

## Prompting Strategy

Types of prompts used
- Instructional prompts: explicit asks like "migrate sqflite to Hive with encryption" and "add delete all data option".
- Role-based prompts: the AI was asked to act like an expert programming assistant (pair programmer) and to make edits in the codebase.
- Iterative refinement: repeated prompts to fix analyzer warnings, build errors, and to adjust Android Gradle config until the release build succeeded.

Common prompt pattern
- High-level instruction (goal) → request code changes → ask for static analysis fixes → run build → provide build errors → request targeted fixes.

Example prompts that produced the core outputs

1) Migrate storage and implement encrypted Hive:
"Change existing storage from sqflite to Hive, add encryption using flutter_secure_storage to persist the encryption key, create a HiveHelper with CRUD for TransactionItem."