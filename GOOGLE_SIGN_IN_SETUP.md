# Google Sign In Setup Guide

## Overview

Aplikasi CekaCeka telah dilengkapi dengan fitur Google Sign In yang memungkinkan user untuk:
1. Login menggunakan akun Google
2. Menghubungkan akun Google ke akun email/password yang sudah ada
3. Memutuskan hubungan akun Google

## Fitur yang Sudah Diimplementasikan

### 1. Google Auth Service
File: [lib/services/google_auth_service.dart](lib/services/google_auth_service.dart)

Methods yang tersedia:
- `signInWithGoogle()` - Login dengan akun Google
- `linkWithGoogle()` - Hubungkan Google ke akun yang sedang login
- `unlinkGoogle()` - Putuskan hubungan akun Google
- `isGoogleLinked()` - Cek apakah Google sudah terhubung
- `getLinkedGoogleEmail()` - Dapatkan email Google yang terhubung
- `signOut()` - Logout dari Firebase dan Google

### 2. Login Page Integration
File: [lib/pages/login_page.dart](lib/pages/login_page.dart)

- Tombol Google Sign In sudah ditambahkan (ikon Google berwarna coklat)
- Ketika user login dengan Google:
  - Jika user baru → otomatis membuat document di Firestore
  - Jika user sudah ada → langsung login
  - Navigasi ke OnboardingPage setelah berhasil

### 3. Profile Page Integration
File: [lib/pages/profile_page.dart](lib/pages/profile_page.dart)

- Menu "Akun Terkait" sudah fungsional
- Menampilkan status linked/unlinked
- Menampilkan email Google yang terhubung (jika ada)
- Tombol untuk link/unlink Google account

## Firebase Console Configuration

### Langkah 1: Enable Google Sign In di Firebase Console

1. **Buka Firebase Console**:
   - Go to https://console.firebase.google.com/
   - Pilih project Anda

2. **Enable Google Sign In Provider**:
   - Klik **Authentication** di sidebar
   - Klik tab **Sign-in method**
   - Cari **Google** di daftar providers
   - Klik **Google** → Klik **Enable**
   - Pilih **Project support email** (email Anda)
   - Klik **Save**

### Langkah 2: Konfigurasi untuk Android

#### 2.1. Dapatkan SHA-1 Fingerprint

Jalankan command berikut di terminal untuk mendapatkan SHA-1:

```bash
cd android
./gradlew signingReport
```

Atau di Windows:
```bash
cd android
gradlew.bat signingReport
```

Cari output seperti ini:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
SHA-256: ...
```

**Copy SHA-1 fingerprint** (yang panjang dengan format AA:BB:CC:...)

#### 2.2. Tambahkan SHA-1 ke Firebase Project

1. **Buka Project Settings di Firebase Console**:
   - Klik icon **gear** (⚙️) di sidebar → **Project settings**
   - Scroll ke bagian **Your apps**
   - Pilih aplikasi Android Anda

2. **Tambahkan SHA certificate fingerprint**:
   - Scroll ke bawah ke bagian **SHA certificate fingerprints**
   - Klik **Add fingerprint**
   - Paste SHA-1 yang sudah di-copy
   - Klik **Save**

#### 2.3. Download google-services.json Baru

Setelah menambahkan SHA-1:
1. Scroll ke atas di halaman yang sama
2. Klik **Download google-services.json**
3. Replace file `android/app/google-services.json` dengan file baru
4. **PENTING**: Restart aplikasi (bukan hot reload/restart!)

### Langkah 3: Konfigurasi untuk iOS (Opsional)

#### 3.1. Tambahkan GoogleService-Info.plist

1. Download `GoogleService-Info.plist` dari Firebase Console
2. Copy ke folder `ios/Runner/`
3. Buka `ios/Runner.xcworkspace` di Xcode
4. Drag `GoogleService-Info.plist` ke project

#### 3.2. Update Info.plist

Buka `ios/Runner/Info.plist` dan tambahkan:

```xml
<!-- Google Sign In -->
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<!-- TODO: Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
			<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
		</array>
	</dict>
</array>
```

Ganti `YOUR_CLIENT_ID` dengan nilai `REVERSED_CLIENT_ID` dari `GoogleService-Info.plist`.

### Langkah 4: Konfigurasi untuk Web (Opsional)

1. **Enable Web Client ID**:
   - Sudah otomatis dibuat saat enable Google Sign In
   - Bisa dilihat di Firebase Console → Authentication → Sign-in method → Google

2. **Update index.html**:

   Buka `web/index.html` dan tambahkan sebelum `</head>`:

```html
<!-- Google Sign In -->
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

