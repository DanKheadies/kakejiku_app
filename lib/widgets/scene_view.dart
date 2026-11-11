import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kakejiku_app/barrel.dart';

extension AnchorAlignment on Anchor {
  Alignment get alignment => switch (this) {
    Anchor.topLeft => Alignment.topLeft,
    Anchor.topCenter => Alignment.topCenter,
    Anchor.topRight => Alignment.topRight,
    Anchor.centerLeft => Alignment.centerLeft,
    Anchor.center => Alignment.center,
    Anchor.centerRight => Alignment.centerRight,
    Anchor.bottomLeft => Alignment.bottomLeft,
    Anchor.bottomCenter => Alignment.bottomCenter,
    Anchor.bottomRight => Alignment.bottomRight,
  };
}

double _c01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// One scene. It listens to the scroll controller and derives a single
/// number, `t` (scene progress, 0..1). Everything animated (ken-burns zoom,
/// fades, typewriter, pinning) is just a function of `t`, which is why manual
/// scrolling and auto-play will behave identically later.
class SceneView extends StatelessWidget {
  const SceneView({
    super.key,
    required this.story,
    required this.flat,
    required this.viewport,
    required this.controller,
    required this.media,
  });

  final Story story;
  final FlatScene flat;
  final Size viewport;
  final ScrollController controller;
  final MediaResolver media;

  Scene get scene => flat.scene;

  /// Normal scene: 0 when it starts entering at the bottom, 1 when it has
  /// fully left at the top (0.5 = exactly filling the screen if height 1.0).
  /// Pinned scene: 0 when the pin starts, 1 when it ends.
  double _progress(double offset) {
    if (scene.pin) {
      final travel = flat.height - viewport.height;
      return travel <= 0 ? 0 : _c01((offset - flat.top) / travel);
    }
    return _c01(
      (offset + viewport.height - flat.top) / (flat.height + viewport.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentH = scene.pin ? viewport.height : flat.height;
    final maxPinShift = math.max(0.0, flat.height - viewport.height);

    // The background is passed as AnimatedBuilder's `child`, so it is NOT
    // rebuilt on every scroll tick, only re-transformed.
    final background = RepaintBoundary(
      child: BackgroundView(bg: scene.background, story: story, media: media),
    );

    return SizedBox(
      height: flat.height,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: controller,
          child: background,
          builder: (context, bg) {
            final offset = controller.hasClients ? controller.offset : 0.0;
            final t = _progress(offset);
            final dy = scene.pin
                ? (offset - flat.top).clamp(0.0, maxPinShift).toDouble()
                : 0.0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: SizedBox(
                width: viewport.width,
                height: contentH,
                child: ClipRect(child: _content(bg!, t)),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---- composition -------------------------------------------------------

  Widget _content(Widget bg, double t) {
    Widget background = bg;
    final b = scene.background;
    if (b is ImageBackground && b.motion == 'kenBurns') {
      background = Transform.scale(scale: 1 + 0.08 * t, child: bg);
    }

    final overlay = <Widget>[];
    final flow = <Widget>[];
    for (final block in scene.blocks) {
      final built = _buildBlock(block, t);
      if (built == null) continue;
      final place = _placeOf(block);
      if (place.mode == PlaceMode.overlay) {
        overlay.add(_overlay(place, built));
      } else {
        flow.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: built,
          ),
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        if (flow.isNotEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: viewport.width * 0.06),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(viewport.width * 0.88, 720),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: flow),
              ),
            ),
          ),
        ...overlay,
      ],
    );
  }

  Widget _overlay(Place p, Widget child) => Align(
    alignment: p.anchor.alignment,
    child: Padding(
      padding: EdgeInsets.all(p.margin * viewport.width),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: p.widthFrac != null
              ? p.widthFrac! * viewport.width
              : math.min(viewport.width * 0.8, 720),
        ),
        child: child,
      ),
    ),
  );

  Place _placeOf(Block b) => switch (b) {
    TextBlock() => b.place ?? const Place(),
    ImageBlock() => b.place ?? const Place(mode: PlaceMode.flow),
    UnknownBlock() => const Place(),
  };

  // ---- blocks ------------------------------------------------------------

  Widget? _buildBlock(Block b, double t) {
    switch (b) {
      case TextBlock():
        final base = story.theme.styles[b.style] ?? const TextStyleDef();
        final def = base.merge(b.overrides);
        final e = _enterProgress(b.enter, t);
        final typewriter = def.typewriter == true;
        final w = StyledText(
          text: b.text,
          def: def,
          fonts: story.theme.fonts,
          reveal: typewriter ? e : 1.0,
        );
        // Typewriter handles its own reveal; don't also fade it.
        return typewriter ? w : _applyEnter(b.enter, e, w);

      case ImageBlock():
        final asset = story.assets[b.asset];
        if (asset == null || asset.isVideo) {
          return _note('image: ${b.asset}');
        }
        final place = _placeOf(b);
        Widget img = AspectRatio(
          aspectRatio: asset.aspect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SmartImage(asset: asset, resolver: media),
          ),
        );
        img = place.mode == PlaceMode.flow
            ? FractionallySizedBox(
                widthFactor: place.widthFrac ?? 1.0,
                child: img,
              )
            : SizedBox(
                width: viewport.width * (place.widthFrac ?? 0.5),
                child: img,
              );
        return _applyEnter(b.enter, _enterProgress(b.enter, t), img);

      case UnknownBlock():
        return null;
    }
  }

  double _enterProgress(Enter? enter, double t) {
    if (enter == null || enter.type == EnterType.none) return 1;
    final a = enter.at.first;
    final b = enter.at.last;
    if (b <= a) return t >= a ? 1 : 0;
    return Curves.easeOut.transform(_c01((t - a) / (b - a)));
  }

  Widget _applyEnter(Enter? enter, double e, Widget child) =>
      switch (enter?.type ?? EnterType.none) {
        EnterType.none => child,
        EnterType.fade => Opacity(opacity: e, child: child),
        EnterType.fadeUp => Opacity(
          opacity: e,
          child: Transform.translate(
            offset: Offset(0, (1 - e) * 28),
            child: child,
          ),
        ),
      };

  Widget _note(String s) =>
      Text(s, style: const TextStyle(color: Color(0xFF888888), fontSize: 12));
}

