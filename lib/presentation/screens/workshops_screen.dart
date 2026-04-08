import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/workshop_model.dart';
import '../providers/theme_provider.dart';
import '../providers/workshop_provider.dart';
import '../widgets/common_app_bar.dart';

class WorkshopsScreen extends ConsumerWidget {
  const WorkshopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final workshopsAsync = ref.watch(workshopsProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'الورش'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.panelColor(isDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderColor(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ورش المدرسة التعليمية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اطلع على الورش المجدولة والمباشرة داخل المنصة.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: workshopsAsync.when(
                data: (workshops) {
                  if (workshops.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد ورش متاحة حالياً',
                        style: TextStyle(color: AppColors.textSecondary(isDark)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    itemCount: workshops.length,
                    itemBuilder: (context, index) => _WorkshopCard(
                      workshop: workshops[index],
                      isDark: isDark,
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'خطأ: $err',
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  final WorkshopModel workshop;
  final bool isDark;

  const _WorkshopCard({
    required this.workshop,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleText = workshop.scheduledAt == null
        ? 'سيحدد لاحقاً'
        : DateFormat('yyyy/MM/dd - hh:mm a').format(workshop.scheduledAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  workshop.isLive ? 'مباشر' : 'مجدول',
                  style: TextStyle(
                    color: AppColors.appBarForeground(isDark),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${workshop.durationMinutes} دقيقة',
                style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workshop.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          if ((workshop.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              workshop.description!,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: AppColors.appBarForeground(isDark),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                ),
              ),
              Text(
                workshop.price > 0 ? '\$${workshop.price.toStringAsFixed(2)}' : 'مجاني',
                style: TextStyle(
                  color: AppColors.appBarForeground(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
