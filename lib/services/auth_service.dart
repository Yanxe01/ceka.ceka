import 'package:firebase_auth/firebase_auth.dart';
import 'auth_exceptions.dart';

/// Service untuk menangani autentikasi menggunakan Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mendapatkan current user
  User? get currentUser => _auth.currentUser;

  /// Stream untuk mendengarkan perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register dengan Email dan Password
  ///
  /// Throws [AuthException] jika terjadi error
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty) {
        throw AuthException(
          code: 'empty-email',
          message: 'Email tidak boleh kosong',
        );
      }

      if (password.isEmpty) {
        throw AuthException(
          code: 'empty-password',
          message: 'Password tidak boleh kosong',
        );
      }

      if (password.length < 6) {
        throw AuthException(
          code: 'weak-password',
          message: 'Password minimal 6 karakter',
        );
      }

      // Register user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name jika ada
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Login dengan Email dan Password
  ///
  /// Throws [AuthException] jika terjadi error
  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty) {
        throw AuthException(
          code: 'empty-email',
          message: 'Email tidak boleh kosong',
        );
      }

      if (password.isEmpty) {
        throw AuthException(
          code: 'empty-password',
          message: 'Password tidak boleh kosong',
        );
      }

      // Login user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Logout
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        code: 'logout-failed',
        message: 'Gagal logout: ${e.toString()}',
      );
    }
  }

  /// Reset Password (Kirim email reset password)
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> resetPassword({required String email}) async {
    try {
      if (email.isEmpty) {
        throw AuthException(
          code: 'empty-email',
          message: 'Email tidak boleh kosong',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Update Display Name
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      await user.updateDisplayName(displayName);
      await user.reload();
    } catch (e) {
      throw AuthException(
        code: 'update-failed',
        message: 'Gagal update display name: ${e.toString()}',
      );
    }
  }

  /// Update Email
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'update-failed',
        message: 'Gagal update email: ${e.toString()}',
      );
    }
  }

  /// Update Password
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      if (newPassword.length < 6) {
        throw AuthException(
          code: 'weak-password',
          message: 'Password minimal 6 karakter',
        );
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'update-failed',
        message: 'Gagal update password: ${e.toString()}',
      );
    }
  }

  /// Delete User
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> deleteUser() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'delete-failed',
        message: 'Gagal menghapus user: ${e.toString()}',
      );
    }
  }

  /// Send Email Verification
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> sendEmailVerification() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      if (user.emailVerified) {
        throw AuthException(
          code: 'already-verified',
          message: 'Email sudah diverifikasi',
        );
      }

      await user.sendEmailVerification();
    } catch (e) {
      throw AuthException(
        code: 'verification-failed',
        message: 'Gagal mengirim email verifikasi: ${e.toString()}',
      );
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    User? user = currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }
}
