import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/state/app_state.dart';
import 'core/state/favorites_state.dart';
import 'data/database/content_importer.dart';
import 'data/repositories/guide_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Import/refresh offline content from the versioned JSON asset.
  // Failure here must not block launch — the app still opens (possibly empty).
  try {
    await ContentImporter().importIfNeeded();
  } catch (error, stack) {
    debugPrint('Content import failed: $error\n$stack');
  }

  final repository = GuideRepository();
  final favorites = FavoritesState(repository);
  await favorites.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider<FavoritesState>.value(value: favorites),
      ],
      child: const ErpGuidesApp(),
    ),
  );
}
