import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/category.dart';
import '../../data/models/guide.dart';
import '../../data/repositories/guide_repository.dart';
import '../widgets/guide_card.dart';
import 'category_screen.dart';
import 'favorites_screen.dart';
import 'guide_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GuideRepository _repo = GuideRepository();
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final categories = await _repo.getCategories();
    final recent = await _repo.getRecentGuides();
    return _HomeData(categories, recent);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appTitle')),
        actions: [
          IconButton(
            tooltip: s.t('favorites'),
            icon: const Icon(Icons.star_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            tooltip: s.t('toggleTheme'),
            icon: Icon(appState.themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => context.read<AppState>().toggleTheme(),
          ),
          TextButton(
            onPressed: () => context.read<AppState>().toggleLanguage(),
            child: Text(s.t('toggleLanguage')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        icon: const Icon(Icons.search),
        label: Text(s.t('search')),
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(s.t('noResults')));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s.t('homeSubtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              _SectionTitle(s.t('categories')),
              const SizedBox(height: 8),
              _CategoryGrid(categories: data.categories, isArabic: appState.isArabic),
              const SizedBox(height: 24),
              _SectionTitle(s.t('recentGuides')),
              const SizedBox(height: 4),
              ...data.recent.map(
                (g) => GuideCard(
                  guide: g,
                  isArabic: appState.isArabic,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(guide: g),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _HomeData {
  _HomeData(this.categories, this.recent);
  final List<Category> categories;
  final List<Guide> recent;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.isArabic});

  final List<Category> categories;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 96,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final scheme = Theme.of(context).colorScheme;
        return Card(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryScreen(category: category),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(appIcon(category.icon),
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name(isArabic),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
