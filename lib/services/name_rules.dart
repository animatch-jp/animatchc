import 'package:cloud_firestore/cloud_firestore.dart';

// 名前（ニックネーム）のきまり
// ・運営や公式のふりをする名前は使えない
// ・ほかの人がもう使っている名前は使えない
class NameRules {
  // 名前に入っていたら使えない言葉（大文字・小文字、空白は気にしない）
  static const List<String> reservedWords = [
    '運営',
    '公式',
    '管理者',
    'スタッフ',
    'animatch',
    'アニマッチ',
    'admin',
    'official',
    'staff',
  ];

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s'), '');

  // 運営・公式のふりをする言葉が入っていたら、その理由を返す
  static String? reservedError(String name) {
    final n = _normalize(name);
    for (final w in reservedWords) {
      if (n.contains(_normalize(w))) {
        return '「$w」が入った名前は使えません（運営や公式と見分けがつかなくなるため）';
      }
    }
    return null;
  }

  // 使えない名前なら、その理由を返す。使えるなら null。
  // myUid: 自分の名前を変えるとき、自分自身は「かぶり」に数えない
  static Future<String?> check(String name, {String? myUid}) async {
    final n = name.trim();
    if (n.isEmpty) return '名前を入力してください';
    final reserved = reservedError(n);
    if (reserved != null) return reserved;
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: n)
          .limit(2)
          .get();
      if (q.docs.any((d) => d.id != myUid)) {
        return 'この名前は、ほかの人が使っています。別の名前にしてください';
      }
    } catch (_) {
      // 確かめられなかったとき（通信エラーなど）は、登録は止めない
    }
    return null;
  }
}
