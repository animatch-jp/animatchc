import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'animaru.dart';

/// アニメーションの部品（AniMatch 全体で同じ動きにする）
/// 「動きを減らす」設定の人には、動かさずにすぐ出す。
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// ふわっと下から出てくる。index をずらすと、順番に出てくる（リストなど）
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.duration = const Duration(milliseconds: 420),
  });
  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = (index.clamp(0, 8)) * 70;
    final total = duration.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      child: child,
      builder: (_, v, c) {
        // 前の delay の間は待つ
        final t = total == 0 ? 1.0 : ((v * total - delay) / duration.inMilliseconds).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: e,
          child: Transform.translate(offset: Offset(0, offset * (1 - e)), child: c),
        );
      },
    );
  }
}

/// ぽんっと大きくなって出てくる（バッジ・チェック・カードなど）
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delayMs = 0, this.from = 0.6});
  final Widget child;
  final int delayMs;
  final double from;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    const dur = 520;
    final total = dur + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      child: child,
      builder: (_, v, c) {
        final t = ((v * total - delayMs) / dur).clamp(0.0, 1.0);
        final s = from + (1 - from) * Curves.elasticOut.transform(t);
        return Opacity(opacity: Curves.easeOut.transform(t), child: Transform.scale(scale: s, child: c));
      },
    );
  }
}

/// 押したときに、少しへこむ（カードやボタンを、さわった感じにする）
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 数字が0から数えあがる
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style, this.suffix = ''});
  final num value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text('${value.round()}$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// ゆらゆら（ベルや大事なお知らせに）。active のときだけ、ときどきゆれる
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, this.active = true});
  final Widget child;
  final bool active;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Wiggle old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context) || !widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, c) {
        // はじめの 0.25 の間だけ、左右に3回ゆれる
        final t = _c.value;
        final a = t < 0.25 ? math.sin(t / 0.25 * math.pi * 6) * 0.22 * (1 - t / 0.25) : 0.0;
        return Transform.rotate(angle: a, alignment: Alignment.topCenter, child: c);
      },
    );
  }
}

/// まるの中に、チェックが「ぽんっ」と出る
class AnimatedCheckCircle extends StatelessWidget {
  const AnimatedCheckCircle({
    super.key,
    required this.done,
    required this.label,
    this.size = 26,
    this.color = const Color(0xFF52B788),
    this.accent = const Color(0xFFE8845A),
  });
  final bool done;
  final String label;
  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: done ? color : accent, width: 1.5),
        boxShadow: done
            ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, spreadRadius: 1)]
            : const [],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (c, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
        child: done
            ? Icon(Icons.check_rounded, key: const ValueKey('done'), size: size * 0.62, color: Colors.white)
            : Text(label,
                key: const ValueKey('todo'),
                style: TextStyle(fontSize: size * 0.46, fontWeight: FontWeight.bold, color: accent)),
      ),
    );
  }
}

/// うれしいことがあったとき：肉球がはじけて、あにまるが喜んで、ひとこと。少したつと自分で消える
Future<void> showHappyBurst(
  BuildContext context, {
  required String message,
  String sub = '',
  String emoji = '🐾',
  Color color = const Color(0xFFE8845A),
  Duration stay = const Duration(milliseconds: 1700),
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _HappyBurst(
      message: message,
      sub: sub,
      emoji: emoji,
      color: color,
      stay: stay,
      onDone: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _HappyBurst extends StatefulWidget {
  const _HappyBurst({
    required this.message,
    required this.sub,
    required this.emoji,
    required this.color,
    required this.stay,
    required this.onDone,
  });
  final String message;
  final String sub;
  final String emoji;
  final Color color;
  final Duration stay;
  final VoidCallback onDone;

  @override
  State<_HappyBurst> createState() => _HappyBurstState();
}

class _HappyBurstState extends State<_HappyBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: Duration(milliseconds: 700 + widget.stay.inMilliseconds));
    _c.forward().whenComplete(_close);
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _c.duration!.inMilliseconds.toDouble();
    double p(double fromMs, double toMs, [Curve curve = Curves.easeOut]) =>
        curve.transform(((_c.value * total - fromMs) / (toMs - fromMs)).clamp(0.0, 1.0));
    final reduce = reduceMotion(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final inT = reduce ? 1.0 : p(0, 380, Curves.easeOutBack);
              final outT = p(total - 260, total);
              final burst = p(80, 900);
              final opacity = (1 - outT).clamp(0.0, 1.0);
              return IgnorePointer(
                ignoring: false,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    color: Colors.black.withOpacity(0.18 * opacity),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (!reduce)
                          ...List.generate(12, (i) {
                            final ang = i / 12 * math.pi * 2 + 0.3;
                            final d = 50 + 120 * burst;
                            final colors = [widget.color, const Color(0xFFF2B830), const Color(0xFF52B788)];
                            return Transform.translate(
                              offset: Offset(math.cos(ang) * d, -30 + math.sin(ang) * d * 0.9),
                              child: Transform.rotate(
                                angle: burst * math.pi * (i.isEven ? 1 : -1),
                                child: Opacity(
                                  opacity: (1 - burst).clamp(0.0, 1.0),
                                  child: Icon(i % 3 == 0 ? Icons.favorite_rounded : Icons.pets,
                                      size: 16 + (i % 3) * 4.0, color: colors[i % 3]),
                                ),
                              ),
                            );
                          }),
                        Transform.scale(
                          scale: 0.6 + 0.4 * inT,
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                    color: widget.color.withOpacity(0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Animaru(size: 76, mood: AnimaruMood.happy, wave: true),
                                const SizedBox(height: 6),
                                Text('${widget.emoji} ${widget.message}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                                if (widget.sub.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(widget.sub,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 写真が読みこまれたら、ふわっと出す（ぱっと出ないように）
class FadeInNetworkImage extends StatelessWidget {
  const FadeInNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFFFFF1E6),
    this.errorEmoji = '🐾',
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color placeholderColor;
  final String errorEmoji;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, sync) {
        if (sync || reduceMotion(context)) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Container(width: width, height: height, color: placeholderColor),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: frame == null ? 1.04 : 1,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                child: child,
              ),
            ),
          ],
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        alignment: Alignment.center,
        child: Text(errorEmoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

/// ゆっくり「どきどき」する（緊急の迷子など、目立たせたいもの）
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.scale = 1.015});
  final Widget child;
  final double scale;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, c) => Transform.scale(
        scale: 1 + (widget.scale - 1) * Curves.easeInOut.transform(_c.value),
        child: c,
      ),
    );
  }
}
