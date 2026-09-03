import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/models/media.dart';
import 'media_error.dart';
import 'pdf_media_view.dart';
import 'video_media_view.dart';

/// Renders a guide's media attachment according to its [MediaType].
/// Central dispatch point so screens stay agnostic of the concrete viewer.
class GuideMediaView extends StatelessWidget {
  const GuideMediaView({
    super.key,
    required this.type,
    required this.source,
  });

  final MediaType type;
  final String source;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MediaType.image:
        return _ImageView(source: source);
      case MediaType.video:
        return VideoMediaView(source: source);
      case MediaType.pdf:
        return PdfMediaView(source: source);
    }
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    Widget errorBuilder(BuildContext _, Object __, StackTrace? ___) =>
        const MediaErrorBox();

    final Widget image;
    switch (mediaSourceKind(source)) {
      case MediaSourceKind.asset:
        image = Image.asset(source, fit: BoxFit.cover, errorBuilder: errorBuilder);
      case MediaSourceKind.file:
        image = Image.file(
          File(source.replaceFirst('file:', '')),
          fit: BoxFit.cover,
          errorBuilder: errorBuilder,
        );
      case MediaSourceKind.network:
        image = Image.network(source, fit: BoxFit.cover, errorBuilder: errorBuilder);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }
}
