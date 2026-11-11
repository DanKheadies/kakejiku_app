// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
  meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
  theme: StoryTheme.fromJson(json['theme'] as Map<String, dynamic>),
  assets: (json['assets'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, Asset.fromJson(e as Map<String, dynamic>)),
  ),
  chapters: (json['chapters'] as List<dynamic>)
      .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList(),
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
);

Meta _$MetaFromJson(Map<String, dynamic> json) => Meta(
  title: json['title'] as String? ?? '',
  cover: json['cover'] as String?,
  music: json['music'] as String?,
);

StoryTheme _$StoryThemeFromJson(Map<String, dynamic> json) => StoryTheme(
  fonts:
      (json['fonts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      {},
  styles:
      (json['styles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, TextStyleDef.fromJson(e as Map<String, dynamic>)),
      ) ??
      {},
);

TextStyleDef _$TextStyleDefFromJson(Map<String, dynamic> json) => TextStyleDef(
  font: json['font'] as String?,
  size: (json['size'] as num?)?.toDouble(),
  color: json['color'] as String?,
  bg: json['bg'] as String?,
  weight: (json['weight'] as num?)?.toInt(),
  rotation: (json['rotation'] as num?)?.toDouble(),
  shadow: json['shadow'] as bool?,
  typewriter: json['typewriter'] as bool?,
  frame: $enumDecodeNullable(
    _$FrameEnumMap,
    json['frame'],
    unknownValue: Frame.none,
  ),
);

const _$FrameEnumMap = {
  Frame.none: 'none',
  Frame.speech: 'speech',
  Frame.pixelBox: 'pixelBox',
  Frame.card: 'card',
};

Asset _$AssetFromJson(Map<String, dynamic> json) => Asset(
  type: json['type'] as String,
  w: (json['w'] as num).toInt(),
  h: (json['h'] as num).toInt(),
  src: Map<String, String>.from(json['src'] as Map),
  placeholder: json['placeholder'] as String?,
  focal:
      (json['focal'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      [0.5, 0.5],
  durationMs: (json['durationMs'] as num?)?.toInt(),
  poster: json['poster'] as String?,
  muted: json['muted'] as bool? ?? true,
);

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: json['id'] as String,
  title: json['title'] as String,
  scenes: (json['scenes'] as List<dynamic>)
      .map((e) => Scene.fromJson(e as Map<String, dynamic>))
      .toList(),
  icon: json['icon'] as String?,
);

Scene _$SceneFromJson(Map<String, dynamic> json) => Scene(
  id: json['id'] as String,
  height: (json['height'] as num?)?.toDouble() ?? 1.0,
  pin: json['pin'] as bool? ?? false,
  dwell: (json['dwell'] as num?)?.toInt() ?? 3000,
  transitionIn: json['transitionIn'] == null
      ? null
      : SceneTransition.fromJson(json['transitionIn'] as Map<String, dynamic>),
  background: json['background'] == null
      ? const ColorBackground()
      : Background.parse(json['background']),
  blocks: json['blocks'] == null ? const [] : Block.parseList(json['blocks']),
);

SceneTransition _$SceneTransitionFromJson(Map<String, dynamic> json) =>
    SceneTransition(
      type: json['type'] as String? ?? 'cut',
      ms: (json['ms'] as num?)?.toInt() ?? 400,
    );

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
  mode:
      $enumDecodeNullable(
        _$PlaceModeEnumMap,
        json['mode'],
        unknownValue: PlaceMode.overlay,
      ) ??
      PlaceMode.overlay,
  anchor:
      $enumDecodeNullable(
        _$AnchorEnumMap,
        json['anchor'],
        unknownValue: Anchor.center,
      ) ??
      Anchor.center,
  margin: (json['margin'] as num?)?.toDouble() ?? 0.06,
  widthFrac: (json['widthFrac'] as num?)?.toDouble(),
);

const _$PlaceModeEnumMap = {
  PlaceMode.overlay: 'overlay',
  PlaceMode.flow: 'flow',
};

const _$AnchorEnumMap = {
  Anchor.topLeft: 'topLeft',
  Anchor.topCenter: 'topCenter',
  Anchor.topRight: 'topRight',
  Anchor.centerLeft: 'centerLeft',
  Anchor.center: 'center',
  Anchor.centerRight: 'centerRight',
  Anchor.bottomLeft: 'bottomLeft',
  Anchor.bottomCenter: 'bottomCenter',
  Anchor.bottomRight: 'bottomRight',
};

Enter _$EnterFromJson(Map<String, dynamic> json) => Enter(
  type:
      $enumDecodeNullable(
        _$EnterTypeEnumMap,
        json['type'],
        unknownValue: EnterType.none,
      ) ??
      EnterType.fade,
  at:
      (json['at'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      [0.4, 0.55],
);

const _$EnterTypeEnumMap = {
  EnterType.none: 'none',
  EnterType.fade: 'fade',
  EnterType.fadeUp: 'fadeUp',
};

TextBlock _$TextBlockFromJson(Map<String, dynamic> json) => TextBlock(
  text: json['text'] as String,
  style: json['style'] as String?,
  place: json['place'] == null
      ? null
      : Place.fromJson(json['place'] as Map<String, dynamic>),
  enter: json['enter'] == null
      ? null
      : Enter.fromJson(json['enter'] as Map<String, dynamic>),
  overrides: json['override'] == null
      ? null
      : TextStyleDef.fromJson(json['override'] as Map<String, dynamic>),
);

ImageBlock _$ImageBlockFromJson(Map<String, dynamic> json) => ImageBlock(
  asset: json['asset'] as String,
  place: json['place'] == null
      ? null
      : Place.fromJson(json['place'] as Map<String, dynamic>),
  enter: json['enter'] == null
      ? null
      : Enter.fromJson(json['enter'] as Map<String, dynamic>),
);

ImageBackground _$ImageBackgroundFromJson(Map<String, dynamic> json) =>
    ImageBackground(
      asset: json['asset'] as String,
      fit: json['fit'] as String? ?? 'cover',
      motion: json['motion'] as String? ?? 'none',
    );

ColorBackground _$ColorBackgroundFromJson(Map<String, dynamic> json) =>
    ColorBackground(value: json['value'] as String? ?? '#000000');

VideoBackground _$VideoBackgroundFromJson(Map<String, dynamic> json) =>
    VideoBackground(asset: json['asset'] as String);

MapBackground _$MapBackgroundFromJson(Map<String, dynamic> json) =>
    MapBackground(
      from: MapPoint.fromJson(json['from'] as Map<String, dynamic>),
      to: MapPoint.fromJson(json['to'] as Map<String, dynamic>),
      route: json['route'] as String? ?? 'none',
      label: json['label'] as String?,
    );

MapPoint _$MapPointFromJson(Map<String, dynamic> json) => MapPoint(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  zoom: (json['zoom'] as num?)?.toDouble() ?? 10.0,
);
