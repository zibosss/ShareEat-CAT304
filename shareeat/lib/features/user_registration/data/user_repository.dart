// lib/features/user_registration/data/user_repository.dart

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'user_model.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Register new user (Auth + Realtime DB + Storage)
  Future<AppUser> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String contactNumber,
    required String gender,
    required Uint8List profileImageBytes,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCred.user!.uid;

    final storageRef = _storage.ref().child("user_profiles/$uid/profile.jpg");
    await storageRef.putData(profileImageBytes);
    final imageUrl = await storageRef.getDownloadURL();

    final appUser = AppUser(
      uid: uid,
      fullName: fullName,
      username: username,
      email: email,
      contactNumber: contactNumber,
      gender: gender,
      profileImageUrl: imageUrl,
    );

    await _db.child("users/$uid").set(appUser.toMap());
    return appUser;
  }

  /// Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// 🔥 RESET PASSWORD (NEW)
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Load current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _db.child("users/${user.uid}").get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return AppUser.fromMap(data);
  }

  /// Update DB only
  Future<void> updateUserProfile(AppUser user) async {
    await _db.child("users/${user.uid}").update(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
