import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/models/content_library_models.dart';
import '../../data/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ContentRepository(api);
});

final contentCategoriesProvider = FutureProvider<List<ContentCategoryModel>>((ref) {
  return ref.watch(contentRepositoryProvider).getCategories();
});

final contentFeaturedProvider = FutureProvider<ContentFeaturedResponse?>((ref) {
  return ref.watch(contentRepositoryProvider).getFeatured();
});

final contentTracksProvider =
    FutureProvider.family<List<ContentTrackModel>, String?>((ref, categorySlug) {
  return ref.watch(contentRepositoryProvider).getTracks(categorySlug: categorySlug);
});

class LibraryItemsQuery {
  final String? categorySlug;
  final String? trackSlug;
  final String? contentType;
  final bool? featured;

  const LibraryItemsQuery({
    this.categorySlug,
    this.trackSlug,
    this.contentType,
    this.featured,
  });

  @override
  bool operator ==(Object other) {
    return other is LibraryItemsQuery &&
        other.categorySlug == categorySlug &&
        other.trackSlug == trackSlug &&
        other.contentType == contentType &&
        other.featured == featured;
  }

  @override
  int get hashCode => Object.hash(categorySlug, trackSlug, contentType, featured);
}

final libraryItemsProvider =
    FutureProvider.family<List<LibraryItemModel>, LibraryItemsQuery>((ref, query) {
  return ref.watch(contentRepositoryProvider).getLibraryItems(
        categorySlug: query.categorySlug,
        trackSlug: query.trackSlug,
        contentType: query.contentType,
        featured: query.featured,
      );
});

class ProgramsQuery {
  final String? categorySlug;
  final String? trackSlug;
  final bool? featured;

  const ProgramsQuery({
    this.categorySlug,
    this.trackSlug,
    this.featured,
  });

  @override
  bool operator ==(Object other) {
    return other is ProgramsQuery &&
        other.categorySlug == categorySlug &&
        other.trackSlug == trackSlug &&
        other.featured == featured;
  }

  @override
  int get hashCode => Object.hash(categorySlug, trackSlug, featured);
}

final programsProvider =
    FutureProvider.family<List<ProgramModel>, ProgramsQuery>((ref, query) {
  return ref.watch(contentRepositoryProvider).getPrograms(
        categorySlug: query.categorySlug,
        trackSlug: query.trackSlug,
        featured: query.featured,
      );
});

final programLessonsProvider =
    FutureProvider.family<List<ProgramLessonModel>, String>((ref, programId) {
  return ref.watch(contentRepositoryProvider).getProgramLessons(programId);
});
