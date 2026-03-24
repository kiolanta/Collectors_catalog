import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _updateUserLastLogin(credential.user!.uid);
        try {
          await _analytics.logLogin(loginMethod: 'password');
          await _analytics.logEvent(
            name: 'user_signed_in',
            parameters: {'uid': credential.user!.uid, 'method': 'password'},
          );
        } catch (_) {}
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserDocument(credential.user!);
        try {
          await _analytics.logSignUp(signUpMethod: 'password');
          await _analytics.logEvent(
            name: 'user_signed_up',
            parameters: {'uid': credential.user!.uid, 'method': 'password'},
          );
        } catch (_) {}
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithGoogle({
    bool forceAccountPicker = true,
  }) async {
    try {
      if (forceAccountPicker) {
        try {
          print('GoogleSignIn: attempting disconnect/signOut to force chooser');
          try {
            await _googleSignIn.disconnect();
            print('GoogleSignIn: disconnect successful');
          } catch (e) {
            print('GoogleSignIn.disconnect failed: $e; trying signOut');
            try {
              await _googleSignIn.signOut();
              print('GoogleSignIn: signOut successful');
            } catch (e2) {
              print('GoogleSignIn.signOut failed: $e2');
            }
          }
          await Future.delayed(const Duration(milliseconds: 350));
        } catch (e) {
          print('Error while trying to clear GoogleSignIn session: $e');
        }
      }
      final interactiveGoogleSignIn = GoogleSignIn(
        scopes: _googleSignIn.scopes,
        hostedDomain: null,
        clientId: null,
      );

      print('GoogleSignIn: calling signIn() on fresh instance');
      final GoogleSignInAccount? gUser = await interactiveGoogleSignIn.signIn();
      if (gUser == null) throw 'Google sign in aborted';

      print('GoogleSignIn selected account: ${gUser.email} (id: ${gUser.id})');

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {}

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
        try {
          await _analytics.logLogin(loginMethod: 'google');
          await _analytics.logEvent(
            name: 'user_signed_in',
            parameters: {'uid': userCredential.user!.uid, 'method': 'google'},
          );
        } catch (_) {}
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      try {
        await _analytics.logEvent(name: 'user_signed_out');
      } catch (_) {}
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      try {
        await _analytics.logEvent(
          name: 'password_reset_requested',
          parameters: {'email_provided': email.isNotEmpty},
        );
      } catch (_) {}
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        final userData = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        ).toMap();

        await userRef.set(userData);
      } else {
        await userRef.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLogin': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Update user's last login
  Future<void> _updateUserLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastLogin': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  Future<void> syncCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLogin': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing user profile: $e');
    }
  }

  Future<void> deleteCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _deleteQueryDocs(
        _firestore
            .collection('collection_items')
            .where('userId', isEqualTo: user.uid),
      );
      await _deleteQueryDocs(
        _firestore
            .collection('collections')
            .where('userId', isEqualTo: user.uid),
      );
      await _deleteQueryDocs(
        _firestore.collection('items').where('createdBy', isEqualTo: user.uid),
      );
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  Future<void> _deleteQueryDocs(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'This sign in method is not enabled.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        default:
          return 'The password or emailis incorrect. Please try again.';
      }
    }
    return e.toString();
  }
}
