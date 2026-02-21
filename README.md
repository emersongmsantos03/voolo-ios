# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Google Login (Android)

Web login is already implemented via `FirebaseAuth.signInWithPopup`.

For Android Google login to work, your `android/app/google-services.json` must include OAuth clients (it should NOT have `"oauth_client": []`).

Steps:
1. In Firebase Console: Authentication -> Sign-in method -> enable Google.
2. In Firebase Console: Project settings -> Your apps -> Android app -> add your app SHA-1.
3. Re-download `google-services.json` and replace `android/app/google-services.json`.
4. Run `flutter clean` then `flutter run`.
