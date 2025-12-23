// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'user_model.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  /// REGISTER NEW USER (AUTH + STORAGE + FIRESTORE)
  Future<AppUser> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String contactNumber,
    required String gender,
    required Uint8List profileImageBytes,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;

      final imageUrl = await uploadProfileImage(uid, profileImageBytes);

      final appUser = AppUser(
        uid: uid,
        fullName: fullName,
        username: username,
        email: email,
        contactNumber: contactNumber,
        gender: gender,
        profileImageUrl: imageUrl,
      );

      await _db.collection("users").doc(uid).set({
        ...appUser.toMap(),
        "role": "user", // default role
        "createdAt": FieldValue.serverTimestamp(),
      });


      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapRegisterError(e));
    } catch (e) {
      throw Exception("Registration failed. Please try again.");
    }
  }

  /// LOGIN (WITH USER-FRIENDLY ERRORS)
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapLoginError(e));
    } catch (_) {
      throw Exception("Login failed. Please try again.");
    }
  }

  /// RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// GET CURRENT USER PROFILE FROM FIRESTORE
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

    /// GET CURRENT USER ROLE (admin/user)
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return "user";

    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) return "user";

    final data = doc.data() as Map<String, dynamic>;
    return (data["role"] ?? "user").toString();
  }

  /// QUICK CHECK
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role.trim().toLowerCase() == "admin";
  }

  /// GET USER PROFILE BY UID (FOR DONOR INFO)
// Inside lib/features/user_registration/data/user_repository.dart

Future<AppUser?> getUserById(String uid) async {
  try {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      // Ensure your AppUser.fromMap handles the data correctly
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null; 
  } catch (e) {
    print("Error getting donor info: $e");
    return null;
  }
}

  /// UPDATE USER PROFILE
  Future<void> updateUserProfile(AppUser user) async {
    await _db.collection("users").doc(user.uid).update(user.toMap());
  }

  /// UPDATE PASSWORD
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  /// FILE UPLOAD (PROFILE IMAGE)
  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child("user_profiles/$uid/profile.jpg");
    final metadata = SettableMetadata(contentType: "image/jpeg");

    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  /// SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================
  // 🔐 FRIENDLY ERROR MAPPERS
  // ============================

  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Email not registered. Please sign up first.";

      case 'wrong-password':
        return "Incorrect password. Please try again.";

      case 'invalid-email':
        return "Invalid email format. Please check and try again.";

      case 'user-disabled':
        return "This account has been disabled. Please contact support.";

      case 'too-many-requests':
        return "Too many failed attempts. Please try again later.";

      default:
        return "Login failed. Please check your credentials.";
    }
  }

  String _mapRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "This email is already registered. Please log in.";

      case 'weak-password':
        return "Password is too weak. Please use at least 6 characters.";

      case 'invalid-email':
        return "Invalid email address.";

      default:
        return "Registration failed. Please try again.";
    }
  }
}