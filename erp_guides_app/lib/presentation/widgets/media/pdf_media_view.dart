import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../data/models/media.dart';
import 'media_error.dart';

/// Embedded PDF viewer for procedure/documentation attachments. Supports
/// asset and local-file sources (offline). Network PDFs are treated as
/// unavailable here to keep the app dependency-light and offline-first.
class PdfMediaView extends StatefulWidget {
  const PdfMediaView({super.key, required this.source, this.height = 480});

  final String source;
  final double height;

  @override
  State<PdfMediaView> createState() => _PdfMediaViewState();
}

class _PdfMediaViewState extends State<PdfMediaView> {
  PdfController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    try {
      final Future<PdfDocument> document;
      switch (mediaSourceKind(widget.source)) {
        case MediaSourceKind.asset:
          document = PdfDocument.openAsset(widget.source);
        case MediaSourceKind.file:
          document = PdfDocument.openFile(
            widget.source.replaceFirst('file:', ''),
          );
        case MediaSourceKind.network:
          throw UnsupportedError('Network PDF is not supported offline');
      }
      _controller = PdfController(document: document);
    } catch (error) {
      _error = error.toString();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null || _controller == null) {
      return MediaErrorBox(detail: _error);
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfView(
        controller: _controller!,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}
