class MonthlyTheme {
  final String title;
  final String emoji;
  MonthlyTheme(this.title, this.emoji);
}

final Map<int, MonthlyTheme> monthlyThemes = {
  1: MonthlyTheme('新年のペット', '🎍'),
  2: MonthlyTheme('あったかペット', '🧣'),
  3: MonthlyTheme('春のはじまり', '🌸'),
  4: MonthlyTheme('おでかけ日和', '🌷'),
  5: MonthlyTheme('新緑とペット', '🌿'),
  6: MonthlyTheme('雨の日のペット', '☔'),
  7: MonthlyTheme('夏の動物', '🌻'),
  8: MonthlyTheme('夏バテ注意', '🍉'),
  9: MonthlyTheme('秋の気配', '🍁'),
  10: MonthlyTheme('ハロウィン仮装', '🎃'),
  11: MonthlyTheme('食欲の秋', '🍂'),
  12: MonthlyTheme('あったかペット・クリスマス', '🎄'),
};

bool isMonthlyBestPeriod(DateTime now) => now.day >= 21;

MonthlyTheme getCurrentMonthlyTheme(DateTime now) => monthlyThemes[now.month]!;

String getMonthlyThemeKey(DateTime now) =>
    '${now.year}-${now.month.toString().padLeft(2, '0')}';
