# 📤 Panduan Push ke GitHub dengan Aman

## ✅ Status Saat Ini: AMAN untuk di-Push!

Saya sudah mengamankan semua file sensitif. Berikut yang akan di-commit:

### 🟢 File yang AMAN di-commit:

- ✅ `.gitignore` (sudah di-update untuk exclude file sensitif)
- ✅ `.env.example` (template, tanpa API key asli)
- ✅ `android/app/google-services.json.example` (template)
- ✅ `lib/config/env_config.dart` (helper untuk .env)
- ✅ `lib/main.dart` (load dotenv)
- ✅ `pubspec.yaml` (dependencies)
- ✅ `ENV_SETUP.md` (dokumentasi)
- ✅ `FIREBASE_FIX.md` (dokumentasi)
- ✅ `SECURITY.md` (panduan keamanan)

### 🔴 File yang TIDAK akan di-commit (sudah di-gitignore):

- ❌ `.env` (berisi API key ASLI)
- ❌ `android/app/google-services.json` (berisi API key ASLI)
- ❌ File build dan cache

---

## 🚀 Langkah Push ke GitHub

### 1. Verifikasi File yang Akan di-Commit

```bash
git status
```

**Pastikan `google-services.json` dan `.env` TIDAK muncul di daftar!**

### 2. Add File yang Aman

```bash
git add .gitignore
git add .env.example
git add android/app/google-services.json.example
git add lib/config/env_config.dart
git add lib/main.dart
git add pubspec.yaml
git add pubspec.lock
git add ENV_SETUP.md
git add FIREBASE_FIX.md
git add SECURITY.md
```

Atau lebih simple:

```bash
git add .
```

### 3. Commit dengan Pesan yang Jelas

```bash
git commit -m "feat: add environment variables support with .env

- Add flutter_dotenv package
- Create EnvConfig helper class
- Add .env.example template
- Add google-services.json.example template
- Update .gitignore to exclude sensitive files
- Add security documentation

BREAKING CHANGE: Developers need to setup .env file locally
See SECURITY.md for setup instructions"
```

### 4. Push ke GitHub

```bash
git push origin main
```

Atau jika branch lain:

```bash
git push origin nama-branch-anda
```

---

## 🔒 Security Checklist (Cek Sebelum Push!)

Pastikan semua ini ✅ sebelum push:

- [ ] File `.env` **TIDAK** muncul di `git status`
- [ ] File `google-services.json` **TIDAK** muncul di `git status`
- [ ] File `.gitignore` sudah di-update
- [ ] Ada file `.env.example` sebagai template
- [ ] Ada file `google-services.json.example` sebagai template
- [ ] Dokumentasi SECURITY.md sudah dibuat
- [ ] Tidak ada API keys hardcoded di code
- [ ] Tidak ada debug prints yang print API keys

---

## 📝 Catatan untuk Tim

Setelah clone repository, tim harus:

1. Copy `.env.example` menjadi `.env`
2. Copy `google-services.json.example` menjadi `google-services.json`
3. Minta API keys dari team lead
4. Update kedua file tersebut dengan credentials yang benar
5. Jalankan `flutter pub get`

**Lihat [SECURITY.md](SECURITY.md) untuk panduan lengkap.**

---

## 🆘 Troubleshooting

### "google-services.json masih muncul di git status"

```bash
# Remove dari cache
git rm --cached android/app/google-services.json

# Verify gitignore
cat .gitignore | grep google-services
```

### ".env masih muncul di git status"

```bash
# Remove dari cache
git rm --cached .env

# Verify gitignore
cat .gitignore | grep .env
```

### "Sudah terlanjur commit API key"

1. **JANGAN PANIK!**
2. Regenerate API key di Firebase Console
3. Revoke key yang lama
4. Update `.env` dengan key baru
5. Gunakan `git filter-branch` atau BFG Repo-Cleaner untuk clean history (advanced)
6. Atau buat repository baru (simple)

---

## ✅ Sekarang Aman untuk Push!

Setelah semua checklist ✅, Anda sudah aman untuk push ke GitHub.

```bash
git push origin main
```

🎉 **Happy Coding & Stay Safe!**
