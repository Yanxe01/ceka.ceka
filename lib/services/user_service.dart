import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'auth_exceptions.dart';

/// Combined service untuk menangani autentikasi dan data user
/// Service ini menggabungkan AuthService dan FirestoreService
class UserService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Mendapatkan current user dari Firebase Auth
  User? get currentUser => _authService.currentUser;

  /// Stream untuk mendengarkan perubahan status autentikasi
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Register user baru dengan Email dan Password
  /// Otomatis membuat dokumen user di Firestore
  ///
  /// Throws [AuthException] jika terjadi error
  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      // Register di Firebase Auth
      UserCredential userCredential =
          await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Simpan data user ke Firestore
      if (userCredential.user != null) {
        await _firestoreService.createUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          photoURL: userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } catch (e) {
      // Jika error saat membuat di Firestore, hapus user dari Auth
      if (e is AuthException && e.code == 'create-user-failed') {
        try {
          await _authService.deleteUser();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Login dengan Email dan Password
  ///
  /// Throws [AuthException] jika terjadi error
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _authService.loginWithEmailPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Reset Password
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> resetPassword({required String email}) async {
    await _authService.resetPassword(email: email);
  }

  /// Mendapatkan data user dari Firestore
  ///
  /// Returns null jika user tidak ditemukan
  /// Throws [AuthException] jika terjadi error
  Future<UserModel?> getUserData(String uid) async {
    return await _firestoreService.getUser(uid);
  }

  /// Mendapatkan data current user dari Firestore
  ///
  /// Returns null jika tidak ada user yang login atau data tidak ditemukan
  /// Throws [AuthException] jika terjadi error
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await _firestoreService.getUser(currentUser!.uid);
  }

  /// Stream untuk mendapatkan data current user secara real-time
  ///
  /// Returns null jika tidak ada user yang login
  Stream<UserModel?> getCurrentUserDataStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }
    return _firestoreService.getUserStream(currentUser!.uid);
  }

  /// Update profile user (Auth & Firestore)
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    if (currentUser == null) {
      throw AuthException(
        code: 'no-user',
        message: 'Tidak ada user yang login',
      );
    }

    // Update di Firebase Auth
    if (displayName != null) {
      await _authService.updateDisplayName(displayName);
    }

    // Update di Firestore
    await _firestoreService.updateUser(
      uid: currentUser!.uid,
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
    );
  }

  /// Update email user (Auth & Firestore)
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateEmail(String newEmail) async {
    if (currentUser == null) {
      throw AuthException(
        code: 'no-user',
        message: 'Tidak ada user yang login',
      );
    }

    // Update di Firebase Auth
    await _authService.updateEmail(newEmail);

    // Update di Firestore
    await _firestoreService.updateUserEmail(
      uid: currentUser!.uid,
      newEmail: newEmail,
    );
  }

  /// Update password user
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  /// Delete user (Auth & Firestore)
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw AuthException(
        code: 'no-user',
        message: 'Tidak ada user yang login',
      );
    }

    final uid = currentUser!.uid;

    // Hapus dari Firestore
    await _firestoreService.deleteUser(uid);

    // Hapus dari Firebase Auth
    await _authService.deleteUser();
  }

  /// Send email verification
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    return await _authService.isEmailVerified();
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    return await _firestoreService.userExists(uid);
  }

  /// Search users
  ///
  /// Throws [AuthException] jika terjadi error
  Future<List<UserModel>> searchUsers(String query) async {
    return await _firestoreService.searchUsers(query);
  }
}
