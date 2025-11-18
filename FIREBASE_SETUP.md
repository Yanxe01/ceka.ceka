# Setup Firebase untuk CekaCeka

Panduan lengkap untuk mengkonfigurasi Firebase di aplikasi CekaCeka.

## Langkah 1: Buat Project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Create a project"
3. Masukkan nama project: **CekaCeka**
4. Ikuti wizard setup hingga selesai

## Langkah 2: Registrasi Aplikasi Android

### 2.1. Tambah Android App

1. Di Firebase Console, klik icon Android
2. Masukkan Android package name: `com.example.cekaceka` (atau sesuai package name di AndroidManifest.xml)
3. Masukkan app nickname: **CekaCeka Android**
4. Skip SHA-1 untuk saat ini (bisa ditambahkan nanti jika perlu Google Sign-In)
5. Klik "Register app"

### 2.2. Download google-services.json

1. Download file `google-services.json`
2. Letakkan file di: `android/app/google-services.json`

### 2.3. Update Android Build Files

**File: `android/build.gradle`**

Tambahkan di bagian `dependencies`:

```gradle
buildscript {
    dependencies {
        // ... dependencies lainnya
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

**File: `android/app/build.gradle`**

Tambahkan di bagian paling bawah:

```gradle
apply plugin: 'com.google.gms.google-services'
```

Dan pastikan `minSdkVersion` minimal 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimal SDK untuk Firebase
        // ... config lainnya
    }
}
```

## Langkah 3: Registrasi Aplikasi iOS (Opsional)

### 3.1. Tambah iOS App

1. Di Firebase Console, klik icon iOS
2. Masukkan iOS bundle ID: `com.example.cekaceka`
3. Masukkan app nickname: **CekaCeka iOS**
4. Klik "Register app"

### 3.2. Download GoogleService-Info.plist

1. Download file `GoogleService-Info.plist`
2. Buka Xcode project di `ios/Runner.xcworkspace`
3. Drag file `GoogleService-Info.plist` ke Xcode project (di bawah Runner folder)
4. Pastikan "Copy items if needed" dicentang

## Langkah 4: Registrasi Aplikasi Web (Opsional)

### 4.1. Tambah Web App

1. Di Firebase Console, klik icon Web (</>)
2. Masukkan app nickname: **CekaCeka Web**
3. Klik "Register app"
4. Copy konfigurasi Firebase yang muncul

## Langkah 5: Aktifkan Firebase Services

### 5.1. Firebase Authentication

1. Di Firebase Console, buka **Authentication**
2. Klik "Get started"
3. Pilih tab **Sign-in method**
4. Aktifkan **Email/Password**:
   - Klik "Email/Password"
   - Toggle "Enable"
   - Klik "Save"

### 5.2. Cloud Firestore

1. Di Firebase Console, buka **Firestore Database**
2. Klik "Create database"
3. Pilih mode:
   - **Production mode** (untuk production)
   - **Test mode** (untuk development, auto akan berubah ke production setelah 30 hari)
4. Pilih location (pilih yang terdekat dengan user, misal: `asia-southeast1`)
5. Klik "Enable"

### 5.3. Firebase Storage

1. Di Firebase Console, buka **Storage**
2. Klik "Get started"
3. Pilih mode security rules (biasanya production mode)
4. Pilih location yang sama dengan Firestore
5. Klik "Done"

### 5.4. Firebase Cloud Messaging (FCM)

FCM sudah otomatis aktif saat menambahkan aplikasi ke Firebase project.

## Langkah 6: Konfigurasi Firebase di Aplikasi

### 6.1. Dapatkan Firebase Config

1. Di Firebase Console, klik icon Settings (⚙️) > Project settings
2. Scroll ke bawah ke bagian "Your apps"
3. Untuk setiap platform (Android, iOS, Web), klik app dan copy config:

**Android:**
- Copy values dari `google-services.json`:
  - `api_key` → `apiKey`
  - `mobilesdk_app_id` → `appId`
  - `project_id` → `projectId`
  - `storage_bucket` → `storageBucket`
  - `project_number` → `messagingSenderId`

**Web:**
- Copy seluruh config object yang ditampilkan

