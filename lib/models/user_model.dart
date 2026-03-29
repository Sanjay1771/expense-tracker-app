// User model for authentication
// Stores user credentials and profile data in sqflite

class UserModel {
  final int? id;
  final String email;
  final String passwordHash; // We store a hashed password, never plain text
  final String createdAt;

  UserModel({
    this.id,
    required this.email,
    required this.passwordHash,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Convert to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt,
    };
  }

  /// Create a UserModel from a database row
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
