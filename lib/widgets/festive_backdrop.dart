// 「ひろば」の背景：お祭りのような絵（写真を読みこまないので、すぐ出て、通信も使わない）
// ・bunting：三角の旗と紙ふぶき（昼のお祭り）
// ・lantern：ちょうちんと光のつぶ（夜のお祭り）
// ・stars：星と光のつぶ（しずかな夜）
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pages/hiroba_data.dart' show BackdropStyle;

class FestiveBackdrop extends StatelessWidget {
  final List<Color> colors;
  final BackdropStyle style;
  final int seed; // 部屋ごとに、紙ふぶきの位置を変える
  final Widget? child;
  const FestiveBackdrop({
    super.key,
    required this.colors,
    this.style = BackdropStyle.bunting,
    this.seed = 1,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: CustomPaint(
        painter: _FestivePainter(style: style, seed: seed),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _FestivePainter extends CustomPainter {
  final BackdropStyle style;
  final int seed;
  _FestivePainter({required this.style, required this.seed});

  static const _flagColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFE066),
    Color(0xFF7BE0AD),
    Color(0xFF8EC5FF),
    Color(0xFFFFB3C7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    // やわらかい光のつぶ（どの絵にも）
    for (var i = 0; i < 9; i++) {
      final r = 14.0 + rnd.nextDouble() * 38;
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07 + rnd.nextDouble() * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    switch (style) {
      case BackdropStyle.bunting:
        _bunting(canvas, size, rnd);
        _confetti(canvas, size, rnd);
      case BackdropStyle.lantern:
        _lanterns(canvas, size, rnd);
        _sparkles(canvas, size, rnd, 18);
      case BackdropStyle.stars:
        _sparkles(canvas, size, rnd, 30);
    }
  }

  // ひもに下がった三角の旗（2本）
  void _bunting(Canvas canvas, Size size, math.Random rnd) {
    final rows = size.height > 120 ? 2 : 1;
    for (var row = 0; row < rows; row++) {
      final y0 = 6.0 + row * 26;
      final sag = 16.0 + row * 6;
      final xStart = row == 0 ? -10.0 : size.width * 0.35;
      final xEnd = size.width + 10;
      Offset at(double t) {
        final x = xStart + (xEnd - xStart) * t;
        final y = y0 + sag * 4 * t * (1 - t);
        return Offset(x, y);
      }

      final string = Path()..moveTo(at(0).dx, at(0).dy);
      for (var t = 0.0; t <= 1.0001; t += 0.05) {
        final p = at(t);
        string.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          string,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: 0.75));
      final n = ((xEnd - xStart) / 26).floor();
      for (var i = 0; i < n; i++) {
        final t0 = (i + 0.15) / n, t1 = (i + 0.85) / n;
        final a = at(t0), b = at(t1);
        final mid = at((t0 + t1) / 2);
        final tip = Offset(mid.dx, mid.dy + 16);
        final flag = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(tip.dx, tip.dy)
          ..close();
        canvas.drawPath(
            flag,
            Paint()
              ..color = _flagColors[(i + row * 2 + seed) % _flagColors.length]
                  .withValues(alpha: 0.9));
      }
    }
  }

  void _confetti(Canvas canvas, Size size, math.Random rnd) {
    for (var i = 0; i < 26; i++) {
      final c = _flagColors[rnd.nextInt(_flagColors.length)];
      final p = Offset(rnd.nextDouble() * size.width, 30 + rnd.nextDouble() * (size.height - 30));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      final paint = Paint()..color = c.withValues(alpha: 0.55 + rnd.nextDouble() * 0.35);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 2.4, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -1.6, 8, 3.2), const Radius.circular(1)),
            paint);
      }
      canvas.restore();
    }
  }

  // ちょうちん（上からぶら下がる、光る丸）
  void _lanterns(Canvas canvas, Size size, math.Random rnd) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 8), Offset(size.width, 8), line);
    final n = math.max(3, (size.width / 70).floor());
    const warm = [Color(0xFFFFB347), Color(0xFFFF6B6B), Color(0xFFFFE29A)];
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * size.width / n + (rnd.nextDouble() - 0.5) * 10;
      final drop = 14.0 + rnd.nextDouble() * 14;
      canvas.drawLine(Offset(x, 8), Offset(x, 8 + drop), line);
      final c = Offset(x, 8 + drop + 13);
      final color = warm[i % warm.length];
      canvas.drawCircle(
          c,
          22,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 20, height: 26), const Radius.circular(10));
      canvas.drawRRect(body, Paint()..color = color);
      final rib = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..strokeWidth = 1;
      for (final dy in [-6.0, 0.0, 6.0]) {
        canvas.drawLine(Offset(c.dx - 9, c.dy + dy), Offset(c.dx + 9, c.dy + dy), rib);
      }
      final cap = Paint()..color = const Color(0xFF3D2B1F).withValues(alpha: 0.7);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy - 13), width: 10, height: 3), cap);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy + 13), width: 10, height: 3), cap);
    }
  }

  // きらきら（十字の星と小さな点）
  void _sparkles(Canvas canvas, Size size, math.Random rnd, int count) {
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final a = 0.35 + rnd.nextDouble() * 0.55;
      final paint = Paint()..color = Colors.white.withValues(alpha: a);
      if (i % 4 == 0) {
        final r = 3.0 + rnd.nextDouble() * 3;
        final star = Path()
          ..moveTo(p.dx, p.dy - r)
          ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
          ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
          ..close();
        canvas.drawPath(star, paint);
      } else {
        canvas.drawCircle(p, 0.8 + rnd.nextDouble() * 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FestivePainter old) => old.style != style || old.seed != seed;
}
