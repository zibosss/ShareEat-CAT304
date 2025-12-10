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

  /// Convert object → Map for saving into Realtime Database
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'contactNumber': contactNumber,
        'gender': gender,
        'profileImageUrl': profileImageUrl,
      };

  /// Convert Map → AppUser object for loading from Realtime Database
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
