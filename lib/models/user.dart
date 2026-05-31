class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isVerified;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    this.dateOfBirth,
    this.gender,
    required this.isVerified,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      isVerified: json['is_verified'] ?? false,
      roles: json['roles'] == null
          ? const []
          : List<String>.from(json['roles'].map((role) => role is String ? role : role['name'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'is_verified': isVerified,
      'roles': roles,
    };
  }
}

