import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AniMatchのキャラクター「あにまる」
/// おもちみたいな、なにものでもない生き物。頭に緑のぽこぽこ。目はちょぼてん。
///
/// size: 横はば（たても同じ）
/// moving: true なら、ふわふわ上下にゆれて、ときどきまばたきする
/// wave: true なら、手をふる
/// mood: 気持ち（ふつう・うれしい・てれる〈手で目をかくす〉・しょんぼり）
enum AnimaruMood { normal, happy, shy, sad }

class Animaru extends StatefulWidget {
  const Animaru({
    super.key,
    this.size = 120,
    this.moving = true,
    this.wave = false,
    this.mood = AnimaruMood.normal,
  });
  final double size;
  final bool moving;
  final bool wave;
  final AnimaruMood mood;

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
      label: 'あにまる',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _AnimaruPainter(
                t: widget.moving ? _c.value : 0, wave: widget.wave, mood: widget.mood),
          ),
        ),
      ),
    );
  }
}

class _AnimaruPainter extends CustomPainter {
  _AnimaruPainter({required this.t, required this.wave, required this.mood});
  final double t; // 0〜1 のくり返し
  final bool wave;
  final AnimaruMood mood;

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
    final happy = mood == AnimaruMood.happy;
    final shy = mood == AnimaruMood.shy;
    final sad = mood == AnimaruMood.sad;
    // 上下のゆれ（うれしいときは、ぴょんぴょんはねる）
    final bob = happy
        ? math.sin(phase * 2).abs() * 10.0
        : sad
            ? math.sin(phase) * 1.2
            : math.sin(phase) * 3.0;
    // ぷにっとした伸び縮み
    final squash = happy
        ? 1 + math.cos(phase * 4) * 0.035
        : 1 + math.sin(phase * 2) * 0.012;
    // てれるときは、左右にもじもじ
    final sway = shy ? math.sin(phase * 2) * 2.5 : 0.0;
    // 2.4秒に1回、まばたき
    final blink = !happy && !sad && t > 0.92 && t < 0.97;

    final paint = Paint()..isAntiAlias = true;

    // かげ
    paint.color = Colors.black.withOpacity(0.08 - bob.abs() * 0.004);
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 184), width: 104 - bob, height: 14), paint);

    canvas.save();
    canvas.translate(sway, -bob);
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
      final dy = math.sin(phase + i * 0.9) * (happy ? 3.0 : 1.6) + (sad ? 5.0 : 0.0);
      canvas.drawCircle(Offset(f[0], f[1] + dy), f[2] * (sad ? 0.9 : 1.0), paint);
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

    // 手（wave のときは右手をふる。うれしいときは両手を上げる。てれるときは、あとで目の上に描く）
    paint.color = _orange;
    if (happy) {
      _limb(canvas, paint, const Offset(42, 112), 40 + math.sin(phase * 4) * 12);
      _limb(canvas, paint, const Offset(158, 112), -40 - math.sin(phase * 4) * 12);
    } else if (!shy) {
      _limb(canvas, paint, const Offset(40, 138), sad ? 10 : 25);
      final waveAngle = wave && !sad ? -60 + math.sin(phase * 3) * 22 : (sad ? -10.0 : -25.0);
      _limb(canvas, paint, Offset(160, wave && !sad ? 128 : 138), waveAngle);
    }

    // 足
    paint.color = _orangeDark;
    canvas.drawOval(Rect.fromCenter(center: const Offset(82, 178), width: 26, height: 14), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(118, 178), width: 26, height: 14), paint);

    // ほっぺ（てれるときは、赤く大きく）
    paint.color = shy ? const Color(0xFFF59A8C) : _cheek;
    final cw = shy ? 24.0 : 18.0, ch = shy ? 15.0 : 12.0;
    canvas.drawOval(Rect.fromCenter(center: const Offset(62, 134), width: cw, height: ch), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(138, 134), width: cw, height: ch), paint);

    // 目（ちょぼてん）
    paint.color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (happy) {
      // にっこり（＾＾）
      for (final x in const [81.0, 119.0]) {
        final e = Path()
          ..moveTo(x - 6, 122)
          ..quadraticBezierTo(x, 113, x + 6, 122);
        canvas.drawPath(e, line);
      }
    } else if (sad) {
      canvas.drawCircle(const Offset(81, 123), 4, paint);
      canvas.drawCircle(const Offset(119, 123), 4, paint);
      // 下がったまゆ
      canvas.drawLine(const Offset(72, 110), const Offset(86, 113), line..strokeWidth = 2.5);
      canvas.drawLine(const Offset(128, 110), const Offset(114, 113), line);
      line.strokeWidth = 3;
    } else if (shy) {
      // 目は手でかくれている
    } else if (blink) {
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
    if (happy) {
      // 大きく笑った口
      final m = Path()
        ..moveTo(92, 133)
        ..quadraticBezierTo(100, 146, 108, 133)
        ..close();
      canvas.drawPath(m, Paint()..color = _ink);
      canvas.drawOval(Rect.fromCenter(center: const Offset(100, 140), width: 8, height: 4),
          Paint()..color = const Color(0xFFE7737F));
    } else if (sad) {
      final m = Path()
        ..moveTo(94, 138)
        ..quadraticBezierTo(100, 133, 106, 138);
      canvas.drawPath(m, mouth);
    } else if (shy) {
      final m = Path()
        ..moveTo(96, 137)
        ..quadraticBezierTo(100, 139, 104, 137);
      canvas.drawPath(m, mouth);
    } else {
      final m = Path()
        ..moveTo(94, 134)
        ..quadraticBezierTo(100, 139, 106, 134);
      canvas.drawPath(m, mouth);
    }

    // てれるとき：両手で目をかくす
    if (shy) {
      paint.color = _orange;
      final wob = math.sin(phase * 4) * 3;
      _limb(canvas, paint, Offset(80, 118 + wob), 70, w: 22, h: 30);
      _limb(canvas, paint, Offset(120, 118 - wob), -70, w: 22, h: 30);
      paint.color = _orangeDark.withOpacity(0.35);
      canvas.drawOval(Rect.fromCenter(center: Offset(80, 122 + wob), width: 10, height: 4), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(120, 122 - wob), width: 10, height: 4), paint);
    }

    canvas.restore();
    canvas.restore();
  }

  void _limb(Canvas canvas, Paint paint, Offset c, double deg, {double w = 18, double h = 24}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimaruPainter old) =>
      old.t != t || old.wave != wave || old.mood != mood;
}
