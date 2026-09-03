import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../data/models/category.dart';
import '../../data/models/guide.dart';
import '../../data/repositories/guide_repository.dart';
import '../widgets/guide_card.dart';
import 'guide_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final GuideRepository _repo = GuideRepository();
  late Future<List<Guide>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getGuidesByCategory(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name(appState.isArabic))),
      body: FutureBuilder<List<Guide>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final guides = snapshot.data ?? const [];
          if (guides.isEmpty) {
            return Center(child: Text(s.t('noGuides')));
          }
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
