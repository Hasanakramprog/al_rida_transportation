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
    apiKey: 'AIzaSyA2oyyjjQJtcaKDqaCQHLKNUo2Hfr5tJbY',
    appId: '1:558137143032:web:YOUR_WEB_APP_ID_HERE',
    messagingSenderId: '558137143032',
    projectId: 'al-rida-app',
    authDomain: 'al-rida-app.firebaseapp.com',
    storageBucket: 'al-rida-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2oyyjjQJtcaKDqaCQHLKNUo2Hfr5tJbY',
    appId: '1:558137143032:android:fbbb3543768a6e0d70550d',
    messagingSenderId: '558137143032',
    projectId: 'al-rida-app',
    storageBucket: 'al-rida-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2oyyjjQJtcaKDqaCQHLKNUo2Hfr5tJbY',
    appId: '1:558137143032:ios:YOUR_IOS_APP_ID_HERE',
    messagingSenderId: '558137143032',
    projectId: 'al-rida-app',
    storageBucket: 'al-rida-app.firebasestorage.app',
    iosBundleId: 'com.example.alRidaApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA2oyyjjQJtcaKDqaCQHLKNUo2Hfr5tJbY',
    appId: '1:558137143032:macos:YOUR_MACOS_APP_ID_HERE',
    messagingSenderId: '558137143032',
    projectId: 'al-rida-app',
    storageBucket: 'al-rida-app.firebasestorage.app',
    iosBundleId: 'com.example.alRidaApp',
  );
}
