import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/state/favorites_state.dart';
import '../../data/models/guide.dart';
import '../../data/repositories/guide_repository.dart';
import '../widgets/guide_card.dart';
import 'guide_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Watch favorites so removing an item here refreshes the list immediately.
    final favorites = context.watch<FavoritesState>();
    final s = AppStrings(appState.isArabic);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('favorites'))),
      body: favorites.isEmpty
          ? _Empty(text: s.t('noFavorites'))
          : FutureBuilder<List<Guide>>(
              future: GuideRepository().getFavoriteGuides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final guides = snapshot.data ?? const [];
                if (guides.isEmpty) return _Empty(text: s.t('noFavorites'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    final guide = guides[index];
                    return GuideCard(
                      guide: guide,
                      isArabic: appState.isArabic,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GuideDetailScreen(guide: guide),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
