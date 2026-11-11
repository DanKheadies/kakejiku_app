import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kakejiku_app/barrel.dart';

Color parseColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

FontWeight? _weight(int? w) => w == null
    ? null
    : FontWeight.values[((w / 100).round() - 1).clamp(0, 8).toInt()];

/// Renders one text block: font/size/weight/color, optional frame, rotation,
/// and an optional typewriter reveal driven by [reveal] (0..1).
class StyledText extends StatelessWidget {
  const StyledText({
    super.key,
    required this.text,
    required this.def,
    required this.fonts,
    this.reveal = 1.0,
  });

  final String text;
  final TextStyleDef def;
  final Map<String, String> fonts;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final frame = def.frame ?? Frame.none;

    final Color? bg = def.bg != null
        ? parseColor(def.bg, Colors.white)
        : switch (frame) {
            Frame.none => null,
            Frame.pixelBox => const Color(0xFF1B1B6B),
            _ => Colors.white,
          };

    // If no color was chosen, pick black or white for contrast with the bg.
    final autoColor = bg == null
        ? Colors.white
        : (bg.computeLuminance() > 0.5 ? Colors.black : Colors.white);

    final style = TextStyle(
      fontFamily: fonts[def.font ?? 'body'],
      fontSize: def.size ?? 20,
      fontWeight: _weight(def.weight),
      color: parseColor(def.color, autoColor),
      height: 1.3,
      shadows: def.shadow == true
          ? const [
              Shadow(
                blurRadius: 8,
                color: Color(0xCC000000),
                offset: Offset(0, 1),
              ),
            ]
          : null,
    );

    // Typewriter: the unrevealed tail is laid out but transparent, so the
    // box never changes size while the text "types".
    final n = (text.length * reveal).round().clamp(0, text.length).toInt();
    final Widget t = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, n)),
          if (n < text.length)
            TextSpan(
              text: text.substring(n),
              style: const TextStyle(color: Colors.transparent, shadows: []),
            ),
        ],
      ),
      style: style,
      textAlign: frame == Frame.pixelBox ? TextAlign.left : TextAlign.center,
    );

    final Widget framed = switch (frame) {
      Frame.none => t,
      Frame.card => DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: t,
        ),
      ),
      Frame.speech => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: t,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: CustomPaint(
              size: const Size(20, 12),
              painter: _TailPainter(bg ?? Colors.white),
            ),
          ),
        ],
      ),
      Frame.pixelBox => DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4)),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(14), child: t),
      ),
    };

    final rot = def.rotation ?? 0;
    return rot == 0
        ? framed
        : Transform.rotate(angle: rot * math.pi / 180, child: framed);
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
