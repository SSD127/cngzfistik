import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'ssd',
    authDomain: 'fistik-komisyon.firebaseapp.com',
    projectId: 'fistik-komisyon',
    storageBucket: 'fistik-komisyon.firebasestorage.app',
    messagingSenderId: '351227366477',
    appId: '1:351227366477:web:197ef51029295bc0b5a004',
    measurementId: 'G-PX62S7C2F3',
  );

  // Android ve iOS için google-services.json / GoogleService-Info.plist
  // gerekirse flutterfire configure ile eklenebilir.
  static const FirebaseOptions android = web;
  static const FirebaseOptions ios = web;
}