### 6.2. Update firebase_config.dart

Edit file `lib/config/firebase_config.dart` dan ganti placeholder dengan nilai yang sebenarnya:

```dart
static const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: 'AIzaSy...', // Dari google-services.json
  appId: '1:123456789:android:...', // Dari google-services.json
  messagingSenderId: '123456789', // Dari google-services.json
  projectId: 'cekaceka-12345', // Dari google-services.json
  storageBucket: 'cekaceka-12345.appspot.com', // Dari google-services.json
);

static const FirebaseOptions webOptions = FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:123456789:web:...',
  messagingSenderId: '123456789',
  projectId: 'cekaceka-12345',
  authDomain: 'cekaceka-12345.firebaseapp.com',
  storageBucket: 'cekaceka-12345.appspot.com',
);

static const FirebaseOptions iosOptions = FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:123456789:ios:...',
  messagingSenderId: '123456789',
  projectId: 'cekaceka-12345',
  storageBucket: 'cekaceka-12345.appspot.com',
  iosBundleId: 'com.example.cekaceka',
);
```

## Langkah 7: Setup Firestore Security Rules

Di Firebase Console > Firestore Database > Rules, gunakan rules berikut:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function untuk check apakah user sudah login
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function untuk check apakah user adalah pemilik data
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // Semua user yang login bisa membaca semua user (untuk fitur pencarian)
      allow read: if isSignedIn();

      // User hanya bisa membuat/update/delete data mereka sendiri
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }

    // Tambahkan rules untuk collection lain di sini
    // Contoh: pagian, grup, status, dll.
  }
}
```

## Langkah 8: Setup Firebase Storage Rules

Di Firebase Console > Storage > Rules, gunakan rules berikut:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper function
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // User uploads
    match /users/{userId}/{allPaths=**} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }

    // Foto transfer (untuk fitur transfer foto)
    match /transfers/{transferId}/{allPaths=**} {
      allow read: if isSignedIn();
      allow write: if isSignedIn();
    }
  }
}
```

## Langkah 9: Test Setup

Jalankan aplikasi untuk memastikan Firebase sudah terkonfigurasi dengan benar:

```bash
flutter run
```

Cek console untuk memastikan tidak ada error Firebase initialization.

## Langkah 10: Setup Cloud Messaging (FCM) - Opsional

### Android

**File: `android/app/src/main/AndroidManifest.xml`**

Tambahkan permission:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Troubleshooting

### Error: "Default FirebaseApp is not initialized"

**Solusi:**
- Pastikan `google-services.json` (Android) sudah ada di `android/app/`
- Pastikan sudah menambahkan `apply plugin: 'com.google.gms.google-services'` di `android/app/build.gradle`
- Jalankan `flutter clean` dan `flutter pub get`

### Error: "PlatformException (channel-error, ...)"

**Solusi:**
- Pastikan `firebase_config.dart` sudah diisi dengan config yang benar
- Periksa internet connection

### Error: "PERMISSION_DENIED: Missing or insufficient permissions"

**Solusi:**
- Periksa Firestore Security Rules
- Pastikan user sudah login sebelum mengakses Firestore

## Struktur Database Firestore

```
cekaceka/
└── users/
    └── {userId}/
        ├── email: string
        ├── displayName: string
        ├── phoneNumber: string
        ├── photoURL: string
        ├── createdAt: timestamp
        └── updatedAt: timestamp
```

## Struktur Firebase Storage

```
cekaceka.appspot.com/
├── users/
│   └── {userId}/
│       ├── profile/
│       │   └── avatar.jpg
│       └── uploads/
│           └── {fileId}.jpg
└── transfers/
    └── {transferId}/
        └── {fileId}.jpg
```

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

## Next Steps

Setelah setup Firebase selesai, Anda bisa:

1. Implementasi halaman Login dan Register
2. Implementasi halaman Profile
3. Tambahkan fitur upload foto (Storage)
4. Tambahkan fitur notifikasi (FCM)
5. Implementasi fitur transfer foto antar user

Lihat dokumentasi lengkap di `lib/services/README.md` untuk cara penggunaan Firebase services.
