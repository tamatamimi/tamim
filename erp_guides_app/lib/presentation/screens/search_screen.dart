import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../data/models/guide.dart';
import '../../data/repositories/guide_repository.dart';
import '../widgets/guide_card.dart';
import 'guide_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GuideRepository _repo = GuideRepository();
  final TextEditingController _controller = TextEditingController();
  List<Guide> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String query) async {
    final results = await _repo.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: s.t('searchHint'),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
          ),
          onChanged: _run,
          onSubmitted: _run,
        ),
      ),
      body: !_searched
          ? _Hint(text: s.t('startTyping'), icon: Icons.search)
          : _results.isEmpty
              ? _Hint(text: s.t('noResults'), icon: Icons.search_off)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final guide = _results[index];
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
                ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
