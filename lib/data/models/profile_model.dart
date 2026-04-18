class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? role;
  final String? country;
  final bool isVerified;
  final String status;
  final List<String> specialties;
  final Map<String, dynamic> socialLinks;
  final bool isPublicProfile;

  ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.role,
    this.country,
    this.isVerified = false,
    this.status = 'active',
    this.specialties = const [],
    this.socialLinks = const {},
    this.isPublicProfile = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String?,
      country: json['country'] as String?,
      isVerified: (json['is_verified'] ?? json['isVerified']) as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      specialties: (json['specialties'] as List?)?.map((e) => e as String).toList() ?? [],
      socialLinks: (json['social_links'] ?? json['socialLinks']) as Map<String, dynamic>? ?? {},
      isPublicProfile: (json['is_public_profile'] ?? json['isPublicProfile']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'role': role,
      'country': country,
      'is_verified': isVerified,
      'status': status,
      'specialties': specialties,
      'social_links': socialLinks,
      'is_public_profile': isPublicProfile,
    };
  }
}
