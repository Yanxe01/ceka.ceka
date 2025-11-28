# Environment Variables Setup Guide

## 📋 Overview

Project ini menggunakan file `.env` untuk menyimpan API keys dan konfigurasi sensitif lainnya. Ini adalah best practice untuk keamanan aplikasi.

## 🚀 Quick Start

### 1. Copy File Template

```bash
cp .env.example .env
```

### 2. Dapatkan Firebase API Keys

#### Cara Mendapatkan Firebase API Key:

1. **Buka Firebase Console**
   - Kunjungi: https://console.firebase.google.com/
   - Pilih project: **tugasmobile-59071**

2. **Untuk Android API Key:**
   - Klik ⚙️ (Settings) → Project settings
   - Scroll ke bagian "Your apps"
   - Klik aplikasi Android (com.mobile.cekaceka)
   - Lihat di bagian "Web API Key" atau "API Key"
   - Copy API key tersebut

3. **Untuk iOS API Key (jika ada):**
   - Sama seperti Android, tapi pilih aplikasi iOS
   - Copy API key dari konfigurasi iOS

4. **Untuk Web API Key:**
   - Klik ⚙️ → Project settings
   - Scroll ke "Web API Key"
   - Copy key tersebut

### 3. Update File .env

Edit file `.env` dan isi dengan nilai yang benar:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=tugasmobile-59071
FIREBASE_PROJECT_NUMBER=727120428216
FIREBASE_STORAGE_BUCKET=tugasmobile-59071.firebasestorage.app
FIREBASE_MOBILE_SDK_APP_ID=1:727120428216:android:ba0585e37c964b0c40c84d
FIREBASE_ANDROID_PACKAGE_NAME=com.mobile.cekaceka

# Firebase API Keys (Ganti dengan key yang ASLI dari Firebase Console!)
FIREBASE_API_KEY_ANDROID=AIzaSy...  # Ganti dengan key asli Anda
FIREBASE_API_KEY_IOS=AIzaSy...      # Ganti jika punya iOS app
FIREBASE_API_KEY_WEB=AIzaSy...      # Ganti dengan Web API Key
```

## 💻 Cara Menggunakan di Code

### Import EnvConfig

```dart
import 'package:cekaceka/config/env_config.dart';
```

### Akses Environment Variables

```dart
// Mendapatkan Firebase Project ID
String projectId = EnvConfig.firebaseProjectId;

// Mendapatkan API Key Android
String apiKey = EnvConfig.firebaseApiKeyAndroid;

// Mendapatkan custom key (optional)
String customKey = EnvConfig.getOptionalKey('CUSTOM_KEY', fallback: 'default_value');
```

### Validasi Konfigurasi

```dart
if (EnvConfig.validateFirebaseConfig()) {
  print('Firebase configuration is valid ✅');
} else {
  print('Firebase configuration is invalid ❌');
}
```

### Debug Configuration (Development only!)

```dart
// HANYA untuk debugging - HAPUS di production!
EnvConfig.printConfig();
```

## 🔒 Security Best Practices

### ✅ DO (Lakukan):

1. **Selalu** tambahkan `.env` ke `.gitignore`
2. **Jangan pernah** commit file `.env` ke Git
3. **Gunakan** `.env.example` sebagai template untuk tim
4. **Simpan** backup `.env` di tempat yang aman (1Password, Bitwarden, dll)
5. **Update** API keys secara berkala
6. **Gunakan** environment variables berbeda untuk development dan production

### ❌ DON'T (Jangan):

1. **Jangan** hardcode API keys langsung di code
2. **Jangan** share file `.env` via chat/email
3. **Jangan** screenshot file `.env` dengan key yang visible
4. **Jangan** commit `.env` ke public repository
5. **Jangan** gunakan API key production untuk development

## 📁 File Structure

```
cekaceka/
├── .env                    # File utama (JANGAN commit!)
├── .env.example           # Template (boleh commit)
├── lib/
│   └── config/
│       └── env_config.dart # Helper class untuk akses .env
└── ENV_SETUP.md           # Dokumentasi ini
```

## 🔧 Troubleshooting

### Problem: "Failed to load .env file"

**Solusi:**
1. Pastikan file `.env` ada di root project (sejajar dengan `pubspec.yaml`)
2. Pastikan `.env` sudah ditambahkan di `pubspec.yaml` → `assets`
3. Jalankan `flutter clean` dan `flutter pub get`

### Problem: "Environment variable not found"

**Solusi:**
1. Cek typo di nama variable di file `.env`
2. Pastikan tidak ada spasi sebelum/sesudah `=`
3. Restart aplikasi setelah mengubah `.env`

### Problem: "Config validation failed"

**Solusi:**
1. Pastikan semua required keys sudah diisi
2. Cek tidak ada karakter aneh atau newline di value
3. Gunakan `EnvConfig.printConfig()` untuk debug

## 🎯 Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `FIREBASE_PROJECT_ID` | ✅ Yes | Firebase project identifier |
| `FIREBASE_PROJECT_NUMBER` | ✅ Yes | Firebase project number |
| `FIREBASE_STORAGE_BUCKET` | ✅ Yes | Cloud Storage bucket URL |
| `FIREBASE_MOBILE_SDK_APP_ID` | ✅ Yes | Firebase app ID |
| `FIREBASE_ANDROID_PACKAGE_NAME` | ✅ Yes | Android package name |
| `FIREBASE_API_KEY_ANDROID` | ⚠️ Recommended | Android API key |
| `FIREBASE_API_KEY_IOS` | ❌ Optional | iOS API key |
| `FIREBASE_API_KEY_WEB` | ❌ Optional | Web API key |

## 📝 Notes

- File `.env` hanya dibaca saat aplikasi pertama kali dimulai
- Setiap perubahan di `.env` memerlukan hot restart (tidak cukup hot reload)
- Untuk production, pertimbangkan menggunakan Firebase Remote Config atau environment-specific builds

## 🆘 Need Help?

Jika masih ada masalah:
1. Cek file `.env.example` untuk format yang benar
2. Verifikasi Firebase Console untuk nilai yang tepat
3. Jalankan `flutter clean && flutter pub get`
4. Restart IDE dan emulator/device

---

**⚠️ PENTING:** Jangan pernah commit file `.env` dengan API keys asli ke Git repository!
