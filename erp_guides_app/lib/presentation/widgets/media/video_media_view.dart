import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/media.dart';
import 'media_error.dart';

/// In-app video player for visual guides. Supports asset, local file, and
/// network sources; degrades to a calm error box if initialization fails.
class VideoMediaView extends StatefulWidget {
  const VideoMediaView({super.key, required this.source});

  final String source;

  @override
  State<VideoMediaView> createState() => _VideoMediaViewState();
}

class _VideoMediaViewState extends State<VideoMediaView> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = _controllerFor(widget.source);
      _video = controller;
      await controller.initialize();
      _chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
      );
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  VideoPlayerController _controllerFor(String source) {
    switch (mediaSourceKind(source)) {
      case MediaSourceKind.asset:
        return VideoPlayerController.asset(source);
      case MediaSourceKind.file:
        final path = source.replaceFirst('file:', '');
        return VideoPlayerController.file(File(path));
      case MediaSourceKind.network:
        return VideoPlayerController.networkUrl(Uri.parse(source));
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return MediaErrorBox(detail: _error);
    if (!_ready || _chewie == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _chewie!.aspectRatio ?? 16 / 9,
        child: Chewie(controller: _chewie!),
      ),
    );
  }
}
