import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 登録の画面の上の部分。
/// ・色が少しずつ動くグラデーション
/// ・ふわふわ浮かぶ丸と、上へのぼっていく肉球
/// ・下のふちが、ゆっくり動く波の形
class SignupHeader extends StatefulWidget {
  const SignupHeader({
    super.key,
    required this.child,
    this.colors = const [Color(0xFFE8845A), Color(0xFFF4A261)],
    this.padding = const EdgeInsets.fromLTRB(24, 72, 24, 52),
  });

  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;

  @override
  State<SignupHeader> createState() => _SignupHeaderState();
}

class _SignupHeaderState extends State<SignupHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce && _c.isAnimating) _c.stop();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final a = math.sin(t * math.pi * 2);
        return ClipPath(
          clipper: _WaveClipper(t),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.colors,
                begin: Alignment(-1 + a * 0.4, -1),
                end: Alignment(1 - a * 0.4, 1),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _FloatPainter(t))),
                Padding(padding: widget.padding, child: child),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  _WaveClipper(this.t);
  final double t;

  @override
  Path getClip(Size size) {
    const h = 22.0;
    final p = Path()..lineTo(0, size.height - h);
    final shift = t * math.pi * 2;
    for (double x = 0; x <= size.width; x += 6) {
      final y = size.height - h +
          math.sin(x / size.width * math.pi * 2 + shift) * 7 +
          math.sin(x / size.width * math.pi * 4 - shift) * 3;
      p.lineTo(x, y);
    }
    p
      ..lineTo(size.width, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant _WaveClipper old) => old.t != t;
}

class _FloatPainter extends CustomPainter {
  _FloatPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    // ふわふわ浮かぶ丸
    const bubbles = [
      [0.85, 0.18, 60.0, 0.0],
      [0.10, 0.70, 44.0, 0.3],
      [0.62, 0.62, 28.0, 0.6],
      [0.95, 0.80, 36.0, 0.8],
    ];
    for (final b in bubbles) {
      final ph = (t + b[3]) * math.pi * 2;
      final c = Offset(size.width * b[0] + math.sin(ph) * 10, size.height * b[1] + math.cos(ph) * 8);
      paint.color = Colors.white.withOpacity(0.10);
      canvas.drawCircle(c, b[2], paint);
    }
    // 上へのぼっていく、小さな肉球
    for (var i = 0; i < 7; i++) {
      final r = math.Random(i * 13 + 5);
      final x = size.width * (0.05 + r.nextDouble() * 0.9);
      final speed = 0.5 + r.nextDouble() * 0.5;
      final p = (t * speed * 2 + r.nextDouble()) % 1.0;
      final y = size.height * (1.05 - p * 1.1);
      final s = 5.0 + r.nextDouble() * 4;
      final alpha = (math.sin(p * math.pi) * 0.22).clamp(0.0, 1.0);
      _paw(canvas, Offset(x + math.sin(p * 6 + i) * 6, y), s, Colors.white.withOpacity(alpha),
          r.nextDouble() * 0.8 - 0.4);
    }
  }

  void _paw(Canvas canvas, Offset c, double s, Color color, double rot) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.6), width: s * 2.2, height: s * 1.8), paint);
    for (final o in const [Offset(-1.3, -0.9), Offset(-0.45, -1.6), Offset(0.45, -1.6), Offset(1.3, -0.9)]) {
      canvas.drawCircle(Offset(o.dx * s, o.dy * s), s * 0.45, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FloatPainter old) => old.t != t;
}

/// 中身を1つずつ、下からふわっと出す Column
class StaggerColumn extends StatelessWidget {
  const StaggerColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) _StaggerItem(index: i, child: children[i]),
      ],
    );
  }
}

class _StaggerItem extends StatefulWidget {
  const _StaggerItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + math.min(widget.index, 14) * 45), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - _a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// 登録の画面から次の画面へ：右からすっと入って、ふわっと出る
Route<T> signupRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
