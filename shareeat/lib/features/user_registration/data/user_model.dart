// lib/features/user_registration/data/user_model.dart

class AppUser {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String contactNumber;
  final String gender;
  final String profileImageUrl;

  // NEW
  final String role; // "user" or "admin"

  AppUser({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.contactNumber,
    required this.gender,
    required this.profileImageUrl,
    this.role = "user",
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'contactNumber': contactNumber,
        'gender': gender,
        'profileImageUrl': profileImageUrl,
        'role': role, // NEW
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        username: map['username']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        contactNumber: map['contactNumber']?.toString() ?? '',
        gender: map['gender']?.toString() ?? '',
        profileImageUrl: map['profileImageUrl']?.toString() ?? '',
        role: map['role']?.toString() ?? 'user', // NEW
      );
}