import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/content_model.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? initialSidebarCategory;

  const LibraryScreen({super.key, this.initialSidebarCategory});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, String>> _mediaTabs = const [
    {'label': 'مرئي', 'value': 'video'},
    {'label': 'صوتي', 'value': 'audio'},
    {'label': 'مقالات', 'value': 'article'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mediaTabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة الترتيلية'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.darkPrimary : AppColors.accent,
          labelColor: AppColors.appBarForeground(isDark),
          unselectedLabelColor: AppColors.textSecondary(isDark),
          tabs: _mediaTabs.map((tab) => Tab(text: tab['label'])).toList(),
        ),
      ),
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
                      'محتوى المدرسة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر نوع المحتوى المناسب واستكشف المواد التعليمية المتاحة في المنصة.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildContentList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(bool isDark) {
    final mediaType = _mediaTabs[_tabController.index]['value'];
    final contentsAsync = ref.watch(contentsProvider(widget.initialSidebarCategory));

    return contentsAsync.when(
      data: (contents) {
        final filteredContents = contents.where((c) => c.type == mediaType).toList();

        if (filteredContents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'لا يوجد محتوى في هذا القسم حالياً',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          itemCount: filteredContents.length,
          itemBuilder: (context, index) => _ContentCard(
            content: filteredContents[index],
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
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentModel content;
  final bool isDark;

  const _ContentCard({
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.subtleFill(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getIconForType(content.type),
            color: AppColors.appBarForeground(isDark),
          ),
        ),
        title: Text(
          content.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            content.description ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_left_rounded,
          color: AppColors.appBarForeground(isDark),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'audio':
        return Icons.headset_rounded;
      default:
        return Icons.article_outlined;
    }
  }
}
