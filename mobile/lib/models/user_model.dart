class UserModel {
  final String id;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String businessName;
  final String kycStatus;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.businessName,
    required this.kycStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      businessName: json['businessName'] ?? '',
      kycStatus: json['kycStatus'] ?? 'pending',
    );
  }

  String get fullName => '$firstName $lastName';
}
