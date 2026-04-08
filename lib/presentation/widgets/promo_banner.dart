import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  final List<Map<String, String>> _banners = [
    {
      'title': 'دورة التجويد الجديدة',
      'subtitle': 'انضم الآن لإتقان تلاوة القرآن الكريم',
    },
    {
      'title': 'ورشة العمل القادمة',
      'subtitle': 'مناقشة حية حول التزكية والروحانية',
    },
    {
      'title': 'مكتبة ترتيل المتجددة',
      'subtitle': 'تصفح أحدث الكتب والمقالات الصوتية',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient(isDark),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (isDark ? AppColors.darkPrimary : AppColors.accentSoft)
                          .withAlpha(110),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 34 : 16),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -16,
                        bottom: -12,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 140,
                          color: Colors.white.withAlpha(24),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        right: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(28),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.black.withAlpha(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/logo.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              banner['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle']!,
                              style: TextStyle(
                                color: Colors.white.withAlpha(222),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withAlpha(46)),
                              ),
                              child: const Text(
                                'استكشف الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withAlpha(96),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
