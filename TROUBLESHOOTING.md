# Troubleshooting Guide

## Problem: Model Changes Not Reflected Until Hot Restart

### Gejala
- Saat menjalankan aplikasi Flutter, perubahan pada model yang sudah diperbaiki tidak muncul
- Perubahan baru muncul setelah melakukan hot restart (R) atau hot reload (r)
- Aplikasi masih menggunakan versi model yang lama

### Penyebab
1. **Build cache tidak terupdate** - Flutter menyimpan cache dari compiled code
2. **Model class tidak ter-rebuild** - Hot reload tidak selalu mendeteksi perubahan pada model class
3. **State management** - Objek model yang sudah di-instantiate tidak ter-recreate saat hot reload

### Solusi

#### Solusi 1: Flutter Clean (Recommended)
Jalankan perintah berikut untuk membersihkan cache dan rebuild aplikasi:

```bash
# 1. Clean build cache
flutter clean

# 2. Get dependencies kembali
flutter pub get

# 3. Rebuild aplikasi
flutter run
# atau
flutter build apk --debug
```

#### Solusi 2: Hot Restart vs Hot Reload
- **Hot Reload (r)**: Hanya reload UI, tidak rebuild state
- **Hot Restart (R)**: Restart aplikasi penuh, rebuild semua state
- **Full Restart**: Stop aplikasi dan jalankan ulang `flutter run`

Untuk perubahan model, selalu gunakan **Hot Restart (R)** minimal.

#### Solusi 3: Invalidate Caches (VS Code/Android Studio)
Jika menggunakan IDE:
- **VS Code**: Command Palette → "Flutter: Clean Project"
- **Android Studio**: File → Invalidate Caches / Restart

### Best Practices untuk Model Changes

1. **Setelah mengubah model class**, selalu lakukan:
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

2. **Gunakan const constructors** jika memungkinkan:
   ```dart
   class UserModel {
     const UserModel({required this.uid, required this.email});
   }
   ```

3. **Tambahkan toString() dan copyWith()** untuk debugging lebih mudah (sudah ada di UserModel)

4. **Gunakan code generation** untuk model yang kompleks:
   ```yaml
   # pubspec.yaml
   dev_dependencies:
     json_serializable: ^6.7.1
     build_runner: ^2.4.6
   ```

### Penjelasan Hot Reload di Flutter

Flutter hot reload memiliki batasan:
- ✅ **BISA**: UI changes, method implementations, function logic
- ❌ **TIDAK BISA**: Global variables, static fields, main(), initState() yang sudah dijalankan
- ⚠️ **KADANG-KADANG**: Model class changes, enum changes

**Rule of thumb**: Jika ragu, gunakan **Hot Restart (R)** atau **Full Restart**.

### Debug Tips

Jika masih mengalami masalah:

1. **Cek console output** untuk error:
   ```
   DEBUG: User data received - uid: xxx, displayName: 'xxx'
   ```

2. **Tambahkan print debugging** di model:
   ```dart
   factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
     print("DEBUG: Creating UserModel from map: $map");
     // ... rest of code
   }
   ```

3. **Verify Firebase data** di Firebase Console

4. **Check Flutter Doctor**:
   ```bash
   flutter doctor -v
   ```

### Catatan untuk Tim

- Selalu komunikasikan perubahan model ke tim
- Update dokumentasi API jika model berubah
- Jalankan `flutter clean` setelah merge branch dengan perubahan model
- Test di berbagai kondisi (fresh install, hot reload, hot restart)
