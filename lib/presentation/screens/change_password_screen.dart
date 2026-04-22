import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/common_app_bar.dart';

enum _ChangePasswordStep {
  requestCode,
  confirmReset,
  done,
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ChangePasswordScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  _ChangePasswordStep _step = _ChangePasswordStep.requestCode;
  bool _requesting = false;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'تغيير كلمة المرور',
        showNotifications: false,
        showThemeToggle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: ListView(
          padding: AppSpacing.page,
          children: [
            if (_step == _ChangePasswordStep.done)
              AppEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'تم تحديث كلمة المرور',
                message: 'يمكنك استخدام كلمة المرور الجديدة لتسجيل الدخول في الأجهزة الأخرى.',
                actionLabel: 'رجوع',
                onAction: () => Navigator.of(context).pop(),
              )
            else ...[
              AppInlineBanner(
                icon: Icons.lock_reset_rounded,
                title: 'تغيير كلمة المرور',
                message: _step == _ChangePasswordStep.requestCode
                    ? 'سنرسل رمز تحقق إلى بريدك الإلكتروني لإعادة تعيين كلمة المرور.'
                    : 'أدخل رمز التحقق وكلمة المرور الجديدة.',
              ),
              const SizedBox(height: AppSpacing.s16),
              AppCard(
                usePanelColor: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      enabled: !_requesting && !_saving && _step == _ChangePasswordStep.requestCode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                      ),
                    ),
                    if (_step == _ChangePasswordStep.confirmReset) ...[
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: _otpController,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رمز التحقق (6 أرقام)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: _newPasswordController,
                        enabled: !_saving,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                          suffixIcon: IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (_step == _ChangePasswordStep.requestCode)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_requesting || _saving) ? null : _sendCode,
                    child: _requesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إرسال الرمز'),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _confirmReset,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ كلمة المرور'),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (_requesting || _saving) ? null : _sendCode,
                    child: const Text('إعادة إرسال الرمز'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('أدخل البريد الإلكتروني أولًا.');
      return;
    }

    setState(() => _requesting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (!mounted) return;

      setState(() => _step = _ChangePasswordStep.confirmReset);
      _showSnack('تم إرسال رمز التحقق (إن كان البريد صحيحًا).');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  Future<void> _confirmReset() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (otp.length != 6) {
      _showSnack('أدخل رمزًا مكونًا من 6 أرقام.');
      return;
    }
    if (newPassword.length < 6) {
      _showSnack('كلمة المرور يجب أن تكون 6 أحرف على الأقل.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            otp: otp,
            newPassword: newPassword,
          );
      if (!mounted) return;

      setState(() => _step = _ChangePasswordStep.done);
      _showSnack('تم تحديث كلمة المرور بنجاح.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

