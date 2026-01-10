class ProfileModel {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String? email;
  final String? phone;
  final String? birthdate;
  final String? address;
  final String? bio;
  final String? gender;
  final String userType;
  final String? agencyName;
  final String? businessId;
  final String? services;
  final String? experienceLevel;
  final String? hourlyRate;
  final String? profilePicturePath;
  final String? idVerificationPath;
  final String createdAt;
  final String? updatedAt;

  ProfileModel({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.email,
    this.phone,
    this.birthdate,
    this.address,
    this.bio,
    this.gender,
    required this.userType,
    this.agencyName,
    this.businessId,
    this.services,
    this.experienceLevel,
    this.hourlyRate,
    this.profilePicturePath,
    this.idVerificationPath,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'birthdate': birthdate,
      'address': address,
      'bio': bio,
      'gender': gender,
      'user_type': userType,
      'agency_name': agencyName,
      'business_id': businessId,
      'services': services,
      'experience_level': experienceLevel,
      'hourly_rate': hourlyRate,
      'profile_picture_path': profilePicturePath,
      'id_verification_path': idVerificationPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      birthdate: map['birthdate'] as String?,
      address: map['address'] as String?,
      bio: map['bio'] as String?,
      gender: map['gender'] as String?,
      userType: map['user_type'] as String,
      agencyName: map['agency_name'] as String?,
      businessId: map['business_id'] as String?,
      services: map['services'] as String?,
      experienceLevel: map['experience_level'] as String?,
      hourlyRate: map['hourly_rate'] as String?,
      profilePicturePath: map['profile_picture_path'] as String?,
      idVerificationPath: map['id_verification_path'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
