import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.identifierId,
    required super.name,
    required super.role,
    super.ipk,
    super.sksTotal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      identifierId: json['identifier_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      ipk: json['ipk'] != null ? double.tryParse(json['ipk'].toString()) : null,
      sksTotal: json['sks_total'] as int?,
    );
  }
}