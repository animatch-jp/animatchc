import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AniMatchのキャラクター「アニマル」
/// おもちみたいな、なにものでもない生き物。頭に緑のぽこぽこ。目はちょぼてん。
///
/// size: 横はば（たても同じ）
/// moving: true なら、ふわふわ上下にゆれて、ときどきまばたきする
/// wave: true なら、手をふる
class Animaru extends StatefulWidget {
  const Animaru({super.key, this.size = 120, this.moving = true, this.wave = false});
  final double size;
  final bool moving;
  final bool wave;

  @override
  State<Animaru> createState() => _AnimaruState();
}

class _AnimaruState extends State<Animaru> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    if (widget.moving) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Animaru old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_c.isAnimating) _c.repeat();
    if (!widget.moving && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'アニマル',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _AnimaruPainter(t: widget.moving ? _c.value : 0, wave: widget.wave),
          ),
        ),
      ),
    );
  }
}

class _AnimaruPainter extends CustomPainter {
  _AnimaruPainter({required this.t, required this.wave});
  final double t; // 0〜1 のくり返し
  final bool wave;

  static const _orange = Color(0xFFE8845A);
  static const _orangeDark = Color(0xFFD9744C);
  static const _green = Color(0xFF4E8A6E);
  static const _cheek = Color(0xFFF9C3A9);
  static const _ink = Color(0xFF2E2018);

  @override
  void paint(Canvas canvas, Size size) {
    // 200×200 の下書きを、大きさに合わせて広げる
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s, s);

    final phase = t * math.pi * 2;
    final bob = math.sin(phase) * 3.0; // 上下のゆれ
    final squash = 1 + math.sin(phase * 2) * 0.012; // ぷにっとした伸び縮み
    // 2.4秒に1回、まばたき
    final blink = t > 0.92 && t < 0.97;

    final paint = Paint()..isAntiAlias = true;

    // かげ
    paint.color = Colors.black.withOpacity(0.08 - bob.abs() * 0.004);
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 184), width: 104 - bob, height: 14), paint);

    canvas.save();
    canvas.translate(0, -bob);
    canvas.translate(100, 178);
    canvas.scale(1 / squash, squash);
    canvas.translate(-100, -178);

    // 頭の緑のぽこぽこ（少しずつずれてゆれる）
    paint.color = _green;
    const tufts = [
      [70.0, 58.0, 11.0],
      [92.0, 48.0, 12.0],
      [114.0, 50.0, 11.0],
      [133.0, 60.0, 9.0],
    ];
    for (var i = 0; i < tufts.length; i++) {
      final f = tufts[i];
      final dy = math.sin(phase + i * 0.9) * 1.6;
      canvas.drawCircle(Offset(f[0], f[1] + dy), f[2], paint);
    }

    // からだ
    final body = Path()
      ..moveTo(100, 58)
      ..cubicTo(140, 58, 164, 88, 164, 124)
      ..cubicTo(164, 158, 138, 178, 100, 178)
      ..cubicTo(62, 178, 36, 158, 36, 124)
      ..cubicTo(36, 88, 60, 58, 100, 58)
      ..close();
    paint.color = _orange;
    canvas.drawPath(body, paint);

    // 手（wave のときは右手をふる）
    paint.color = _orange;
    _limb(canvas, paint, const Offset(40, 138), 25);
    final waveAngle = wave ? -60 + math.sin(phase * 3) * 22 : -25.0;
    _limb(canvas, paint, Offset(160, wave ? 128 : 138), waveAngle);

    // 足
    paint.color = _orangeDark;
    canvas.drawOval(Rect.fromCenter(center: const Offset(82, 178), width: 26, height: 14), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(118, 178), width: 26, height: 14), paint);

    // ほっぺ
    paint.color = _cheek;
    canvas.drawOval(Rect.fromCenter(center: const Offset(62, 134), width: 18, height: 12), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(138, 134), width: 18, height: 12), paint);

    // 目（ちょぼてん）
    paint.color = _ink;
    if (blink) {
      final line = Paint()
        ..color = _ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(76, 120), const Offset(86, 120), line);
      canvas.drawLine(const Offset(114, 120), const Offset(124, 120), line);
    } else {
      canvas.drawCircle(const Offset(81, 120), 5, paint);
      canvas.drawCircle(const Offset(119, 120), 5, paint);
    }

    // 口
    final mouth = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final m = Path()
      ..moveTo(94, 134)
      ..quadraticBezierTo(100, 139, 106, 134);
    canvas.drawPath(m, mouth);

    canvas.restore();
    canvas.restore();
  }

  void _limb(Canvas canvas, Paint paint, Offset c, double deg) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 24), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimaruPainter old) => old.t != t || old.wave != wave;
}
