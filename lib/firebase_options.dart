import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

/// Checked-in Firebase options for native mobile startup.
///
/// This keeps iOS simulator/App Preview startup from depending solely on
/// discovery of a bundled `GoogleService-Info.plist`.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-DCmov4aHL7r4Tyz6yU6gZ4ZlbhJPl9o',
    appId: '1:100666481363:android:f1e5d37da415fea4975226',
    messagingSenderId: '100666481363',
    projectId: 'voolo-ad416',
    storageBucket: 'voolo-ad416.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChm8NlXhW1-1OYPfEiqJbNGOvdWSgU8cI',
    appId: '1:100666481363:ios:7a4f4eb893b6b4f6975226',
    messagingSenderId: '100666481363',
    projectId: 'voolo-ad416',
    storageBucket: 'voolo-ad416.firebasestorage.app',
    iosClientId:
        '100666481363-r1nvlcji3h8nc72i3abnfjhkmin2s5ed.apps.googleusercontent.com',
    iosBundleId: 'com.voolo.jetx',
  );
}
