import '../entities/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;

  AuthResult({required this.token, required this.user});
}

class SignUpResult {
  final String? token;
  final AppUser? user;
  final bool needsVerification;
  final bool emailVerificationPending;
  final String? message;

  SignUpResult({
    this.token,
    this.user,
    required this.needsVerification,
    required this.emailVerificationPending,
    this.message,
  });
}

abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<SignUpResult> signUp({required String email, required String password, String? fullName});
  Future<AuthResult> verifyEmail({required String email, required String code});
  Future<AuthResult> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> confirmPasswordReset({
    required String otp,
    required String newPassword,
  });
  Future<AppUser?> getCurrentUser();
  Future<bool> hasActiveSession();
  Stream<AppUser?> watchAuthState();
}
