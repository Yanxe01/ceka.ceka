import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_exceptions.dart';

/// Service untuk menangani operasi Firestore terkait user
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nama collection untuk users
  static const String usersCollection = 'users';

  /// Membuat user baru di Firestore
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final userData = {
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      await _firestore.collection(usersCollection).doc(uid).set(userData);
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'create-user-failed',
        message: 'Gagal membuat user: ${e.toString()}',
      );
    }
  }

  /// Mendapatkan data user berdasarkan UID
  ///
  /// Returns null jika user tidak ditemukan
  /// Throws [AuthException] jika terjadi error
  Future<UserModel?> getUser(String uid) async {
    try {
      print("DEBUG: FirestoreService.getUser() - Fetching user data for uid: $uid");
      DocumentSnapshot doc =
          await _firestore.collection(usersCollection).doc(uid).get();

      if (!doc.exists) {
        print("DEBUG: FirestoreService.getUser() - Document not found for uid: $uid");
        return null;
      }

      print("DEBUG: FirestoreService.getUser() - Document found, parsing user data");
      print("DEBUG: FirestoreService.getUser() - Document data: ${doc.data()}");
      final user = UserModel.fromDocumentSnapshot(doc);
      print("DEBUG: FirestoreService.getUser() - Successfully parsed user: ${user.displayName} (${user.email})");
      return user;
    } on FirebaseException catch (e) {
      print("DEBUG: FirestoreService.getUser() - FirebaseException: ${e.code} - ${e.message}");
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      print("DEBUG: FirestoreService.getUser() - Exception: $e");
      print("DEBUG: FirestoreService.getUser() - Stack trace: $e");
      throw AuthException(
        code: 'get-user-failed',
        message: 'Gagal mendapatkan data user: ${e.toString()}',
      );
    }
  }

  /// Stream untuk mendapatkan data user secara real-time
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDocumentSnapshot(doc);
    });
  }

  /// Update data user
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateUser({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      await _firestore
          .collection(usersCollection)
          .doc(uid)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'update-user-failed',
        message: 'Gagal update user: ${e.toString()}',
      );
    }
  }

  /// Update email user di Firestore
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> updateUserEmail({
    required String uid,
    required String newEmail,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'update-email-failed',
        message: 'Gagal update email: ${e.toString()}',
      );
    }
  }

  /// Delete user dari Firestore
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'delete-user-failed',
        message: 'Gagal menghapus user: ${e.toString()}',
      );
    }
  }

  /// Check apakah user dengan UID tertentu ada
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Mendapatkan semua users (untuk admin)
  ///
  /// Throws [AuthException] jika terjadi error
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection(usersCollection).get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'get-users-failed',
        message: 'Gagal mendapatkan daftar user: ${e.toString()}',
      );
    }
  }

  /// Search users berdasarkan email atau display name
  ///
  /// Throws [AuthException] jika terjadi error
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final String searchQuery = query.toLowerCase();

      // Search by email
      QuerySnapshot emailSnapshot = await _firestore
          .collection(usersCollection)
          .where('email', isGreaterThanOrEqualTo: searchQuery)
          .where('email', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      // Search by display name
      QuerySnapshot nameSnapshot = await _firestore
          .collection(usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: searchQuery)
          .where('displayName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      // Combine results
      Set<String> userIds = {};
      List<UserModel> users = [];

      for (var doc in emailSnapshot.docs) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          users.add(UserModel.fromDocumentSnapshot(doc));
        }
      }

      for (var doc in nameSnapshot.docs) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          users.add(UserModel.fromDocumentSnapshot(doc));
        }
      }

      return users;
    } on FirebaseException catch (e) {
      throw AuthExceptionHandler.handleFirestoreException(e.code);
    } catch (e) {
      throw AuthException(
        code: 'search-users-failed',
        message: 'Gagal mencari user: ${e.toString()}',
      );
    }
  }
}
