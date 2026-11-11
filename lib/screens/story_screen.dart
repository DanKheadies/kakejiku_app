import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kakejiku_app/barrel.dart';

/// The long, continuous scroll. Requires Flutter 3.22+ (SliverVariedExtentList).
class StoryView extends StatefulWidget {
  const StoryView({
    super.key,
    required this.story,
    this.media = const MediaResolver(),
    this.controller,
  });

  final Story story;
  final MediaResolver media;

  /// Optional: pass your own controller (table of contents and auto-play
  /// will need one). If null, the widget owns its controller.
  final ScrollController? controller;

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  late final ScrollController _controller;
  late final bool _ownsController;
  StoryLayout? _layout;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        if (_layout == null ||
            _layout!.viewport != size ||
            _layout!.story != widget.story) {
          _layout = StoryLayout(widget.story, size);
        }
        final layout = _layout!;

        return ScrollConfiguration(
          // Let mouse and trackpad drag-scroll too (desktop, web, TV browsers).
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: CustomScrollView(
            controller: _controller,
            // Build (and therefore load) about 1.5 screens ahead and behind.
            // cacheExtent: size.height * 1.5,
            scrollCacheExtent: ScrollCacheExtent.viewport(size.height * 1.5),
            slivers: [
              SliverVariedExtentList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => SceneView(
                    story: widget.story,
                    flat: layout.scenes[i],
                    viewport: size,
                    controller: _controller,
                    media: widget.media,
                  ),
                  childCount: layout.scenes.length,
                  addAutomaticKeepAlives: false,
                ),
                itemExtentBuilder: (i, dimensions) => layout.scenes[i].height,
              ),
            ],
          ),
        );
      },
    );
  }
}
