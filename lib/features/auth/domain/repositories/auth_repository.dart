import '../entities/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;

  AuthResult({required this.token, required this.user});
}

abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password, String? fullName});
  Future<AuthResult> verifyEmail({required String email, required String code});
  Future<AuthResult> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<AppUser?> getCurrentUser();
  Future<bool> hasActiveSession();
  Stream<AppUser?> watchAuthState();
}
