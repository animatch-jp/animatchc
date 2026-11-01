import 'package:flutter/material.dart';

/// 投稿・コメント・チャットなどに、ひどい言葉や、外での連絡先が入っていないか確かめる。
/// （Appleの審査で「よくない投稿をふせぐしくみ」が必要なため）
///
/// 使い方：
///   final ng = ContentFilter.check([title, body]);
///   if (ng != null) { ...ng を画面に出して、保存しない... }
class ContentFilter {
  ContentFilter._();

  // 入っていたら、投稿できない言葉（大文字・小文字、空白、全角・半角は気にしない）
  static const List<String> _ngWords = [
    // 人を傷つける言葉
    '死ね', '氏ね', '殺す', '殺してやる', 'ころしてやる', '消えろ', 'きえろ',
    'ガイジ', '池沼', 'キモい', 'きもい', 'ブス', 'クズ',
    // 性的な言葉
    'セックス', 'せっくす', 'ちんこ', 'ちんぽ', 'まんこ', 'おっぱい', 'エロ', 'えろ動画', 'av女優',
    // 出会い・お金がらみの勧誘
    '援交', '援助交際', 'パパ活', 'ママ活', '裏垢', '出会い系', 'セフレ',
    '副業で稼', '簡単に稼', '儲かる話', '投資で稼', '高収入バイト',
    // 動物の売り買い（AniMatchでは禁止）
    '生体販売', '個人売買', '売ります', '販売します', '買い取ります',
    // 英語
    'fuck', 'shit', 'bitch', 'porn', 'sex', 'nigger', 'killyourself', 'kys',
  ];

  // みんなに見える場所で、外の連絡先を書いていないか（子どもを守るため）
  static final List<RegExp> _contactPatterns = [
    RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), // メールアドレス
    RegExp(r'(line|ライン)(id|アイディー|ｉｄ)', caseSensitive: false), // LINE ID
  ];

  // 電話番号：0から始まる10〜11けたの数字（間の - や空白は気にしない）
  static bool _hasPhone(String t) {
    final half = StringBuffer();
    for (final r in t.runes) {
      half.writeCharCode(r >= 0xFF10 && r <= 0xFF19 ? r - 0xFEE0 : r);
    }
    for (final m in RegExp(r'[0-9][0-9\-ー－ ()（）]{8,16}[0-9]').allMatches(half.toString())) {
      final digits = m.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('0') && (digits.length == 10 || digits.length == 11)) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      // 全角の英数字・記号を半角に
      if (r >= 0xFF01 && r <= 0xFF5E) {
        b.writeCharCode(r - 0xFEE0);
      } else if (r == 0x3000) {
        // 全角スペースはとばす
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString().toLowerCase().replaceAll(RegExp(r'[\s・._\-]'), '');
  }

  /// だめなら、その理由（画面に出す文）を返す。大丈夫なら null。
  /// allowContact: 1対1のチャットなど、連絡先を書いてもよい場所なら true
  static String? check(List<String?> texts, {bool allowContact = false}) {
    for (final t in texts) {
      if (t == null || t.trim().isEmpty) continue;
      final n = _normalize(t);
      for (final w in _ngWords) {
        if (n.contains(_normalize(w))) {
          return '使えない言葉が入っています（「$w」）。やさしい言葉に変えてください';
        }
      }
      if (!allowContact) {
        if (_hasPhone(t) || _contactPatterns[0].hasMatch(t) || _contactPatterns[1].hasMatch(n)) {
          return '電話番号やメールアドレス、LINEのIDなどは、ここには書けません（安全のため）';
        }
      }
    }
    return null;
  }

  /// だめなら画面に知らせて true を返す（呼んだ側は、保存をやめる）
  static bool blocked(BuildContext context, List<String?> texts, {bool allowContact = false}) {
    final ng = check(texts, allowContact: allowContact);
    if (ng == null) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ng), backgroundColor: Colors.red),
    );
    return true;
  }
}
