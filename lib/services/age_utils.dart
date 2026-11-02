import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 生年月日と年齢の計算。
/// 生年月日は「2008-02-03」のような文字列で保存する（時差で日付がずれないようにするため）。
class AgeUtils {
  /// DateTime → "2008-02-03"
  static String format(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$m-$day';
  }

  /// "2008-02-03" → DateTime。形がおかしければ null
  static DateTime? parse(String? s) {
    if (s == null) return null;
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    final dt = DateTime(y, m, d);
    // 2月31日 などは、別の日にずれるので、無効にする
    if (dt.year != y || dt.month != m || dt.day != d) return null;
    return dt;
  }

  /// 満年齢（誕生日の当日から1つ上がる）
  static int calculate(DateTime birth, [DateTime? now]) {
    final n = now ?? DateTime.now();
    var age = n.year - birth.year;
    if (n.month < birth.month ||
        (n.month == birth.month && n.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// ほかの人に見せる年代：「10代」「20代」…（くわしい年齢は見せない）
  static String group(int age) => age < 10 ? '10歳未満' : '${age - age % 10}代';

  /// プロフィールのデータから、年代を出す（前の版で age だけがある人にも対応）
  static String groupOf(Map<String, dynamic>? data) {
    final g = data?['ageGroup'];
    if (g is String && g.isNotEmpty) return g;
    final a = data?['age'];
    if (a is int) return group(a);
    return '';
  }

  /// 自分の今の年齢（本人しか読めない生年月日から計算。なければ前の版の age）
  static Future<int?> myAge() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      final b = await userRef.collection('private').doc('birth').get();
      final birth = parse(b.data()?['birthDate'] as String?);
      if (birth != null) return calculate(birth);
    } catch (_) {}
    try {
      final u = await userRef.get();
      return u.data()?['age'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// 画面に出す形：2008年2月3日
  static String display(DateTime d) => '${d.year}年${d.month}月${d.day}日';
}