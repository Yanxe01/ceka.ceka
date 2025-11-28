import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration Helper
///
/// Digunakan untuk mengakses environment variables dari file .env
/// dengan cara yang aman dan mudah.
class EnvConfig {
  // Firebase Configuration
  static String get firebaseProjectId =>
      dotenv.get('FIREBASE_PROJECT_ID', fallback: '');

  static String get firebaseProjectNumber =>
      dotenv.get('FIREBASE_PROJECT_NUMBER', fallback: '');

  static String get firebaseStorageBucket =>
      dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: '');

  static String get firebaseMobileSdkAppId =>
      dotenv.get('FIREBASE_MOBILE_SDK_APP_ID', fallback: '');

  static String get firebaseAndroidPackageName =>
      dotenv.get('FIREBASE_ANDROID_PACKAGE_NAME', fallback: '');

  // Firebase API Keys
  static String get firebaseApiKeyAndroid =>
      dotenv.get('FIREBASE_API_KEY_ANDROID', fallback: '');

  static String get firebaseApiKeyIos =>
      dotenv.get('FIREBASE_API_KEY_IOS', fallback: '');

  static String get firebaseApiKeyWeb =>
      dotenv.get('FIREBASE_API_KEY_WEB', fallback: '');

  // Optional: Other API Keys
  static String getOptionalKey(String key, {String fallback = ''}) {
    return dotenv.get(key, fallback: fallback);
  }

  /// Check if all required Firebase keys are present
  static bool validateFirebaseConfig() {
    return firebaseProjectId.isNotEmpty &&
           firebaseProjectNumber.isNotEmpty &&
           firebaseStorageBucket.isNotEmpty &&
           firebaseMobileSdkAppId.isNotEmpty;
  }

  /// Print configuration (for debugging only - remove in production)
  static void printConfig() {
    print('=== Environment Configuration ===');
    print('Firebase Project ID: $firebaseProjectId');
    print('Firebase Project Number: $firebaseProjectNumber');
    print('Firebase Storage Bucket: $firebaseStorageBucket');
    print('Firebase Mobile SDK App ID: $firebaseMobileSdkAppId');
    print('Firebase Android Package: $firebaseAndroidPackageName');
    print('Config Valid: ${validateFirebaseConfig()}');
    print('================================');
  }
}
