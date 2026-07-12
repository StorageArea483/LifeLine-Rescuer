import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Google Sign-In Service Class
class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;
  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '494066243537-svh0nrrt1iqh0tmp5fp2fa320mf55g7j.apps.googleusercontent.com',
      );
    }
    isInitialize = true;
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await initSignIn();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorizationClient = googleUser.authorizationClient;
      GoogleSignInClientAuthorization? authorization = await authorizationClient
          .authorizationForScopes(['email', 'profile']);
      final accessToken = authorization?.accessToken;
      if (accessToken == null) {
        final authorization2 = await authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        );
        if (authorization2?.accessToken == null) {
          throw FirebaseAuthException(code: "error", message: "error");
        }
        authorization = authorization2;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userSnapshot = await userDoc.get();
        if (!userSnapshot.exists) {
          await userDoc.set({
            'email': user.email ?? '',
            'photoURL': user.photoURL,
            'provider': 'google',
          }, SetOptions(merge: true));
        }
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
}
