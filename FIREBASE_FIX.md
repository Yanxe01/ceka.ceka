# 🔥 Panduan Memperbaiki Firebase Authentication Error

## ❌ Masalah yang Terjadi:
Error: "Method doesn't allow unregistered callers (callers without established identity)"

## ✅ Penyebab:
1. Email/Password authentication belum diaktifkan di Firebase Console
2. File google-services.json perlu di-download ulang dari Firebase Console

---

## 🛠️ SOLUSI LENGKAP:

### **Step 1: Download google-services.json yang BARU**

1. **Buka Firebase Console:**
   - https://console.firebase.google.com/
   - Login dan pilih project: **tugasmobile-59071**

2. **Masuk ke Project Settings:**
   - Klik ⚙️ (gear icon) di sidebar kiri
   - Klik **"Project settings"**

3. **Scroll ke bagian "Your apps":**
   - Cari aplikasi Android: **"Ceka Ceka"** (com.mobile.cekaceka)
   - Klik aplikasi tersebut untuk expand

4. **Download google-services.json:**
   - Klik tombol **"Download google-services.json"**
   - Atau klik link "google-services.json" yang ada di bagian "SDK setup and configuration"

5. **Replace file lama:**
   - Copy file `google-services.json` yang baru di-download
   - Paste ke folder: `android/app/`
   - Replace file yang lama

---

### **Step 2: Aktifkan Email/Password Authentication**

1. **Buka Authentication:**
   - Di Firebase Console, klik menu **"Authentication"** di sidebar kiri
   - Jika pertama kali, klik **"Get Started"**

2. **Klik tab "Sign-in method":**
   - Ada 3 tab di atas: Users, Sign-in method, Settings
   - Klik **"Sign-in method"**

3. **Enable Email/Password:**
   - Cari **"Email/Password"** di daftar providers
   - Klik pada baris "Email/Password"
   - **AKTIFKAN toggle "Enable"** (geser ke kanan)
   - Klik **"Save"**

4. **Verifikasi:**
   - Status Email/Password harus berubah jadi **"Enabled"** dengan warna hijau

---

### **Step 3: Update Firestore Rules**

Pastikan Firebase Rules sudah benar:

1. **Buka Firestore Database:**
   - Klik **"Firestore Database"** di sidebar kiri
   - Klik tab **"Rules"**

2. **Paste rules berikut:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null;
    }
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. **Klik "Publish"**

---

### **Step 4: Clean Build & Restart**

1. **Stop aplikasi yang sedang running**

2. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Rebuild aplikasi:**
   ```bash
   flutter run
   ```

---

## 📋 Checklist:

- [ ] Download google-services.json BARU dari Firebase Console
- [ ] Replace file android/app/google-services.json
- [ ] Enable Email/Password di Firebase Authentication
- [ ] Update Firestore Rules
- [ ] Flutter clean & pub get
- [ ] Restart aplikasi

---

## 🔍 Cara Test:

1. Buka aplikasi
2. Klik "Register now"
3. Isi form registrasi
4. Jika berhasil, akan muncul "Registrasi berhasil!"
5. Login dengan email dan password yang baru dibuat

---

## ⚠️ Catatan Penting:

- File `.env` TIDAK digunakan untuk Firebase Android (menggunakan google-services.json)
- API Key di google-services.json boleh kosong untuk Android
- Yang penting adalah file google-services.json harus dari Firebase Console yang benar
- Setiap kali ganti konfigurasi Firebase, wajib flutter clean

---

## 🆘 Jika Masih Error:

1. Pastikan package name di Firebase Console sama: **com.mobile.cekaceka**
2. Cek di `android/app/build.gradle`, applicationId harus: `com.mobile.cekaceka`
3. Screenshot halaman Firebase Authentication dan kirim untuk di-review
