// イベントの「掲示板」の部品
// 動物病院やペットショップの入口にある、コルクの掲示板と貼り紙がもと。
// ・CorkBoard：コルクの背景（絵で描くので通信なし）
// ・PaperFlyer：画びょうやマスキングテープでとめた貼り紙（少しかたむける）
// ・TearTabs：貼り紙の下の「ちぎって持っていく」タブ。ちぎる＝参加。ちぎられた数＝参加した人の数
import 'dart:math' as math;

import 'package:flutter/material.dart';

const kInk = Color(0xFF2B2420);
const kCork = Color(0xFFB98A5E);
const kPaperWhite = Color(0xFFFFFDF6);
const kPaperYellow = Color(0xFFFFF1B0);
const kPaperBlue = Color(0xFFD9ECFF);
const kPaperPink = Color(0xFFFFDDE4);
const kPaperGreen = Color(0xFFDDF3DC);
const kPinRed = Color(0xFFE5484D);

class CorkBoard extends StatelessWidget {
  final Widget child;
  const CorkBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: kCork),
      child: CustomPaint(painter: _CorkPainter(), child: child),
    );
  }
}

class _CorkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final dark = Paint()..color = const Color(0xFF8E6340).withValues(alpha: 0.35);
    final light = Paint()..color = const Color(0xFFDDB48A).withValues(alpha: 0.4);
    // 画面の大きさに合わせて、つぶの数を決める（多すぎると重い）
    final count = (size.width * size.height / 900).clamp(200, 1600).toInt();
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.6, i.isEven ? dark : light);
    }
  }

  @override
  bool shouldRepaint(covariant _CorkPainter oldDelegate) => false;
}

enum FlyerAttach { pin, tape }

class PaperFlyer extends StatelessWidget {
  final Color color;
  final double angle; // 度（-3〜3くらい）
  final FlyerAttach attach;
  final Color pinColor;
  final EdgeInsets padding;
  final Widget child;
  const PaperFlyer({
    super.key,
    required this.child,
    this.color = kPaperWhite,
    this.angle = 0,
    this.attach = FlyerAttach.pin,
    this.pinColor = kPinRed,
    this.padding = const EdgeInsets.fromLTRB(16, 22, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Transform.rotate(
      angle: (reduce ? 0 : angle) * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B2414).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: child,
          ),
          if (attach == FlyerAttach.pin)
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(child: _Pin(color: pinColor)),
            )
          else
            Positioned(
              top: -9,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.rotate(
                  angle: -4 * math.pi / 180,
                  child: Container(
                    width: 74,
                    height: 20,
                    color: const Color(0xFFF2E3B3).withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color color;
  const _Pin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.55)!, color],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 3, offset: const Offset(1, 2)),
        ],
      ),
    );
  }
}

// 貼り紙の下の、ちぎれるタブ（いちばん目立つ仕掛けはここだけ）
class TearTabs extends StatefulWidget {
  final int taken; // もうちぎられた数（参加した数）
  final int total;
  final bool enabled;
  final String label; // タブに書く文字
  final Future<bool> Function() onTear; // 送れたら true
  const TearTabs({
    super.key,
    required this.taken,
    required this.onTear,
    this.total = 8,
    this.enabled = true,
    this.label = '🐾',
  });

  @override
  State<TearTabs> createState() => _TearTabsState();
}

class _TearTabsState extends State<TearTabs> {
  int? _falling; // いまちぎれて落ちているタブ
  bool _busy = false;

  Future<void> _tap(int i) async {
    if (_busy || !widget.enabled) return;
    setState(() {
      _busy = true;
      _falling = i;
    });
    final ok = await widget.onTear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _falling = null;
    });
  }

  @override
  void didUpdateWidget(covariant TearTabs old) {
    super.didUpdateWidget(old);
    // 参加の数が増えたら、落ちたタブは「ちぎられたあと」として描く
    if (widget.taken != old.taken) _falling = null;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final takenShown = widget.taken.clamp(0, widget.total);
    return Column(children: [
      // ミシン目
      CustomPaint(size: const Size(double.infinity, 2), painter: _PerforationPainter()),
      SizedBox(
        height: 54,
        child: Row(
          children: List.generate(widget.total, (i) {
            final torn = i < takenShown;
            final falling = _falling == i && !torn;
            return Expanded(
              child: torn
                  ? const _TornStub()
                  : AnimatedSlide(
                      duration: Duration(milliseconds: reduce ? 0 : 420),
                      curve: Curves.easeIn,
                      offset: falling ? const Offset(0.15, 1.6) : Offset.zero,
                      child: AnimatedRotation(
                        duration: Duration(milliseconds: reduce ? 0 : 420),
                        turns: falling ? 0.06 : 0,
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: reduce ? 0 : 420),
                          opacity: falling ? 0 : 1,
                          child: Semantics(
                            button: true,
                            label: 'ちぎって参加する',
                            child: InkWell(
                              onTap: widget.enabled ? () => _tap(i) : null,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: kInk.withValues(alpha: 0.15)),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    widget.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: widget.enabled ? kInk : kInk.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            );
          }),
        ),
      ),
    ]);
  }
}

class _TornStub extends StatelessWidget {
  const _TornStub();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomPaint(size: const Size(double.infinity, 10), painter: _TornEdgePainter()),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kInk.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 1), Offset(x + 3.5, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ちぎられたあとの、ぎざぎざの紙の端
class _TornEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 0);
    final rnd = math.Random(size.width.round());
    for (double x = 0; x <= size.width; x += 4) {
      path.lineTo(x, 3 + rnd.nextDouble() * 6);
    }
    path
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = kPaperWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 丸いシール（動物で探す・3つのえらび方に使う）
class Sticker extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const Sticker({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(1, 3)),
              ],
            ),
            child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
                  shadows: [Shadow(color: Color(0x88000000), blurRadius: 3)])),
        ]),
      ),
    );
  }
}