/// Draws a scene's backdrop. Video and map are stubs until steps 6 and 7.
class BackgroundView extends StatelessWidget {
  const BackgroundView({
    super.key,
    required this.bg,
    required this.story,
    required this.media,
  });

  final Background bg;
  final Story story;
  final MediaResolver media;

  @override
  Widget build(BuildContext context) => switch (bg) {
    ImageBackground() => _image(bg as ImageBackground),
    ColorBackground() => ColoredBox(
      color: parseColor((bg as ColorBackground).value, Colors.black),
    ),
    VideoBackground() => _video(bg as VideoBackground),
    MapBackground() => _stub('map: ${(bg as MapBackground).label ?? ''}'),
    UnknownBackground() => const ColoredBox(color: Colors.black),
  };

  Widget _image(ImageBackground b) {
    final asset = story.assets[b.asset];
    if (asset == null) return _stub('missing asset: ${b.asset}');
    return ColoredBox(
      color: Colors.black,
      child: SmartImage(
        asset: asset,
        resolver: media,
        fit: b.fit == 'contain' ? BoxFit.contain : BoxFit.cover,
      ),
    );
  }

  Widget _video(VideoBackground b) {
    final asset = story.assets[b.asset];
    final poster = asset?.poster;
    if (poster == null) return _stub('video: ${b.asset}');
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: media.provider(poster), fit: BoxFit.cover),
        const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 72,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _stub(String label) => ColoredBox(
    color: const Color(0xFF14202B),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF8AA0B4), fontSize: 14),
      ),
    ),
  );
}
