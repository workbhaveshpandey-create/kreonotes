import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';

/// Authentication Repository for Kreo Notes
/// Handles Google Sign-In and user data management in Firestore
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to get user after sign-in');
      }

      final userModel = await _createOrUpdateUser(firebaseUser);
      return userModel;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Create or update user document in Firestore
  Future<UserModel> _createOrUpdateUser(User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      await userDoc.update({
        'lastLoginAt': Timestamp.now(),
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
      });
      return UserModel.fromFirestore(await userDoc.get());
    } else {
      final newUser = UserModel.fromFirebaseUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
      await userDoc.set(newUser.toFirestore());

      // Create default workspace for new user
      await _createDefaultWorkspace(firebaseUser.uid);

      return newUser;
    }
  }

  /// Create a default workspace for new users
  Future<void> _createDefaultWorkspace(String userId) async {
    final pageRef = _firestore.collection('pages').doc();
    await pageRef.set({
      'userId': userId,
      'title': 'Welcome to Kreo Notes',
      'icon': '👋',
      'coverUrl': null,
      'parentId': null,
      'blocks': [
        {
          'id': 'block_1',
          'type': 'heading',
          'content': 'Getting Started',
          'level': 1,
        },
        {
          'id': 'block_2',
          'type': 'text',
          'content': 'Welcome to Kreo Notes! Start writing your notes here.',
        },
      ],
      'isFavorite': true,
      'isArchived': false,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Silently sign in (for app restart)
  Future<UserModel?> silentSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();

      if (googleUser == null) {
        if (currentUser != null) {
          return getCurrentUserData();
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return getCurrentUserData();
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  /// Delete user account and all their data
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Delete user's pages
    final pages = await _firestore
        .collection('pages')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final page in pages.docs) {
      await page.reference.delete();
    }

    // Delete user document
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete Firebase Auth account
    await user.delete();

    // Sign out from Google
    await _googleSignIn.signOut();
  }
}
