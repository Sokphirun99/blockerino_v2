import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Signed in with Google: ${userCredential.user?.displayName}');
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  // Link anonymous account with Google
  Future<UserCredential?> linkAnonymousWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the anonymous account with Google credentials
      final userCredential = await _auth.currentUser?.linkWithCredential(credential);
      debugPrint('Linked anonymous account with Google: ${userCredential?.user?.displayName}');
      return userCredential;
    } catch (e) {
      debugPrint('Error linking anonymous account with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('Signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  // Get user display name
  String? get displayName => _auth.currentUser?.displayName;

  // Get user email
  String? get email => _auth.currentUser?.email;

  // Get user photo URL
  String? get photoURL => _auth.currentUser?.photoURL;
}
