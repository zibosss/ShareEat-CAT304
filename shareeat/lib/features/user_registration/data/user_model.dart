// lib/features/user_registration/data/app_user.dart

class AppUser {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String contactNumber;
  final String gender;
  final String profileImageUrl;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.contactNumber,
    required this.gender,
    required this.profileImageUrl,
  });

  /// Convert AppUser → Map (for Firestore)
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'contactNumber': contactNumber,
        'gender': gender,
        'profileImageUrl': profileImageUrl,
      };

  /// Convert Firestore Map → AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        username: map['username']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        contactNumber: map['contactNumber']?.toString() ?? '',
        gender: map['gender']?.toString() ?? '',
        profileImageUrl: map['profileImageUrl']?.toString() ?? '',
      );
}

// lib/features/user_registration/data/app_user.dart
class AppUser {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String contactNumber;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.contactNumber,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'contactNumber': contactNumber,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        fullName: map['fullName'] as String,
        username: map['username'] as String,
        email: map['email'] as String,
        contactNumber: map['contactNumber'] as String,
      );
}