Ganti `YOUR_WEB_CLIENT_ID` dengan Web client ID dari Firebase Console.

## Testing Google Sign In

### Test di Android Emulator/Device

1. **Build dan Run**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Flow**:
   - Klik tombol Google Sign In (ikon Google coklat)
   - Pilih akun Google
   - Login seharusnya berhasil dan navigasi ke OnboardingPage

3. **Test Link/Unlink**:
   - Login dengan email/password biasa terlebih dahulu
   - Go to Profile Page
   - Klik "Akun Terkait"
   - Klik "Hubungkan dengan Google"
   - Pilih akun Google
   - Seharusnya berhasil terhubung
   - Coba putuskan hubungan

### Common Issues

#### Issue 1: "PlatformException(sign_in_failed)"

**Penyebab**: SHA-1 fingerprint belum ditambahkan atau salah

**Solusi**:
1. Pastikan SHA-1 sudah ditambahkan di Firebase Console
2. Download ulang `google-services.json`
3. Restart aplikasi (STOP dan RUN ulang, bukan hot restart)
4. Jika masih error, coba:
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

#### Issue 2: "ApiException: 10"

**Penyebab**: google-services.json tidak up to date

**Solusi**:
1. Download ulang `google-services.json` dari Firebase Console
2. Replace file di `android/app/google-services.json`
3. Restart aplikasi

#### Issue 3: User cancel sign in

**Behavior**: Jika user membatalkan sign in, akan muncul error "Sign in dibatalkan"

**Solusi**: Ini adalah expected behavior, user bisa coba lagi

#### Issue 4: "credential-already-in-use"

**Penyebab**: Akun Google sudah digunakan oleh user lain

**Solusi**:
- Logout dari akun yang sedang menggunakan Google tersebut
- Atau gunakan akun Google yang berbeda

#### Issue 5: "provider-already-linked"

**Penyebab**: Akun Google sudah terhubung dengan akun ini

**Solusi**: Ini adalah expected behavior, tidak perlu link ulang

## Debug Logs

Aplikasi sudah dilengkapi dengan debug logs. Cek console untuk:

```
DEBUG: Starting Google Sign In...
DEBUG: Google user selected: user@gmail.com
DEBUG: Got Google auth token
DEBUG: Created Firebase credential
DEBUG: Signed in to Firebase: user@gmail.com
```

Jika ada error, akan muncul:
```
DEBUG: Firebase Auth Exception: [error_code] - [error_message]
DEBUG: Google Sign In error: [error_details]
```

## Firestore Data Structure

Ketika user login dengan Google, data disimpan di Firestore dengan struktur:

```json
{
  "uid": "firebase_user_id",
  "displayName": "User Full Name",
  "email": "user@gmail.com",
  "phoneNumber": "",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

## Security Considerations

1. **Re-authentication**: Untuk operasi sensitive (unlink), user akan diminta login ulang jika session sudah lama
2. **Error Handling**: Semua error ditangani dengan baik dan ditampilkan ke user
3. **Provider Validation**: Tidak bisa unlink provider terakhir (akan error)

## Files yang Relevan

- [lib/services/google_auth_service.dart](lib/services/google_auth_service.dart) - Google Auth service
- [lib/services/auth_exceptions.dart](lib/services/auth_exceptions.dart) - Exception handling
- [lib/pages/login_page.dart](lib/pages/login_page.dart:132-197) - Login with Google
- [lib/pages/profile_page.dart](lib/pages/profile_page.dart:20-225) - Link/Unlink Google
- [pubspec.yaml](pubspec.yaml:50) - google_sign_in dependency
- `android/app/google-services.json` - Firebase config for Android

## Next Steps

Setelah setup selesai:

1. ✅ Enable Google Sign In di Firebase Console
2. ✅ Tambahkan SHA-1 fingerprint
3. ✅ Download google-services.json baru
4. ✅ Test sign in dengan Google
5. ✅ Test link/unlink di Profile Page

## Troubleshooting Checklist

Jika Google Sign In tidak bekerja, cek:

- [ ] Google Sign In sudah di-enable di Firebase Console
- [ ] SHA-1 fingerprint sudah ditambahkan
- [ ] File `google-services.json` sudah up to date
- [ ] Aplikasi sudah di-restart (bukan hot reload)
- [ ] Internet connection tersedia
- [ ] Google Play Services terinstall (untuk Android)

---

**Status**: ✅ Code Implementation Complete - Tinggal Firebase Console Configuration
