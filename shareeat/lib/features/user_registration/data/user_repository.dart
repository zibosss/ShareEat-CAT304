// lib/features/user_registration/data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_model.dart';

class UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Register new user (Auth + Firestore)
  Future<AppUser> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String contactNumber,
  }) async {
    // Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Profile in Firestore
    final appUser = AppUser(
      uid: uid,
      fullName: fullName,
      username: username,
      email: email,
      contactNumber: contactNumber,
    );

    await _firestore.collection('users').doc(uid).set(appUser.toMap());
    return appUser;
  }

  /// Login by email + password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
