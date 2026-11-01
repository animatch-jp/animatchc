import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'animaru.dart';

/// バッジをもらったときのお祝い。肉球がはじけて、バッジがぽんっと出て、あにまるが喜ぶ。
Future<void> showBadgeCelebration(BuildContext context, String badge, {String emoji = '🏅'}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'とじる',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => _BadgeCelebration(badge: badge, emoji: emoji),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  );
}

class _BadgeCelebration extends StatefulWidget {
  const _BadgeCelebration({required this.badge, required this.emoji});
  final String badge;
  final String emoji;

  @override
  State<_BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<_BadgeCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _p(double a, double b, [Curve c = Curves.easeOut]) =>
      c.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final burst = _p(0.15, 0.8);
            return SizedBox(
              width: 300,
              height: 380,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // はじける肉球
                  ...List.generate(10, (i) {
                    final ang = i / 10 * math.pi * 2;
                    final d = 40 + 110 * burst;
                    return Transform.translate(
                      offset: Offset(math.cos(ang) * d, -40 + math.sin(ang) * d),
                      child: Opacity(
                        opacity: (1 - burst).clamp(0.0, 1.0),
                        child: Icon(Icons.pets,
                            size: 20,
                            color: i.isEven ? const Color(0xFFF2B830) : const Color(0xFF4E8A6E)),
                      ),
                    );
                  }),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('バッジをもらったよ！',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Transform.scale(
                          scale: 0.3 + 0.7 * _p(0.1, 0.6, Curves.elasticOut),
                          child: Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                  colors: [Color(0xFFFFF1C2), Color(0xFFF2B830)]),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFF2B830).withOpacity(0.5),
                                    blurRadius: 20 * _p(0.3, 1))
                              ],
                            ),
                            child: Text(widget.emoji, style: const TextStyle(fontSize: 46)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _p(0.35, 0.6),
                          child: Text(widget.badge,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                        ),
                        const SizedBox(height: 6),
                        const Animaru(size: 70, mood: AnimaruMood.happy),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8845A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('やったね！'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
