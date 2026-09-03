import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/state/favorites_state.dart';
import '../../data/models/guide.dart';
import '../../data/repositories/guide_repository.dart';
import '../widgets/type_badge.dart';

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);
    final theme = Theme.of(context);
    final isArabic = appState.isArabic;

    final favorites = context.watch<FavoritesState>();
    final isFavorite = favorites.isFavorite(guide.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title(isArabic)),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? s.t('removeFromFavorites')
                : s.t('addToFavorites'),
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? const Color(0xFFB4690E) : null,
            ),
            onPressed: () => context.read<FavoritesState>().toggle(guide.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TypeBadge(type: guide.type, isArabic: isArabic),
          const SizedBox(height: 12),
          Text(
            guide.title(isArabic),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${s.t('lastUpdated')}: ${guide.updatedAt}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          if (guide.imageAsset != null) ...[
            _GuideImage(path: guide.imageAsset!),
            const SizedBox(height: 16),
          ],
          MarkdownBody(
            data: guide.content(isArabic),
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              code: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              codeblockDecoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (guide.tags.isNotEmpty) ...[
            Text(s.t('tags'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guide.tags
                  .map((t) => Chip(label: Text(t)))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 24),
          _RelatedSection(guide: guide, isArabic: isArabic),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  const _GuideImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    // Supports both bundled assets and imported files (offline media).
    final isFile = path.startsWith('/') || path.startsWith('file:');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isFile
          ? Image.file(File(path), fit: BoxFit.cover)
          : Image.asset(path, fit: BoxFit.cover),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.guide, required this.isArabic});

  final Guide guide;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(isArabic);
    final repo = GuideRepository();
    return FutureBuilder<List<Guide>>(
      future: repo.getRelatedByType(guide.type, guide.id),
      builder: (context, snapshot) {
        final related = snapshot.data ?? const [];
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('relatedType'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...related.map(
              (g) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(g.type.icon),
                title: Text(g.title(isArabic)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideDetailScreen(guide: g),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
