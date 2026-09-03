/// Kinds of media attachment a guide can carry (Phase 3).
enum MediaType { image, video, pdf }

extension MediaTypeX on MediaType {
  String get key => name;

  /// Parses a stored/JSON key; null/blank/unknown → null (no media).
  static MediaType? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final type in MediaType.values) {
      if (type.name == key) return type;
    }
    return null;
  }
}

/// Where a media file lives. Determines which loader the viewers use.
enum MediaSourceKind { asset, file, network }

MediaSourceKind mediaSourceKind(String source) {
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return MediaSourceKind.network;
  }
  if (source.startsWith('/') || source.startsWith('file:')) {
    return MediaSourceKind.file;
  }
  return MediaSourceKind.asset;
}
