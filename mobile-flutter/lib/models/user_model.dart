class UserModel {
  final String userId;
  final String name;
  final String email;
  final String emergencyContact;
  final String token;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.emergencyContact,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'emergencyContact': emergencyContact,
      'token': token,
    };
  }
}
