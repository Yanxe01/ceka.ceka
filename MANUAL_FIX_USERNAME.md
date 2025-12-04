# Manual Fix untuk Username yang Tidak Muncul

## Masalah
Username tidak muncul di home page karena user yang terdaftar sebelumnya menggunakan field lama (`'name'`) bukan field baru (`'displayName'`).

## Solusi

### Opsi 1: Auto-Migration (Otomatis)

Aplikasi sudah dilengkapi dengan **auto-migration** yang akan berjalan saat HomePage pertama kali load.

Cara kerja:
1. Login ke aplikasi
2. Tunggu HomePage load
3. Auto-migration akan berjalan di background
4. Setelah selesai, **hot restart** aplikasi (tekan R di terminal)
5. Username akan muncul

### Opsi 2: Manual Update di Firebase Console

Jika auto-migration tidak bekerja, Anda bisa update manual di Firebase Console:

1. **Buka Firebase Console**:
   - Go to https://console.firebase.google.com/
   - Pilih project Anda
   - Klik **Firestore Database** di sidebar

2. **Cari Collection `users`**:
   - Klik collection `users`
   - Anda akan melihat list semua user documents

3. **Update Each User Document**:
   Untuk setiap user yang bermasalah:

   a. **Klik document user** (dokumen dengan UID user)

   b. **Periksa field-field yang ada**:
   - Jika ada field `name` tapi tidak ada `displayName`:
     - Klik **Add field**
     - Field name: `displayName`
     - Type: `string`
     - Value: (copy nilai dari field `name`)
     - Klik **Add**

   - Jika ada field `phone` tapi tidak ada `phoneNumber`:
     - Klik **Add field**
     - Field name: `phoneNumber`
     - Type: `string`
     - Value: (copy nilai dari field `phone`)
     - Klik **Add**

   c. **(Opsional) Hapus field lama**:
     - Hover ke field `name` → Klik icon delete
     - Hover ke field `phone` → Klik icon delete

4. **Restart Aplikasi**:
   - Close aplikasi
   - Jalankan ulang dengan `flutter run`
   - Login
   - Username akan muncul

### Opsi 3: Menggunakan Migration Page

Aplikasi dilengkapi dengan halaman khusus untuk migrasi data:

1. **Tambahkan route ke MigrationPage** (temporary):

   Buka file yang memiliki navigator (misalnya ProfilePage atau SettingsPage), tambahkan button:

   ```dart
   import '../pages/migration_page.dart';

   // Di dalam widget build:
   ElevatedButton(
     onPressed: () {
       Navigator.push(
         context,
         MaterialPageRoute(builder: (context) => const MigrationPage()),
       );
     },
     child: const Text("Fix Username Data"),
   )
   ```

2. **Jalankan aplikasi dan klik button tersebut**

3. **Di Migration Page**:
   - Klik "Migrate Current User" untuk migrate user yang sedang login
   - Atau klik "Migrate All Users (Admin)" untuk migrate semua user sekaligus

4. **Setelah selesai**:
   - Restart aplikasi
   - Username akan muncul

### Opsi 4: Register User Baru

Jika tidak ada data penting yang perlu dipertahankan:

1. Logout dari akun lama
2. Register akun baru dengan nama yang diinginkan
3. Login dengan akun baru
4. Username akan langsung muncul (karena registrasi baru sudah menggunakan field yang benar)

## Verifikasi

Setelah melakukan salah satu opsi di atas, verifikasi bahwa username sudah muncul:

1. **Restart aplikasi** (jangan pakai hot reload!)
   ```bash
   # Di terminal, tekan:
   R  # untuk Hot Restart
   # atau stop dan jalankan ulang:
   flutter run
   ```

2. **Login**

3. **Cek home page header**:
   - Seharusnya muncul: "Halo, [Nama]!"
   - Bukan lagi: "Halo, User!"

## Debug

Jika masih tidak berhasil, cek console logs:

```bash
# Di terminal Flutter, cari log seperti:
DEBUG: Auto-migrating user data for [UID]
DEBUG: FirestoreService.getUser() - Document data: {...}
DEBUG HomePage Header: Data: UserModel(...)
```

Jika ada error, screenshot dan laporkan.

## File-file yang Relevan

- [lib/utils/migrate_user_data.dart](lib/utils/migrate_user_data.dart) - Migration utility
- [lib/pages/migration_page.dart](lib/pages/migration_page.dart) - Migration UI page
- [lib/pages/home_page.dart](lib/pages/home_page.dart:57-73) - Auto-migration logic
- [lib/pages/registration_page.dart](lib/pages/registration_page.dart:108-119) - Fixed registration
- [lib/models/user_model.dart](lib/models/user_model.dart) - User model definition

## Catatan Penting

- **Jangan gunakan Hot Reload (r)** setelah migration! Selalu gunakan **Hot Restart (R)** atau restart aplikasi penuh
- Auto-migration hanya berjalan sekali per HomePage load
- Jika sudah di-migrate, migration akan skip (sudah up to date)
- Migration aman - tidak akan menghapus data lama, hanya menambah field baru
