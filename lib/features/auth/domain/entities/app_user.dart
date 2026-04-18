enum UserRole {
  member,
  trainer,
  moderator,
  admin,
}

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? country;
  final UserRole role;
  final List<String> interests;
  final bool isPublicProfile;
  final bool isSudanAwarenessMember;
  final bool isVerified;
  final String status;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? instagramUrl;
  final List<String> specialties;
  final List<String> services;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.country,
    required this.role,
    this.interests = const [],
    this.isPublicProfile = true,
    this.isSudanAwarenessMember = false,
    this.isVerified = false,
    this.status = 'active',
    this.facebookUrl,
    this.tiktokUrl,
    this.instagramUrl,
    this.specialties = const [],
    this.services = const [],
  });
}
