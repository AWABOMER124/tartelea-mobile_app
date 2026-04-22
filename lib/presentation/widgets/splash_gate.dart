import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';

class SplashGate extends StatefulWidget {
  final Widget child;
  final Duration holdDuration;
  final Duration fadeDuration;

  const SplashGate({
    super.key,
    required this.child,
    this.holdDuration = const Duration(milliseconds: 900),
    this.fadeDuration = const Duration(milliseconds: 550),
  });

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _fadeOut = false;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(widget.holdDuration);
    if (!mounted) return;

    setState(() => _fadeOut = true);
    await Future<void>.delayed(widget.fadeDuration);
    if (!mounted) return;
    setState(() => _removed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = AppColors.appBarForeground(isDark);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _fadeOut,
            child: AnimatedOpacity(
              opacity: _fadeOut ? 0 : 1,
              duration: widget.fadeDuration,
              curve: Curves.easeOutCubic,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.screenGradient(isDark),
                ),
                child: SafeArea(
                  child: Center(
                    child: AnimatedScale(
                      scale: _fadeOut ? 1.03 : 1.0,
                      duration: widget.fadeDuration,
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) => Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.panelColor(isDark),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: AppColors.borderColor(isDark),
                                  ),
                                ),
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  color: foreground,
                                  size: 44,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'المدرسة الترتيلية',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: foreground,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            'تجربة هادئة… ونتائج أعمق',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary(isDark),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

