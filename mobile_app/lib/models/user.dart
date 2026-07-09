class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'customer',
  });

  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: int.tryParse('${json['user_id'] ?? json['id'] ?? 0}') ?? 0,
        fullName: '${json['full_name'] ?? json['name'] ?? ''}',
        email: '${json['email'] ?? ''}',
        phone: json['phone']?.toString(),
        role: '${json['role'] ?? 'customer'}',
      );
}
