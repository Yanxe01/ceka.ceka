# Username Display Feature

## Overview
Fitur untuk menampilkan username pengguna di home page yang diambil dari data registrasi.

## Changes Made

### 1. Registration Page Fix
**File**: [lib/pages/registration_page.dart](lib/pages/registration_page.dart)

**Problem**:
- Field yang disimpan ke Firestore adalah `'name'` dan `'phone'`
- UserModel mengharapkan field `'displayName'` dan `'phoneNumber'`
- Mismatch ini menyebabkan username tidak terbaca

**Solution**:
```dart
// BEFORE (WRONG)
await FirebaseFirestore.instance
    .collection('users')
    .doc(credential.user!.uid)
    .set({
      'uid': credential.user!.uid,
      'name': _nameController.text.trim(),        // ❌ Wrong field name
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),      // ❌ Wrong field name
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

// AFTER (CORRECT)
await FirebaseFirestore.instance
    .collection('users')
    .doc(credential.user!.uid)
    .set({
      'uid': credential.user!.uid,
      'displayName': _nameController.text.trim(),  // ✅ Correct field name
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim(), // ✅ Correct field name
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
```

### 2. Home Page Username Display
**File**: [lib/pages/home_page.dart](lib/pages/home_page.dart)

**Improvements**:
1. ✅ Menampilkan loading state saat data masih diambil
2. ✅ Fallback ke email prefix jika displayName kosong
3. ✅ Debug logging untuk troubleshooting
4. ✅ Handling null dan empty string
5. ✅ Mengambil kata pertama dari nama (firstName)

**Code**:
```dart
child: StreamBuilder(
  stream: UserService().getCurrentUserDataStream(),
  builder: (context, snapshot) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text('Halo, User!', ...);
    }

    // Ambil displayName dari UserModel atau fallback ke email
    final userData = snapshot.data;
    String displayName = "User";

    if (userData != null) {
      if (userData.displayName != null && userData.displayName!.isNotEmpty) {
        displayName = userData.displayName!;
      } else {
        // Fallback ke email prefix jika displayName kosong
        displayName = userData.email.split('@')[0];
      }
    }

    // Ambil kata pertama dari nama
    final firstName = displayName.split(' ')[0];

    return Text('Halo, $firstName!', ...);
  }
)
```

## How It Works

### Data Flow:
```
1. User Registration
   └─> Input nama di RegistrationPage
       └─> Simpan ke Firebase Auth (displayName)
           └─> Simpan ke Firestore (displayName field)

2. User Login
   └─> Login berhasil
       └─> HomePage load
           └─> StreamBuilder listen ke UserService().getCurrentUserDataStream()
               └─> Firestore query users/{uid}
                   └─> Convert to UserModel
                       └─> Display firstName di header
```

### StreamBuilder Benefits:
- **Real-time updates**: Jika user update profile, langsung terlihat
- **Automatic refresh**: Tidak perlu manual refresh
- **Efficient**: Hanya re-render widget yang berubah

## Testing

### For New Users:
1. Register dengan nama baru (misalnya "John Doe")
2. Login
3. Header home page akan menampilkan: **"Halo, John!"**

### For Existing Users (dengan data lama):
Jika ada user yang terdaftar sebelum fix ini, mereka akan melihat:
- Email prefix sebagai fallback (misalnya email: john@gmail.com → "Halo, john!")

**To fix existing users**, update Firestore manually:
```javascript
// Firebase Console → Firestore Database
// Cari dokumen user lama, ubah field:
// - 'name' → 'displayName'
// - 'phone' → 'phoneNumber'
```

Atau buat migration script (optional).

## Debug Tips

Jika username tidak muncul, cek:

1. **Console logs**:
   ```
   DEBUG HomePage Header: ConnectionState: waiting
   DEBUG HomePage Header: HasData: true
   DEBUG HomePage Header: Data: UserModel(...)
   ```

2. **Firestore Console**:
   - Buka Firebase Console → Firestore Database
   - Cek collection `users`
   - Pastikan field `displayName` ada dan terisi

3. **UserModel**:
   - Cek [lib/models/user_model.dart](lib/models/user_model.dart)
   - Pastikan `fromMap` handle null displayName dengan benar

4. **UserService**:
   - Cek [lib/services/user_service.dart](lib/services/user_service.dart)
   - Method `getCurrentUserDataStream()` harus return stream yang valid

## Related Files

- [lib/pages/home_page.dart](lib/pages/home_page.dart) - Display username
- [lib/pages/registration_page.dart](lib/pages/registration_page.dart) - Save username on register
- [lib/models/user_model.dart](lib/models/user_model.dart) - User data model
- [lib/services/user_service.dart](lib/services/user_service.dart) - User data service
- [lib/services/firestore_service.dart](lib/services/firestore_service.dart) - Firestore operations

## Future Improvements

1. **Add avatar support**:
   ```dart
   child: userData?.photoURL != null
       ? CircleAvatar(backgroundImage: NetworkImage(userData!.photoURL!))
       : const Icon(Icons.person, ...)
   ```

2. **Add user profile edit**:
   - Allow users to update displayName
   - Use `UserService().updateProfile(displayName: newName)`

3. **Remove debug prints** for production:
   - Replace with proper logging framework
   - Or wrap with `kDebugMode` check
