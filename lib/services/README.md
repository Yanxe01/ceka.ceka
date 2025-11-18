# Firebase Services - CekaCeka

Dokumentasi lengkap untuk menggunakan Firebase Authentication dan Firestore di aplikasi CekaCeka.

## Setup

### 1. Konfigurasi Firebase

Edit file `lib/config/firebase_config.dart` dan ganti placeholder dengan konfigurasi Firebase Anda:

```dart
// Dapatkan konfigurasi dari Firebase Console > Project Settings > Your apps
static const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

### 2. Firestore Security Rules

Gunakan rules berikut di Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // User dapat membaca data mereka sendiri
      allow read: if request.auth != null && request.auth.uid == userId;

      // User dapat menulis data mereka sendiri
      allow write: if request.auth != null && request.auth.uid == userId;

      // Admin dapat membaca semua data
      // allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Penggunaan

### Import Service

```dart
import 'package:cekaceka/services/user_service.dart';
import 'package:cekaceka/services/auth_exceptions.dart';
import 'package:cekaceka/models/user_model.dart';
```

### 1. Register User Baru

```dart
final UserService _userService = UserService();

Future<void> registerUser() async {
  try {
    final userCredential = await _userService.register(
      email: 'user@example.com',
      password: 'password123',
      displayName: 'John Doe',
      phoneNumber: '+628123456789',
    );

    print('Register berhasil: ${userCredential.user?.email}');

    // Redirect ke home page atau dashboard
  } on AuthException catch (e) {
    print('Error: ${e.message}');
    // Tampilkan error ke user
  }
}
```

### 2. Login User

```dart
final UserService _userService = UserService();

Future<void> loginUser() async {
  try {
    final userCredential = await _userService.login(
      email: 'user@example.com',
      password: 'password123',
    );

    print('Login berhasil: ${userCredential.user?.email}');

    // Redirect ke home page atau dashboard
  } on AuthException catch (e) {
    print('Error: ${e.message}');
    // Tampilkan error ke user
  }
}
```

### 3. Logout

```dart
final UserService _userService = UserService();

Future<void> logoutUser() async {
  try {
    await _userService.logout();
    print('Logout berhasil');

    // Redirect ke login page
  } on AuthException catch (e) {
    print('Error: ${e.message}');
  }
}
```

### 4. Get Current User Data

```dart
final UserService _userService = UserService();

Future<void> getCurrentUser() async {
  try {
    final userData = await _userService.getCurrentUserData();

    if (userData != null) {
      print('User: ${userData.displayName}');
      print('Email: ${userData.email}');
      print('Phone: ${userData.phoneNumber}');
    } else {
      print('User tidak ditemukan');
    }
  } on AuthException catch (e) {
    print('Error: ${e.message}');
  }
}
```

### 5. Listen to User Data (Real-time)

```dart
final UserService _userService = UserService();

StreamBuilder<UserModel?> buildUserProfile() {
  return StreamBuilder<UserModel?>(
    stream: _userService.getCurrentUserDataStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      final userData = snapshot.data;
      if (userData == null) {
        return Text('User tidak ditemukan');
      }

      return Column(
        children: [
          Text('Name: ${userData.displayName ?? "N/A"}'),
          Text('Email: ${userData.email}'),
          Text('Phone: ${userData.phoneNumber ?? "N/A"}'),
        ],
      );
    },
  );
}
```

### 6. Update Profile

```dart
final UserService _userService = UserService();

Future<void> updateUserProfile() async {
  try {
    await _userService.updateProfile(
      displayName: 'Jane Doe',
      phoneNumber: '+628987654321',
    );

    print('Profile berhasil diupdate');
  } on AuthException catch (e) {
    print('Error: ${e.message}');
  }
}
```

### 7. Reset Password

```dart
final UserService _userService = UserService();

Future<void> resetUserPassword() async {
  try {
    await _userService.resetPassword(
      email: 'user@example.com',
    );

    print('Email reset password telah dikirim');
  } on AuthException catch (e) {
    print('Error: ${e.message}');
  }
}
```

### 8. Check Authentication State

```dart
final UserService _userService = UserService();

Widget buildAuthChecker() {
  return StreamBuilder<User?>(
    stream: _userService.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      if (snapshot.hasData) {
        // User sudah login
        return HomePage();
      } else {
        // User belum login
        return LoginPage();
      }
    },
  );
}
```

## Contoh Implementasi di Login Page

```dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_exceptions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

## Error Handling

Semua method di `UserService` akan throw `AuthException` jika terjadi error. Gunakan try-catch untuk menangani error:

```dart
try {
  await _userService.login(email: email, password: password);
} on AuthException catch (e) {
  // Handle error
  print('Error Code: ${e.code}');
  print('Error Message: ${e.message}');
}
```

## Pesan Error yang Umum

- `email-already-in-use`: Email sudah terdaftar
- `invalid-email`: Format email tidak valid
- `weak-password`: Password terlalu lemah
- `user-not-found`: Email tidak terdaftar
- `wrong-password`: Password salah
- `invalid-credential`: Email atau password salah
- `too-many-requests`: Terlalu banyak percobaan
- `network-request-failed`: Tidak ada koneksi internet

## Tips

1. Selalu gunakan try-catch saat memanggil method dari UserService
2. Tampilkan loading indicator saat melakukan operasi async
3. Validasi input sebelum mengirim ke Firebase
4. Gunakan StreamBuilder untuk mendengarkan perubahan authentication state
5. Jangan lupa dispose TextEditingController di dispose method
