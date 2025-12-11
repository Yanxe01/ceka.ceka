import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi Firebase untuk aplikasi CekaCeka
class FirebaseConfig {
  // Firebase options untuk berbagai platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return webOptions;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidOptions;
      case TargetPlatform.iOS:
        return iosOptions;
      default:
        throw UnsupportedError(
          'FirebaseOptions tidak dikonfigurasi untuk platform ini.',
        );
    }
  }

  // IMPORTANT: Ganti dengan konfigurasi Firebase Anda sendiri
  // Dapatkan dari Firebase Console > Project Settings > Your apps

  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: '', //GANTI API YANG DIBUAT
    appId: '1:727120428216:android:ba0585e37c964b0c40c84d',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: '', //GANTI API YANG DIBUAT
    appId: '1:727120428216:android:ba0585e37c964b0c40c84d',
    messagingSenderId: '727120428216',
    projectId: 'tugasmobile-59071',
    storageBucket: 'tugasmobile-59071.firebasestorage.app',
  );

  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.cekaceka',
  );

  /// Inisialisasi Firebase
  static Future<void> initialize() async {
    // Cek apakah Firebase sudah diinisialisasi
    if (Firebase.apps.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('Firebase already initialized');
      }
      return;
    }

    // Inisialisasi Firebase
    // Untuk Android: google-services.json otomatis menyediakan config
    // Untuk platform lain: gunakan options manual
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: Biarkan google-services.json handle config
      await Firebase.initializeApp();
    } else {
      // Platform lain: Gunakan config manual
      await Firebase.initializeApp(options: currentPlatform);
    }
  }
}
