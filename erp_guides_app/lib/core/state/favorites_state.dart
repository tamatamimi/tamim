import 'package:flutter/foundation.dart';

import '../../data/repositories/guide_repository.dart';

/// Reactive holder for the set of favorited guide ids. Backed by SQLite through
/// [GuideRepository]; screens watch it to reflect changes instantly.
class FavoritesState extends ChangeNotifier {
  FavoritesState(this._repo);

  final GuideRepository _repo;
  Set<int> _ids = <int>{};

  Set<int> get ids => _ids;
  bool get isEmpty => _ids.isEmpty;
  bool isFavorite(int guideId) => _ids.contains(guideId);

  Future<void> load() async {
    _ids = await _repo.getFavoriteIds();
    notifyListeners();
  }

  Future<void> toggle(int guideId) async {
    final currentlyFavorite = _ids.contains(guideId);
    await _repo.setFavorite(guideId, !currentlyFavorite);
    if (currentlyFavorite) {
      _ids.remove(guideId);
    } else {
      _ids.add(guideId);
    }
    notifyListeners();
  }
}
