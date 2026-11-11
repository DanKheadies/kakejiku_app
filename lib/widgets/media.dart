import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:kakejiku_app/barrel.dart';

/// Turns a path from the story JSON into an [ImageProvider].
///
/// Dev: leave [baseUrl] null and drop files under assets/story/ (declared in
/// pubspec.yaml). Later: set [baseUrl] to your Firebase Storage / CDN root.
class MediaResolver {
  const MediaResolver({this.baseUrl, this.assetDir = 'assets/story'});

  final String? baseUrl;
  final String assetDir;

  ImageProvider provider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    if (baseUrl != null) return NetworkImage('$baseUrl/$path');
    return AssetImage('$assetDir/$path');
  }
}

/// Picks the smallest variant that still looks sharp at [wantedPx]
/// (logical width * device pixel ratio). Falls back to whatever exists.
String pickVariant(Asset a, double wantedPx) {
  final s = a.src;
  if (s.isEmpty) return '';
  final order = wantedPx <= 640
      ? const ['thumb', 'web', 'full']
      : wantedPx <= 1800
      ? const ['web', 'full', 'thumb']
      : const ['full', 'web', 'thumb'];
  for (final k in order) {
    final v = s[k];
    if (v != null) return v;
  }
  return s.values.first;
}

/// Layers: BlurHash (instant) -> thumb (fast) -> target variant (fades in).
/// Because the scroll list only builds scenes near the viewport, building
/// this widget IS the lazy load.
class SmartImage extends StatelessWidget {
  const SmartImage({
    super.key,
    required this.asset,
    required this.resolver,
    this.fit = BoxFit.cover,
  });

  final Asset asset;
  final MediaResolver resolver;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final logicalW = c.maxWidth.isFinite ? c.maxWidth : 1200.0;
        final target = pickVariant(asset, logicalW * dpr);
        final thumb = asset.src['thumb'];
        final alignment = Alignment(
          asset.focal[0] * 2 - 1,
          asset.focal[1] * 2 - 1,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            if (asset.placeholder != null)
              BlurHash(hash: asset.placeholder!)
            else
              const ColoredBox(color: Color(0xFF111111)),
            if (thumb != null && thumb != target)
              Image(
                image: resolver.provider(thumb),
                fit: fit,
                alignment: alignment,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Image(
              image: resolver.provider(target),
              fit: fit,
              alignment: alignment,
              frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                opacity: (frame == null && !sync) ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: child,
              ),
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF222222),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'missing image\n$target',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
