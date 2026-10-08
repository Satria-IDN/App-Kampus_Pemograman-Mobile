class UserEntity {
  final String id;
  final String identifierId;
  final String name;
  final String role;
  final double? ipk;
  final int? sksTotal;

  UserEntity({
    required this.id,
    required this.identifierId,
    required this.name,
    required this.role,
    this.ipk,
    this.sksTotal,
  });
}