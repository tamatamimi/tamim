import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/state/app_state.dart';
import 'package:provider/provider.dart';

/// Shared, calm error/placeholder box for any media that fails to load.
/// Keeps the guide readable even when its attachment is unavailable offline.
class MediaErrorBox extends StatelessWidget {
  const MediaErrorBox({super.key, this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings(context.watch<AppState>().isArabic);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.broken_image_outlined,
              size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(s.t('mediaError'),
              style: TextStyle(color: scheme.onSurfaceVariant)),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
