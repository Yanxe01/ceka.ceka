/// Custom exception untuk authentication
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Helper class untuk mengkonversi Firebase error menjadi pesan yang user-friendly
class AuthExceptionHandler {
  static AuthException handleFirebaseAuthException(String code) {
    String message;

    switch (code) {
      // Register errors
      case 'email-already-in-use':
        message = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
        break;
      case 'invalid-email':
        message = 'Format email tidak valid.';
        break;
      case 'operation-not-allowed':
        message = 'Operasi tidak diizinkan. Hubungi administrator.';
        break;
      case 'weak-password':
        message = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
        break;

      // Login errors
      case 'user-disabled':
        message = 'Akun ini telah dinonaktifkan.';
        break;
      case 'user-not-found':
        message = 'Email tidak terdaftar. Silakan register terlebih dahulu.';
        break;
      case 'wrong-password':
        message = 'Password salah. Silakan coba lagi.';
        break;
      case 'invalid-credential':
        message = 'Email atau password salah.';
        break;

      // General errors
      case 'too-many-requests':
        message = 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
        break;
      case 'network-request-failed':
        message = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
        break;
      case 'requires-recent-login':
        message = 'Operasi sensitif memerlukan login ulang.';
        break;

      // Default
      default:
        message = 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return AuthException(code: code, message: message);
  }

  static AuthException handleFirestoreException(String code) {
    String message;

    switch (code) {
      case 'permission-denied':
        message = 'Anda tidak memiliki izin untuk operasi ini.';
        break;
      case 'not-found':
        message = 'Data tidak ditemukan.';
        break;
      case 'already-exists':
        message = 'Data sudah ada.';
        break;
      case 'unavailable':
        message = 'Layanan tidak tersedia. Coba lagi nanti.';
        break;
      default:
        message = 'Terjadi kesalahan pada database.';
    }

    return AuthException(code: code, message: message);
  }

  static String getGeneralExceptionMessage(Exception e) {
    if (e is AuthException) {
      return e.message;
    }
    return 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
  }
}
