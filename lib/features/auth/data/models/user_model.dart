import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.userName,
    required super.email,
    required super.phoneNumber,
  });

factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] ?? 0,
    userName: json['userName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
  );
}
}