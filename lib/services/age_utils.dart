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

  /// 画面に出す形：2008年2月3日
  static String display(DateTime d) => '${d.year}年${d.month}月${d.day}日';
}