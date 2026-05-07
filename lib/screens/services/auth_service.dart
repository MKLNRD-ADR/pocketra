import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Firebase Auth instance — the main tool for login/signup
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  // Get the currently logged in user
  User? get currentUser => _auth.currentUser;

  // Stream that fires whenever login state changes
  // Used in main.dart to auto redirect
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SIGN UP — creates a new account
  // Takes email and password from the signup form
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException gives us readable error messages
      // Example: "email-already-in-use", "weak-password"
      throw e.message ?? 'Sign up failed';
    }
  }

  // LOGIN — checks email and password against Firebase
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Example errors: "user-not-found", "wrong-password"
      throw e.message ?? 'Login failed';
    }
  }

  // GOOGLE SIGN IN — OAuth login with Google account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Opens Google account picker
      final googleUser = await _googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) return null;

      // Get auth tokens from Google
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential using Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw 'Google sign in failed';
    }
  }

  // SIGN OUT — logs user out completely
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}