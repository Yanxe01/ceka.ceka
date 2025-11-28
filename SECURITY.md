# 🔒 Security & Setup Guide

## ⚠️ PENTING - Jangan Commit File Sensitif!

File-file berikut **TIDAK BOLEH** di-commit ke repository karena berisi API keys dan credentials:

### ❌ File yang TIDAK BOLEH di-commit:

1. **`.env`** - Environment variables
2. **`android/app/google-services.json`** - Firebase config untuk Android
3. **`ios/Runner/GoogleService-Info.plist`** - Firebase config untuk iOS
4. **`lib/firebase_options.dart`** - Firebase options (jika ada)

### ✅ File yang BOLEH di-commit:

1. **`.env.example`** - Template environment variables
2. **`android/app/google-services.json.example`** - Template Firebase config
3. **`.gitignore`** - Sudah dikonfigurasi untuk exclude file sensitif

---

## 🛠️ Setup untuk Developer Baru

Jika Anda clone repository ini, ikuti langkah berikut:

### 1. Setup Environment Variables

```bash
# Copy template .env
cp .env.example .env

# Edit .env dan isi dengan nilai yang benar
# Dapatkan nilai dari team lead atau Firebase Console
```

### 2. Setup Firebase untuk Android

```bash
# Copy template google-services.json
cp android/app/google-services.json.example android/app/google-services.json
```

Kemudian:
1. Buka Firebase Console: https://console.firebase.google.com/
2. Pilih project yang benar
3. Download `google-services.json` yang asli
4. Replace file `android/app/google-services.json` dengan file yang di-download

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run Aplikasi

```bash
flutter run
```

---

## 🔑 Cara Mendapatkan Credentials

### Firebase API Key:

1. Buka Firebase Console
2. Klik ⚙️ → Project Settings
3. Scroll ke "Your apps"
4. Download `google-services.json` untuk Android
5. Atau copy Web API Key untuk platform lain

### Environment Variables:

Minta kepada team lead atau lihat di Firebase Console:
- Project ID
- Project Number
- Storage Bucket
- App ID

---

## 📋 Security Checklist

Sebelum push ke GitHub, pastikan:

- [ ] File `.env` **TIDAK** ada di git status
- [ ] File `google-services.json` **TIDAK** ada di git status
- [ ] File `.gitignore` sudah di-update
- [ ] Tidak ada API keys di code (gunakan environment variables)
- [ ] Debug prints yang berisi sensitive data sudah dihapus

---

## 🚨 Jika API Key Ter-commit

Jika tidak sengaja commit API key ke GitHub:

1. **Regenerate API Key** di Firebase Console
2. **Revoke** API key yang lama
3. **Update** semua environment variables
4. **Clean git history** atau gunakan GitHub secret scanning alerts

---

## 📞 Kontak

Jika ada pertanyaan tentang setup atau credentials:
- Hubungi: Team Lead
- Dokumentasi: Lihat [ENV_SETUP.md](ENV_SETUP.md) dan [FIREBASE_FIX.md](FIREBASE_FIX.md)

---

**⚠️ INGAT:** Jangan pernah commit API keys, tokens, atau credentials ke repository public!
