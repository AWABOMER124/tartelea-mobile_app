import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _needsVerification = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('يرجى تعبئة البريد الإلكتروني وكلمة المرور.');
      return;
    }

    if (!_isLogin && fullName.length < 2) {
      _showMessage('يرجى إدخال الاسم الكامل كما سيظهر في الحساب.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(authRepositoryProvider).signIn(
              email: email,
              password: password,
            );
        ref.invalidate(authTokenProvider);
        ref.invalidate(profileProvider);
        if (mounted) {
          context.go('/');
        }
      } else {
        await ref.read(authRepositoryProvider).signUp(
              email: email,
              password: password,
              fullName: fullName,
            );
        if (mounted) {
          setState(() => _needsVerification = true);
          _showMessage('تم إرسال رمز التحقق إلى بريدك الإلكتروني.');
        }
      }
    } catch (error) {
      _handleAuthFailure(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyEmail() async {
    final code = _verificationCodeController.text.trim();
    if (code.length != 6) {
      _showMessage('أدخل رمز التحقق المكوّن من 6 أرقام.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).verifyEmail(
            email: _emailController.text.trim(),
            code: code,
          );
      ref.invalidate(authTokenProvider);
      ref.invalidate(profileProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      _handleAuthFailure(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.invalidate(authTokenProvider);
      ref.invalidate(profileProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      _handleAuthFailure(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleAuthFailure(Object error) {
    if (_requiresVerification(error) && mounted) {
      setState(() => _needsVerification = true);
    }
    _showMessage(_mappedErrorMessage(error));
  }

  String _mappedErrorMessage(Object error) {
    final code = _errorCode(error);
    final rawMessage = _backendMessage(error);

    switch (code) {
      case 'EMAIL_ALREADY_REGISTERED':
        return 'هذا البريد مسجل بالفعل.';
      case 'GOOGLE_SIGN_IN_REQUIRED':
        return 'هذا الحساب مرتبط بتسجيل الدخول عبر Google. استخدم زر Google للمتابعة.';
      case 'EMAIL_NOT_VERIFIED':
        return 'الحساب غير مفعّل بعد. أعدنا إرسال رمز التحقق إلى بريدك الإلكتروني.';
      case 'INVALID_CREDENTIALS':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'INVALID_VERIFICATION_CODE':
        return 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
      case 'EMAIL_NOT_FOUND':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
    }

    switch (rawMessage) {
      case 'Email already registered':
        return 'هذا البريد مسجل بالفعل.';
      case 'This email is already linked to Google sign-in. Please continue with Google.':
      case 'This account uses Google sign-in. Please continue with Google.':
        return 'هذا الحساب مرتبط بتسجيل الدخول عبر Google. استخدم زر Google للمتابعة.';
      case 'Please verify your email first. A new verification code has been sent.':
      case 'Please verify your email before resetting the password. A new verification code has been sent.':
        return 'الحساب غير مفعّل بعد. أعدنا إرسال رمز التحقق إلى بريدك الإلكتروني.';
      case 'Invalid email or password':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'Invalid or expired verification code':
        return 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
      case 'Email not found':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
    }

    return _errorMessage(error);
  }

  bool _requiresVerification(Object error) {
    final code = _errorCode(error);
    if (code == 'EMAIL_NOT_VERIFIED') {
      return true;
    }

    final message = _backendMessage(error);
    return message == 'Please verify your email first. A new verification code has been sent.' ||
        message == 'Please verify your email before resetting the password. A new verification code has been sent.';
  }

  String? _errorCode(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final directCode = data['code'];
        if (directCode != null) {
          return directCode.toString();
        }

        final nestedError = data['error'];
        if (nestedError is Map<String, dynamic> && nestedError['code'] != null) {
          return nestedError['code'].toString();
        }
      }
    }
    return null;
  }

  String? _backendMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error']?['message'])?.toString();
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error']?['message'] ?? 'تعذر إكمال الطلب.')
            .toString();
      }
      return error.message ?? 'تعذر إكمال الطلب.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _needsVerification = false;
      _verificationCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: _GlowOrb(
                size: 220,
                color: (isDark ? AppColors.darkPrimary : AppColors.accentSoft)
                    .withAlpha(70),
              ),
            ),
            Positioned(
              bottom: -110,
              right: -70,
              child: _GlowOrb(
                size: 260,
                color: AppColors.spiritualGreen.withAlpha(isDark ? 90 : 55),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildCard(context, isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.panelColor(isDark),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: AppColors.borderColor(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 34 : 14),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: _needsVerification
              ? _buildVerificationState(context, isDark)
              : _buildAuthForm(context, isDark),
        ),
      ),
    );
  }

  Widget _buildVerificationState(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(isDark, size: 92),
        const SizedBox(height: 24),
        Text(
          'تأكيد الحساب',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'أرسلنا رمز التحقق إلى ${_emailController.text.trim()} لإتمام إنشاء الحساب.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _verificationCodeController,
          label: 'رمز التحقق',
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyEmail,
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accentForeground(isDark),
                    ),
                  )
                : const Text('تفعيل الحساب'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _needsVerification = false;
                    _verificationCodeController.clear();
                    _isLogin = true;
                  }),
          child: Text(
            'العودة لتسجيل الدخول',
            style: TextStyle(color: AppColors.appBarForeground(isDark)),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.subtleFill(isDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.appBarForeground(isDark),
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildLogo(isDark),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'مرحباً بك مجدداً' : 'إنشاء حساب جديد',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLogin
              ? 'سجل دخولك للمتابعة إلى مكتبتك وغرفك الصوتية وورشك التعليمية.'
              : 'أنشئ حسابك بهوية المدرسة نفسها وابدأ رحلتك داخل المنصة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        if (!_isLogin) ...[
          _buildTextField(
            controller: _fullNameController,
            label: 'الاسم الكامل',
            icon: Icons.badge_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],
        _buildTextField(
          controller: _emailController,
          label: 'البريد الإلكتروني',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _passwordController,
          label: 'كلمة المرور',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isDark: isDark,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accentForeground(isDark),
                    ),
                  )
                : Text(_isLogin ? 'دخول' : 'تسجيل'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderColor(isDark))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'أو عبر',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.borderColor(isDark))),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: Icon(
              Icons.g_mobiledata_rounded,
              size: 28,
              color: AppColors.appBarForeground(isDark),
            ),
            label: Text(
              'تسجيل الدخول باستخدام Google',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: _isLoading ? null : _toggleMode,
          child: Text(
            _isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك',
            style: TextStyle(
              color: AppColors.appBarForeground(isDark),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark, {double size = 110}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.heroGradient(isDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 70 : 40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/images/logo.jpeg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary(isDark)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.appBarForeground(isDark)),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary(isDark),
                ),
              )
            : null,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
