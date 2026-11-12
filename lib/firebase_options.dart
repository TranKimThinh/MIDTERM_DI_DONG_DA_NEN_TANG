import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
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
    apiKey: 'AIzaSyBw9OKkrpFOk7iggnqBbxOlHkVIj20479U',
    appId: '1:924793890242:web:5c7256e101935f078b225b',
    messagingSenderId: '924793890242',
    projectId: 'midterm-di-dong-da-nen-tang',
    authDomain: 'midterm-di-dong-da-nen-tang.firebaseapp.com',
    storageBucket: 'midterm-di-dong-da-nen-tang.firebasestorage.app',
    measurementId: 'G-GLNXG88DL5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBk7M2Lm1XPApeDpSpyWJ2Ic8Q861krhmE',
    appId: '1:924793890242:android:40ac1e81ee1c51c18b225b',
    messagingSenderId: '924793890242',
    projectId: 'midterm-di-dong-da-nen-tang',
    storageBucket: 'midterm-di-dong-da-nen-tang.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBf2bz__xNYQkSV9pmKByYcWBx1lSC5xWM',
    appId: '1:924793890242:ios:a76e60f5fa1558778b225b',
    messagingSenderId: '924793890242',
    projectId: 'midterm-di-dong-da-nen-tang',
    storageBucket: 'midterm-di-dong-da-nen-tang.firebasestorage.app',
    iosBundleId: 'com.example.midtermCrud',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBf2bz__xNYQkSV9pmKByYcWBx1lSC5xWM',
    appId: '1:924793890242:ios:a76e60f5fa1558778b225b',
    messagingSenderId: '924793890242',
    projectId: 'midterm-di-dong-da-nen-tang',
    storageBucket: 'midterm-di-dong-da-nen-tang.firebasestorage.app',
    iosBundleId: 'com.example.midtermCrud',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBw9OKkrpFOk7iggnqBbxOlHkVIj20479U',
    appId: '1:924793890242:web:5c7256e101935f078b225b',
    messagingSenderId: '924793890242',
    projectId: 'midterm-di-dong-da-nen-tang',
    authDomain: 'midterm-di-dong-da-nen-tang.firebaseapp.com',
    storageBucket: 'midterm-di-dong-da-nen-tang.firebasestorage.app',
    measurementId: 'G-GLNXG88DL5',
  );
}
