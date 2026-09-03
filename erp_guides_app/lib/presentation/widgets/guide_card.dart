import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/favorites_state.dart';
import '../../data/models/guide.dart';
import '../../data/models/media.dart';
import 'type_badge.dart';

class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.guide,
    required this.isArabic,
    required this.onTap,
  });

  final Guide guide;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TypeBadge(type: guide.type, isArabic: isArabic),
                  const Spacer(),
                  _FavoriteButton(guideId: guide.id),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                guide.title(isArabic),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                guide.summary(isArabic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    guide.updatedAt,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (guide.hasMedia) ...[
                    const Spacer(),
                    Icon(
                      guide.mediaType == MediaType.video
                          ? Icons.play_circle_outline
                          : guide.mediaType == MediaType.pdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact, reactive star toggle used on cards and lists.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.guideId});

  final int guideId;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesState>();
    final isFavorite = favorites.isFavorite(guideId);
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? const Color(0xFFB4690E) : null,
      ),
      onPressed: () => context.read<FavoritesState>().toggle(guideId),
    );
  }
}
