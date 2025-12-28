// File generated for Firebase Flutter integration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8y4RuLFi4Zb6ZVyt92lh7gex8o_EjhRw',
    appId: '1:668278179102:web:44dcc5ef7fe1eb7e0fb50f',
    messagingSenderId: '668278179102',
    projectId: 'business-tools-bots',
    authDomain: 'business-tools-bots.firebaseapp.com',
    storageBucket: 'business-tools-bots.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8y4RuLFi4Zb6ZVyt92lh7gex8o_EjhRw',
    appId: '1:668278179102:android:44dcc5ef7fe1eb7e0fb50f',
    messagingSenderId: '668278179102',
    projectId: 'business-tools-bots',
    authDomain: 'business-tools-bots.firebaseapp.com',
    storageBucket: 'business-tools-bots.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8y4RuLFi4Zb6ZVyt92lh7gex8o_EjhRw',
    appId: '1:668278179102:ios:44dcc5ef7fe1eb7e0fb50f',
    messagingSenderId: '668278179102',
    projectId: 'business-tools-bots',
    authDomain: 'business-tools-bots.firebaseapp.com',
    storageBucket: 'business-tools-bots.firebasestorage.app',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8y4RuLFi4Zb6ZVyt92lh7gex8o_EjhRw',
    appId: '1:668278179102:ios:44dcc5ef7fe1eb7e0fb50f',
    messagingSenderId: '668278179102',
    projectId: 'business-tools-bots',
    authDomain: 'business-tools-bots.firebaseapp.com',
    storageBucket: 'business-tools-bots.firebasestorage.app',
    iosBundleId: 'com.example.chatApp',
  );
}
