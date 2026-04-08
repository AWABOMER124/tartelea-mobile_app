import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_provider.dart';
import '../../data/models/content_model.dart';
import '../../core/theme/app_colors.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? initialSidebarCategory;
  const LibraryScreen({super.key, this.initialSidebarCategory});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _selectedSidebarCategory = null;
  
  final List<Map<String, String?>> _mediaTabs = [
    {'label': 'مرئي', 'value': 'video'},
    {'label': 'صوتي', 'value': 'audio'},
    {'label': 'مقالات', 'value': 'article'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mediaTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _mediaTabs.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('المكتبة الترتيلية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.white70,
            tabs: _mediaTabs.map((tab) => Tab(text: tab['label'])).toList(),
            onTap: (index) => setState(() {}),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.deepForest],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 120),
              Expanded(child: _buildContentList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentList() {
    final mediaType = _mediaTabs[_tabController.index]['value'];
    final contentsAsync = ref.watch(contentsProvider(_selectedSidebarCategory));

    return contentsAsync.when(
      data: (contents) {
        final filteredContents = contents.where((c) => c.type == mediaType).toList();
        
        if (filteredContents.isEmpty) {
          return const Center(child: Text('لا يوجد محتوى في هذا القسم حالياً', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredContents.length,
          itemBuilder: (context, index) => _ContentCard(content: filteredContents[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.white))),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentModel content;
  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(51)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: AppColors.secondary.withAlpha(51), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIconForType(content.type), color: AppColors.accent),
        ),
        title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(content.description ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_left, color: Colors.white54),
        onTap: () {},
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'audio': return Icons.headset_outlined;
      default: return Icons.article_outlined;
    }
  }
}
