import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_exceptions.dart';

/// Service untuk menangani Google Sign In
class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  ///
  /// Returns [UserCredential] jika berhasil
  /// Throws [AuthException] jika terjadi error atau user cancel
  Future<UserCredential> signInWithGoogle() async {
    try {
      print("DEBUG: Starting Google Sign In...");

      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        print("DEBUG: User cancelled Google Sign In");
        throw AuthException(
          code: 'sign-in-cancelled',
          message: 'Sign in dibatalkan',
        );
      }

      print("DEBUG: Google user selected: ${googleUser.email}");

      // Obtain auth details from Google Sign In
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("DEBUG: Got Google auth token");

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("DEBUG: Created Firebase credential");

      // Sign in to Firebase with Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print("DEBUG: Signed in to Firebase: ${userCredential.user?.email}");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Firebase Auth Exception: ${e.code} - ${e.message}");
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      print("DEBUG: Google Sign In error: $e");
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        code: 'google-sign-in-failed',
        message: 'Gagal sign in dengan Google: ${e.toString()}',
      );
    }
  }

  /// Link Google account to current user
  ///
  /// Throws [AuthException] jika terjadi error
  Future<UserCredential> linkWithGoogle() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      print("DEBUG: Linking Google account for user: ${user.email}");

      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        print("DEBUG: User cancelled linking");
        throw AuthException(
          code: 'sign-in-cancelled',
          message: 'Linking dibatalkan',
        );
      }

      print("DEBUG: Selected Google account: ${googleUser.email}");

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link credential to current user
      final UserCredential userCredential =
          await user.linkWithCredential(credential);

      print("DEBUG: Successfully linked Google account");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Link error: ${e.code} - ${e.message}");

      // Handle specific linking errors
      if (e.code == 'provider-already-linked') {
        throw AuthException(
          code: 'provider-already-linked',
          message: 'Akun Google sudah terhubung',
        );
      } else if (e.code == 'credential-already-in-use') {
        throw AuthException(
          code: 'credential-already-in-use',
          message: 'Akun Google ini sudah digunakan oleh user lain',
        );
      }
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      print("DEBUG: Link error: $e");
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        code: 'link-failed',
        message: 'Gagal menghubungkan akun Google: ${e.toString()}',
      );
    }
  }

  /// Unlink Google account from current user
  ///
  /// Throws [AuthException] jika terjadi error
  Future<void> unlinkGoogle() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw AuthException(
          code: 'no-user',
          message: 'Tidak ada user yang login',
        );
      }

      print("DEBUG: Unlinking Google account for user: ${user.email}");

      // Check if Google provider is linked
      bool isGoogleLinked = user.providerData
          .any((info) => info.providerId == 'google.com');

      if (!isGoogleLinked) {
        throw AuthException(
          code: 'provider-not-linked',
          message: 'Akun Google tidak terhubung',
        );
      }

      // Unlink Google provider
      await user.unlink('google.com');

      // Sign out from Google
      await _googleSignIn.signOut();

      print("DEBUG: Successfully unlinked Google account");
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Unlink error: ${e.code} - ${e.message}");
      throw AuthExceptionHandler.handleFirebaseAuthException(e.code);
    } catch (e) {
      print("DEBUG: Unlink error: $e");
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        code: 'unlink-failed',
        message: 'Gagal memutuskan hubungan akun Google: ${e.toString()}',
      );
    }
  }

  /// Check if Google account is linked
  bool isGoogleLinked() {
    User? user = currentUser;
    if (user == null) return false;

    bool linked = user.providerData
        .any((info) => info.providerId == 'google.com');

    print("DEBUG: Is Google linked: $linked");
    return linked;
  }

  /// Get linked Google email
  String? getLinkedGoogleEmail() {
    User? user = currentUser;
    if (user == null) return null;

    final googleProvider = user.providerData
        .firstWhere(
          (info) => info.providerId == 'google.com',
          orElse: () => throw Exception('Not linked'),
        );

    return googleProvider.email;
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    print("DEBUG: Signing out from Google and Firebase");
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
