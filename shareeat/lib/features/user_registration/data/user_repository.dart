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

  FirebaseStorage get storage => _storage;

  /// REGISTER NEW USER (AUTH + STORAGE + DATABASE)
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
      print("STEP 1: Creating Firebase Auth user...");
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;
      print("STEP 2: Auth created successfully: UID = $uid");

      print("STEP 3: Uploading profile image to Firebase Storage...");
      final imageUrl = await uploadProfileImage(uid, profileImageBytes);
      print("STEP 4: Profile image uploaded successfully: $imageUrl");

      final appUser = AppUser(
        uid: uid,
        fullName: fullName,
        username: username,
        email: email,
        contactNumber: contactNumber,
        gender: gender,
        profileImageUrl: imageUrl,
      );

      print("STEP 5: Saving user data to Realtime Database...");
      await _db.child("users/$uid").set(appUser.toMap());
      print("STEP 6: User data saved successfully!");

      return appUser;
    } catch (e) {
      print("🔥 ERROR during registration: $e");
      rethrow;
    }
  }

  /// LOGIN
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    print("LOGIN: Attempting login for $email");
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// RESET PASSWORD
  Future<void> resetPassword(String email) async {
    print("Sending password reset email to $email");
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// GET CURRENT USER PROFILE FROM REALTIME DB
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("No authenticated user found.");
      return null;
    }

    print("Fetching user profile for UID: ${user.uid}");
    final snapshot = await _db.child("users/${user.uid}").get();

    if (!snapshot.exists) {
      print("❌ User profile does NOT exist in Realtime Database.");
      return null;
    }

    print("User profile loaded successfully!");
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return AppUser.fromMap(data);
  }

  /// UPDATE USER PROFILE
  Future<void> updateUserProfile(AppUser user) async {
    print("Updating user profile: ${user.uid}");
    await _db.child("users/${user.uid}").update(user.toMap());
    print("User profile updated successfully!");
  }

  /// UPDATE PASSWORD
  Future<void> updatePassword(String newPassword) async {
    print("Updating password...");
    await _auth.currentUser!.updatePassword(newPassword);
    print("Password updated.");
  }

  /// FILE UPLOAD (PROFILE IMAGE)
  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    try {
      print("Uploading profile image for UID $uid...");
      final ref = _storage.ref().child("user_profiles/$uid/profile.jpg");

      // Optional metadata for debugging
      final metadata = SettableMetadata(contentType: "image/jpeg");

      await ref.putData(bytes, metadata);
      print("Image upload completed. Fetching Download URL...");

      final url = await ref.getDownloadURL();
      print("Download URL retrieved: $url");

      return url;
    } catch (e) {
      print("🔥 ERROR uploading image: $e");
      rethrow;
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    print("Signing out...");
    await _auth.signOut();
  }
}
