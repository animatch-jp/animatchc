import 'package:flutter/material.dart';

import 'animaru.dart';

/// 登録の画面の上に出す、あにまるの案内（ふきだし）と、いまどこまで進んだかの目印
class AnimaruGuide extends StatelessWidget {
  const AnimaruGuide({
    super.key,
    required this.message,
    required this.step,
    this.mood = AnimaruMood.normal,
    this.labels = userSteps,
  });

  final String message;
  final AnimaruMood mood;
  // いまの段階（labels の何番目か）。null なら、進み具合は出さない
  final int? step;
  final List<String> labels;

  static const userSteps = ['アカウント', 'きほん', 'じこしょうかい', 'うちの子'];
  static const orgSteps = ['申請', '運営が確認', '使えるように'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // オレンジの背景でも見えるように、白い丸の上に立たせる
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Animaru(size: 72, wave: mood == AnimaruMood.normal, mood: mood),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('$message$mood'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * t,
                    alignment: Alignment.bottomLeft,
                    child: child,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 26),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Text(message,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                ),
              ),
            ),
          ],
        ),
        if (step != null) const SizedBox(height: 10),
        if (step != null)
        Row(
          children: List.generate(labels.length, (i) {
            final done = i < step!;
            final now = i == step;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 6,
                      decoration: BoxDecoration(
                        color: done || now ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (done)
                          const Icon(Icons.pets, size: 11, color: Colors.white),
                        if (done) const SizedBox(width: 2),
                        Flexible(
                          child: Text(labels[i],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: now ? FontWeight.bold : FontWeight.normal,
                                  color: done || now ? Colors.white : Colors.white70)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
