import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_payload.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final _authStateController = StreamController<AppUser?>.broadcast();
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        ApiConfig.googleServerClientId.isEmpty ? null : ApiConfig.googleServerClientId,
  );

  static const _tokenKey = 'auth_token';

  AuthRepositoryImpl(this._api);

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    final response = await _api.post(ApiConfig.login, data: {
      'email': _normalizeEmail(email),
      'password': password,
    });

    final payload = ApiPayload.unwrapObject(response.data);
    final token = _readAccessToken(payload);
    await _saveToken(token);

    final user = _mapResponseToUser(payload);
    _authStateController.add(user);

    return AuthResult(token: token, user: user);
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _api.post(ApiConfig.signup, data: {
      'email': _normalizeEmail(email),
      'password': password,
      'full_name': fullName,
    });

    final payload = ApiPayload.unwrapObject(response.data);
    final token = _readOptionalAccessToken(payload);
    final needsVerification = payload['needsVerification'] == true;
    final emailVerificationPending = payload['emailVerificationPending'] == true;
    final message = response.data['message']?.toString();

    AppUser? user;
    if (payload['user'] is Map<String, dynamic>) {
      user = _mapResponseToUser(payload);
    }

    if (token != null) {
      await _saveToken(token);
    }

    if (user != null) {
      _authStateController.add(user);
    }

    return SignUpResult(
      token: token,
      user: user,
      needsVerification: needsVerification,
      emailVerificationPending: emailVerificationPending,
      message: message,
    );
  }

  @override
  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _api.post(ApiConfig.verifyEmail, data: {
      'email': _normalizeEmail(email),
      'code': code,
    });

    final payload = ApiPayload.unwrapObject(response.data);
    final token = _readAccessToken(payload);
    await _saveToken(token);

    final user = _mapResponseToUser(payload);
    _authStateController.add(user);

    return AuthResult(token: token, user: user);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _resetGoogleSelection();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('تم إلغاء عملية تسجيل الدخول.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('تعذر الحصول على Google ID token.');
      }

      final response = await _api.post(ApiConfig.googleLogin, data: {
        'idToken': idToken,
      });

      final payload = ApiPayload.unwrapObject(response.data);
      final token = _readAccessToken(payload);
      await _saveToken(token);

      final user = _mapResponseToUser(payload);
      _authStateController.add(user);

      return AuthResult(token: token, user: user);
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_failed') {
        throw Exception(
          'Google Sign-In غير مهيأ لهذا البناء بعد. يلزم تسجيل com.tartelea.app مع بصمة SHA الصحيحة في Google Cloud.',
        );
      }

      throw Exception(error.message ?? 'تعذر تسجيل الدخول عبر Google.');
    }
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.setToken(null);

    final isGoogleSignedIn = await _googleSignIn.isSignedIn();
    if (isGoogleSignedIn) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google SDK sign-out failures and continue clearing local state.
      }

      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Ignore disconnect failures if the Google session was already cleared.
      }
    }

    _authStateController.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _api.post(ApiConfig.forgotPassword, data: {'email': _normalizeEmail(email)});
  }

  @override
  Future<void> confirmPasswordReset({
    required String otp,
    required String newPassword,
  }) async {
    await _api.post(ApiConfig.resetPassword, data: {
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final hasSession = await hasActiveSession();
    if (!hasSession) return null;

    try {
      final response = await _api.get('/auth/me');
      return _mapResponseToUser(
        ApiPayload.unwrapObject(response.data, preferredKeys: const ['user']),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await signOut();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  @override
  Stream<AppUser?> watchAuthState() => _authStateController.stream;

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.setToken(token);
  }

  Future<void> _resetGoogleSelection() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore cached-session cleanup failures before opening account chooser.
    }
  }

  static String _normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  AppUser _mapResponseToUser(Map<String, dynamic> json) {
    final userData = ApiPayload.unwrapObject(
      json,
      preferredKeys: const ['user'],
    );
    return AppUser(
      id: userData['id'] ?? '',
      fullName: userData['full_name'] ?? userData['fullName'],
      avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
      bio: userData['bio'],
      country: userData['country'],
      email: userData['email'],
      role: _parseRole(userData['role']),
      interests: _parseStringList(userData['interests']),
      isPublicProfile: userData['is_public_profile'] ?? userData['isPublicProfile'] ?? true,
      isSudanAwarenessMember: userData['is_sudan_awareness_member'] ?? false,
      isVerified: userData['is_verified'] ?? userData['isVerified'] ?? false,
      status: userData['status']?.toString() ?? 'active',
      facebookUrl: userData['facebook_url'],
      tiktokUrl: userData['tiktok_url'],
      instagramUrl: userData['instagram_url'],
      specialties: _parseStringList(userData['specialties']),
      services: _parseStringList(userData['services']),
    );
  }

  static UserRole _parseRole(String? role) {
    return switch (role) {
      'admin' => UserRole.admin,
      'moderator' => UserRole.moderator,
      'trainer' => UserRole.trainer,
      'member' => UserRole.member,
      'student' => UserRole.member,
      _ => UserRole.member,
    };
  }

  static String _readAccessToken(Map<String, dynamic> payload) {
    final token = _readOptionalAccessToken(payload);
    if (token == null || token.isEmpty) {
      throw Exception('تعذر العثور على access token صالح في استجابة الخادم.');
    }
    return token;
  }

  static String? _readOptionalAccessToken(Map<String, dynamic> payload) {
    final accessToken = payload['accessToken']?.toString();
    if (accessToken != null && accessToken.isNotEmpty) {
      return accessToken;
    }

    final legacyToken = payload['token']?.toString();
    if (legacyToken != null && legacyToken.isNotEmpty) {
      return legacyToken;
    }

    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
