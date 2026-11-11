// Pure-Dart story model. No Flutter imports on purpose, so it stays easy to
// test and reuse (e.g. in a future admin editor or a Cloud Function).
//
// Generate the (de)serialization code with:
//   dart run build_runner build --delete-conflicting-outputs
import 'package:json_annotation/json_annotation.dart';

part 'story_model.g.dart';

// ---------------------------------------------------------------------------
// Enums. Anything unknown in the JSON falls back to a safe default, so a typo
// or a newer story file never crashes an older viewer.
// ---------------------------------------------------------------------------

enum Frame { none, speech, pixelBox, card }

/// `overlay`: sits on top of the scene at an [Anchor].
/// `flow`: joins the scene's centered column, in the order written in JSON
/// (so "above" and "below" an image is just array order).
enum PlaceMode { overlay, flow }

enum Anchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum EnterType { none, fade, fadeUp }

// ---------------------------------------------------------------------------
// Story root
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class Story {
  const Story({
    required this.meta,
    required this.theme,
    required this.assets,
    required this.chapters,
    this.schemaVersion = 1,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  @JsonKey(defaultValue: 1)
  final int schemaVersion;
  final Meta meta;
  final StoryTheme theme;
  final Map<String, Asset> assets;
  final List<Chapter> chapters;
}

@JsonSerializable(createToJson: false)
class Meta {
  const Meta({this.title = '', this.cover, this.music});

  factory Meta.fromJson(Map<String, dynamic> json) => _$MetaFromJson(json);

  @JsonKey(defaultValue: '')
  final String title;
  final String? cover;
  final String? music;
}

// ---------------------------------------------------------------------------
// Theme: named text styles + font names
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class StoryTheme {
  const StoryTheme({this.fonts = const {}, this.styles = const {}});

  factory StoryTheme.fromJson(Map<String, dynamic> json) =>
      _$StoryThemeFromJson(json);

  /// Logical name -> font family declared in pubspec.yaml.
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> fonts;

  @JsonKey(defaultValue: <String, TextStyleDef>{})
  final Map<String, TextStyleDef> styles;
}

/// Every field is nullable so the same class works as a full style *and* as
/// a partial per-block override. Defaults are applied at render time.
@JsonSerializable(createToJson: false)
class TextStyleDef {
  const TextStyleDef({
    this.font,
    this.size,
    this.color,
    this.bg,
    this.weight,
    this.rotation,
    this.shadow,
    this.typewriter,
    this.frame,
  });

  factory TextStyleDef.fromJson(Map<String, dynamic> json) =>
      _$TextStyleDefFromJson(json);

  final String? font;
  final double? size;
  final String? color; // "#RRGGBB" or "#AARRGGBB"
  final String? bg;
  final int? weight; // 100..900
  final double? rotation; // degrees
  final bool? shadow;
  final bool? typewriter;
  @JsonKey(unknownEnumValue: Frame.none)
  final Frame? frame;

  /// Returns this style with any non-null field of [o] layered on top.
  TextStyleDef merge(TextStyleDef? o) => o == null
      ? this
      : TextStyleDef(
          font: o.font ?? font,
          size: o.size ?? size,
          color: o.color ?? color,
          bg: o.bg ?? bg,
          weight: o.weight ?? weight,
          rotation: o.rotation ?? rotation,
          shadow: o.shadow ?? shadow,
          typewriter: o.typewriter ?? typewriter,
          frame: o.frame ?? frame,
        );
}

// ---------------------------------------------------------------------------
// Assets: declared once, referenced by id everywhere else
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class Asset {
  const Asset({
    required this.type,
    required this.w,
    required this.h,
    required this.src,
    this.placeholder,
    this.focal = const [0.5, 0.5],
    this.durationMs,
    this.poster,
    this.muted = true,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

  /// "image" or "video"
  final String type;
  final int w;
  final int h;

  /// Variant name -> path. Images: thumb / web / full. Video: mp4 (later hls).
  final Map<String, String> src;

  /// BlurHash string shown instantly while the real image loads.
  final String? placeholder;

  /// Where the subject is, as 0..1 (x, y). Used when cropping with `cover`.
  @JsonKey(defaultValue: [0.5, 0.5])
  final List<double> focal;
  final int? durationMs;
  final String? poster;
  @JsonKey(defaultValue: true)
  final bool muted;

  double get aspect => w / h;
  bool get isVideo => type == 'video';
}

// ---------------------------------------------------------------------------
// Chapters and scenes
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.scenes,
    this.icon,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  final String id;
  final String title;
  final String? icon;
  final List<Scene> scenes;
}

@JsonSerializable(createToJson: false)
class Scene {
  const Scene({
    required this.id,
    this.height = 1.0,
    this.pin = false,
    this.dwell = 3000,
    this.transitionIn,
    this.background = const ColorBackground(),
    this.blocks = const [],
  });

  factory Scene.fromJson(Map<String, dynamic> json) => _$SceneFromJson(json);

  final String id;

  /// Scroll length in viewport heights. 1.0 = one screen tall.
  @JsonKey(defaultValue: 1.0)
  final double height;

  /// If true, the content holds still while scroll progress plays out.
  /// Needs height > 1.0 to have any room to scrub.
  @JsonKey(defaultValue: false)
  final bool pin;

  /// Auto-play: how long to linger on this scene, in milliseconds.
  @JsonKey(defaultValue: 3000)
  final int dwell;

  /// Parsed now, used when we do cross-scene transitions.
  final SceneTransition? transitionIn;

  @JsonKey(fromJson: Background.parse)
  final Background background;

  @JsonKey(fromJson: Block.parseList)
  final List<Block> blocks;
}

@JsonSerializable(createToJson: false)
class SceneTransition {
  const SceneTransition({this.type = 'cut', this.ms = 400});

  factory SceneTransition.fromJson(Map<String, dynamic> json) =>
      _$SceneTransitionFromJson(json);

  @JsonKey(defaultValue: 'cut')
  final String type;
  @JsonKey(defaultValue: 400)
  final int ms;
}

// ---------------------------------------------------------------------------
// Placement and entrance animation (shared by blocks)
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class Place {
  const Place({
    this.mode = PlaceMode.overlay,
    this.anchor = Anchor.center,
    this.margin = 0.06,
    this.widthFrac,
  });

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  @JsonKey(defaultValue: PlaceMode.overlay, unknownEnumValue: PlaceMode.overlay)
  final PlaceMode mode;
  @JsonKey(defaultValue: Anchor.center, unknownEnumValue: Anchor.center)
  final Anchor anchor;

  /// Distance from the edges, as a fraction of viewport width.
  @JsonKey(defaultValue: 0.06)
  final double margin;

  /// Width as a fraction of the available width (viewport for overlay,
  /// column for flow). Null = sensible default per block type.
  final double? widthFrac;
}

@JsonSerializable(createToJson: false)
class Enter {
  const Enter({this.type = EnterType.fade, this.at = const [0.4, 0.55]});

  factory Enter.fromJson(Map<String, dynamic> json) => _$EnterFromJson(json);

  @JsonKey(defaultValue: EnterType.fade, unknownEnumValue: EnterType.none)
  final EnterType type;

  /// [start, end] of scene progress (0..1) during which the entrance plays.
  /// For a normal scene of height 1.0, progress 0.5 means "scene exactly
  /// fills the screen". For a pinned scene, 0 = pin starts, 1 = pin ends.
  @JsonKey(defaultValue: [0.4, 0.55])
  final List<double> at;
}

// ---------------------------------------------------------------------------
// Blocks (sealed: the renderer's switch must handle every case)
// ---------------------------------------------------------------------------

sealed class Block {
  const Block();

  factory Block.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'image':
        return ImageBlock.fromJson(json);
      default:
        return const UnknownBlock(); // skipped at render time
    }
  }

  static List<Block> parseList(Object? json) => [
    for (final j in (json as List<dynamic>? ?? const []))
      Block.fromJson(j as Map<String, dynamic>),
  ];
}

@JsonSerializable(createToJson: false)
class TextBlock extends Block {
  const TextBlock({
    required this.text,
    this.style,
    this.place,
    this.enter,
    this.overrides,
  });

  factory TextBlock.fromJson(Map<String, dynamic> json) =>
      _$TextBlockFromJson(json);

  final String text;

  /// Name of an entry in theme.styles.
  final String? style;
  final Place? place;
  final Enter? enter;

  /// One-off tweaks layered on top of the named style.
  @JsonKey(name: 'override')
  final TextStyleDef? overrides;
}

@JsonSerializable(createToJson: false)
class ImageBlock extends Block {
  const ImageBlock({required this.asset, this.place, this.enter});

  factory ImageBlock.fromJson(Map<String, dynamic> json) =>
      _$ImageBlockFromJson(json);

  final String asset;
  final Place? place;
  final Enter? enter;
}

class UnknownBlock extends Block {
  const UnknownBlock();
}

// ---------------------------------------------------------------------------
// Backgrounds
// ---------------------------------------------------------------------------

sealed class Background {
  const Background();

  static Background parse(Object? json) {
    if (json is! Map<String, dynamic>) return const ColorBackground();
    switch (json['type']) {
      case 'image':
        return ImageBackground.fromJson(json);
      case 'color':
        return ColorBackground.fromJson(json);
      case 'video':
        return VideoBackground.fromJson(json);
      case 'map':
        return MapBackground.fromJson(json);
      default:
        return const UnknownBackground();
    }
  }
}

@JsonSerializable(createToJson: false)
class ImageBackground extends Background {
  const ImageBackground({
    required this.asset,
    this.fit = 'cover',
    this.motion = 'none',
  });

  factory ImageBackground.fromJson(Map<String, dynamic> json) =>
      _$ImageBackgroundFromJson(json);

  final String asset;

  /// "cover" or "contain"
  @JsonKey(defaultValue: 'cover')
  final String fit;

  /// "none" or "kenBurns" (slow zoom driven by scroll progress)
  @JsonKey(defaultValue: 'none')
  final String motion;
}

@JsonSerializable(createToJson: false)
class ColorBackground extends Background {
  const ColorBackground({this.value = '#000000'});

  factory ColorBackground.fromJson(Map<String, dynamic> json) =>
      _$ColorBackgroundFromJson(json);

  @JsonKey(defaultValue: '#000000')
  final String value;
}

@JsonSerializable(createToJson: false)
class VideoBackground extends Background {
  const VideoBackground({required this.asset});

  factory VideoBackground.fromJson(Map<String, dynamic> json) =>
      _$VideoBackgroundFromJson(json);

  final String asset;
}

@JsonSerializable(createToJson: false)
class MapBackground extends Background {
  const MapBackground({
    required this.from,
    required this.to,
    this.route = 'none',
    this.label,
  });

  factory MapBackground.fromJson(Map<String, dynamic> json) =>
      _$MapBackgroundFromJson(json);

  final MapPoint from;
  final MapPoint to;

  /// "none" or "dotted"
  @JsonKey(defaultValue: 'none')
  final String route;
  final String? label;
}

@JsonSerializable(createToJson: false)
class MapPoint {
  const MapPoint({required this.lat, required this.lng, this.zoom = 10});

  factory MapPoint.fromJson(Map<String, dynamic> json) =>
      _$MapPointFromJson(json);

  final double lat;
  final double lng;
  @JsonKey(defaultValue: 10.0)
  final double zoom;
}

class UnknownBackground extends Background {
  const UnknownBackground();
}
