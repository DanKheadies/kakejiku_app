import 'dart:ui' show Size;

import 'package:kakejiku_app/barrel.dart';

/// One scene with its position in the long scroll.
class FlatScene {
  const FlatScene({
    required this.index,
    required this.chapterIndex,
    required this.scene,
    required this.top,
    required this.height,
  });

  final int index;
  final int chapterIndex;
  final Scene scene;

  /// Scroll offset where this scene starts, in logical pixels.
  final double top;

  /// Scene height in logical pixels (scene.height * viewport height).
  final double height;

  double get bottom => top + height;
}

/// Because every scene's height is `scene.height * viewport.height`, all
/// offsets are known up front, with no layout pass needed. That one fact
/// gives us table-of-contents jumps, deep links, auto-play and
/// lazy-loading decisions almost for free.
class StoryLayout {
  StoryLayout(this.story, this.viewport) {
    var y = 0.0;
    var i = 0;
    for (var c = 0; c < story.chapters.length; c++) {
      _chapterStart.add(i);
      for (final s in story.chapters[c].scenes) {
        final h = s.height * viewport.height;
        scenes.add(
          FlatScene(index: i, chapterIndex: c, scene: s, top: y, height: h),
        );
        y += h;
        i++;
      }
    }
    totalExtent = y;
  }

  final Story story;
  final Size viewport;
  final List<FlatScene> scenes = [];
  final List<int> _chapterStart = [];
  late final double totalExtent;

  /// Scroll offset of a chapter's first scene (for the table of contents).
  double chapterOffset(int chapterIndex) {
    if (chapterIndex >= _chapterStart.length) return totalExtent;
    final first = _chapterStart[chapterIndex];
    return first < scenes.length ? scenes[first].top : totalExtent;
  }

  /// Index of the scene that contains [offset] (binary search).
  int sceneIndexAt(double offset) {
    if (scenes.isEmpty) return 0;
    var lo = 0;
    var hi = scenes.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (scenes[mid].top <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
