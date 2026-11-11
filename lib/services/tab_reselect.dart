import 'package:flutter/material.dart';

// 下のタブで、いま開いているタブをもう一度押したら、その画面のいちばん上にもどる（インスタと同じ）
// 0 ホーム・1 どうぶつマップ・2 イベント・3 チャット・4 マイページ
class TabReselect {
  static final List<ValueNotifier<int>> tabs = List.generate(5, (_) => ValueNotifier<int>(0));

  static void fire(int index) => tabs[index].value++;

  /// その画面の、スクロールしている場所をいちばん上にもどす
  static void toTop(Iterable<ScrollController> controllers) {
    for (final c in controllers) {
      if (c.hasClients) {
        c.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    }
  }
}
