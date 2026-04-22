import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/theme/app_colors.dart';

class AppShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.subtleFill(isDark);
    final highlight =
        isDark ? Colors.white.withAlpha(34) : Colors.white.withAlpha(120);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.2 + (2.4 * t), 0),
              end: Alignment(-0.2 + (2.4 * t), 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;

  const AppSkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = AppRadius.control,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.subtleFill(isDark),
        borderRadius: borderRadius,
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final double height;

  const AppSkeletonCard({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(
            Theme.of(context).brightness == Brightness.dark,
          ),
          borderRadius: AppRadius.card,
        ),
      ),
    );
  }
}

