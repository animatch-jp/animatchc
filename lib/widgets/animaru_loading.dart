import 'package:flutter/material.dart';

import 'animaru.dart';

/// 読みこみ中：あにまるがぴょこぴょこはねて「よみこみ中…」。
/// せまい場所では、ふつうのくるくるにする。
class AnimaruLoading extends StatelessWidget {
  const AnimaruLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxHeight < 120 || c.maxWidth < 120) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE8845A), strokeWidth: 2.5));
      }
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Animaru(size: 72, mood: AnimaruMood.happy),
            SizedBox(height: 4),
            _Dots(),
          ],
        ),
      );
    });
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = (_c.value * 4).floor();
        return Text('よみこみ中${'.' * n}${' ' * (3 - n)}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE8845A)));
      },
    );
  }
}
