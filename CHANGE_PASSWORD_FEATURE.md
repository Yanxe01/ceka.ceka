# Change Password Feature

## Overview
Fitur untuk mengubah password user melalui halaman Profile → Ubah Password.

## Features

### ✨ Fitur Utama:
1. **Re-authentication** - Validasi password lama sebelum update
2. **Password Validation** - Minimal 6 karakter
3. **Confirmation Check** - Memastikan password baru diketik dengan benar
4. **Security** - Password baru harus berbeda dari password lama
5. **User-Friendly UI** - Toggle visibility password, loading state, error handling

## Implementation

### 1. Change Password Page
**File**: [lib/pages/change_password_page.dart](lib/pages/change_password_page.dart)

**UI Components**:
- ✅ Info card dengan instruksi
- ✅ 3 input fields dengan toggle visibility:
  - Password Lama
  - Password Baru
  - Konfirmasi Password Baru
- ✅ Validasi real-time
- ✅ Loading indicator saat proses
- ✅ Success dialog setelah berhasil

**Validation Rules**:
```dart
Password Lama:
- Tidak boleh kosong
- Harus sesuai dengan password di Firebase

Password Baru:
- Tidak boleh kosong
- Minimal 6 karakter
- Harus berbeda dari password lama

Konfirmasi Password:
- Tidak boleh kosong
- Harus sama dengan password baru
```

### 2. Integration dengan Profile Page
**File**: [lib/pages/profile_page.dart](lib/pages/profile_page.dart:283-292)

Menu "Ubah Password" sudah terhubung dengan navigation ke ChangePasswordPage.

### 3. Firebase Auth Integration
**Service**: [lib/services/auth_service.dart](lib/services/auth_service.dart)

Menggunakan method `updatePassword()` dari UserService yang sudah ada.

## How It Works

### Flow Diagram:
```
1. User click "Ubah Password" di Profile
   ↓
2. Navigate ke ChangePasswordPage
   ↓
3. User input:
   - Password lama
   - Password baru
   - Konfirmasi password baru
   ↓
4. Validasi form (frontend)
   ↓
5. Re-authenticate dengan password lama
   ↓
6. Update password baru di Firebase Auth
   ↓
7. Show success dialog
   ↓
8. Back to Profile page
```

### Code Flow:
```dart
// 1. User submit form
_handleChangePassword()

// 2. Validate form
_formKey.currentState!.validate()

// 3. Check password match
if (_newPasswordController.text != _confirmPasswordController.text)

// 4. Re-authenticate
final credential = EmailAuthProvider.credential(
  email: user.email!,
  password: _currentPasswordController.text,
);
await user.reauthenticateWithCredential(credential);

// 5. Update password
await UserService().updatePassword(_newPasswordController.text);

// 6. Show success
showDialog(...)
```

## Error Handling

Fitur ini menangani berbagai error Firebase Auth:

| Error Code | User Message |
|------------|--------------|
| `wrong-password` | Password lama salah |
| `weak-password` | Password baru terlalu lemah |
| `requires-recent-login` | Sesi Anda sudah kadaluarsa. Silakan login ulang |
| Other | Terjadi kesalahan: [error message] |

## Security Features

1. **Re-authentication Required**
   - User harus input password lama yang benar
   - Mencegah perubahan password oleh orang lain yang pinjam device

2. **Password Strength**
   - Minimal 6 karakter
   - Enforced oleh Firebase Auth

3. **Different Password Check**
   - Password baru harus berbeda dari password lama
   - Mencegah user "update" dengan password yang sama

4. **Session Validation**
   - Jika sesi terlalu lama, user diminta login ulang
   - Keamanan tambahan untuk operasi sensitif

## UI/UX Features

### 1. Toggle Password Visibility
Semua field password memiliki icon eye untuk show/hide:
```dart
IconButton(
  icon: Icon(
    obscureText ? Icons.visibility_off : Icons.visibility,
  ),
  onPressed: onToggle,
)
```

### 2. Loading State
Button berubah menjadi loading indicator saat proses:
```dart
_isLoading
  ? CircularProgressIndicator()
  : Text('Ubah Password')
```

### 3. Success Dialog
Dialog dengan icon centang hijau dan pesan sukses:
- Informasi jelas: "Password Anda berhasil diubah"
- Action button: "OK" untuk kembali

### 4. Responsive Error Messages
Error ditampilkan di:
- **Form validation**: Error text di bawah field
- **Firebase error**: SnackBar merah di bawah

## Testing

### Test Case 1: Successful Password Change
```
1. Login dengan user existing
2. Go to Profile → Ubah Password
3. Input:
   - Password lama: [correct old password]
   - Password baru: "newpass123"
   - Konfirmasi: "newpass123"
4. Klik "Ubah Password"
5. Expected: Success dialog muncul
6. Klik "OK"
7. Expected: Kembali ke Profile page
```

### Test Case 2: Wrong Old Password
```
1. Input password lama yang salah
2. Expected: Error "Password lama salah"
```

### Test Case 3: Password Too Short
```
1. Input password baru: "abc"
2. Expected: Validation error "Password minimal 6 karakter"
```

### Test Case 4: Password Mismatch
```
1. Password baru: "newpass123"
2. Konfirmasi: "newpass456"
3. Expected: Error "Password tidak cocok"
```

### Test Case 5: Same as Old Password
```
1. Password lama: "oldpass123"
2. Password baru: "oldpass123"
3. Expected: Validation error "Password baru harus berbeda dengan password lama"
```

## Future Enhancements

1. **Password Strength Meter**
   - Visual indicator untuk strength password
   - Weak / Medium / Strong

2. **Password Requirements Display**
   - Show checklist:
     - ✓ Minimal 6 karakter
     - ✓ Ada huruf dan angka
     - ✓ Ada karakter spesial (optional)

3. **Forgot Password Integration**
   - Link to "Lupa password lama?"
   - Send reset email

4. **2FA (Two-Factor Authentication)**
   - Optional untuk security tambahan
   - Verify dengan SMS/Email code

## Related Files

- [lib/pages/change_password_page.dart](lib/pages/change_password_page.dart) - Main page
- [lib/pages/profile_page.dart](lib/pages/profile_page.dart) - Integration point
- [lib/services/auth_service.dart](lib/services/auth_service.dart) - Auth methods
- [lib/services/user_service.dart](lib/services/user_service.dart) - User management

## Notes

- ⚠️ **Important**: Setelah password berubah, user tetap login (tidak perlu login ulang)
- 🔒 **Security**: Re-authentication diperlukan untuk mencegah unauthorized password change
- 📱 **Platform**: Works on both Android & iOS
- 🎨 **Theme**: Mengikuti app theme (support dark mode dari ProfilePage)
