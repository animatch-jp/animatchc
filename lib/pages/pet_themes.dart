const List<String> petBragThemes = [
  'おやつタイム🍖',
  '寝顔ショット😴',
  'びっくり顔😳',
  '甘えん坊タイム🥰',
  'かわいい後ろ姿',
  'お気に入りの場所',
  '遊んでる瞬間🎾',
  'グルーミングタイム',
  '窓の外を眺める姿',
  '飼い主にべったり',
  '今日のベストショット',
  'まったりタイム☺️',
  'ごはん待ちの顔',
  'お気に入りのおもちゃ',
  '季節を感じる1枚',
  '朝のひとコマ',
  '夜のリラックスタイム',
  'ふてくされ顔😤',
  '全力ダッシュ中',
  'くつろぎスタイル',
  '観察中の真剣な顔',
  'お腹見せてリラックス',
  '毛づくろい中',
  '見つめてくる瞬間',
  '新しい場所を探検中',
  'おもちゃに夢中',
  '雨の日のおうち時間',
  '日向ぼっこ中',
  '飼い主とのお揃いショット',
  '今週いちばんの癒し',
];

const List<String> discoveryThemes = [
  '今日出会った動物🐾',
  '推しの動物',
  '動物園・水族館で撮った1枚',
  '野良猫との遭遇',
  '空を飛ぶ鳥',
  '散歩中に見かけた子',
  'お店や街で見た看板犬・看板猫',
  '図鑑で見つけたお気に入りの動物',
  '旅先で出会った動物',
  '写真に残したい野生動物',
  '動物系動画で見た1枚',
  '本や図鑑で見つけたお気に入り',
  'SNSで見かけた癒し動物',
  '近所の公園で見た鳥',
  'ペットショップで気になった子',
  '友達・家族のペット',
  '昔飼ってた思い出の子',
  '動物モチーフのグッズ・雑貨',
  'イベント会場で会った動物',
  '動物のイラスト・写真集',
];

List<String> getTodayThemes() {
  final daysSinceEpoch =
      DateTime.now().difference(DateTime(2026, 1, 1)).inDays;

  final petIndex = (daysSinceEpoch) % petBragThemes.length;
  final petTheme = petBragThemes[petIndex];

  final discoveryIndex = (daysSinceEpoch) % discoveryThemes.length;
  final discoveryTheme = discoveryThemes[discoveryIndex];

  return [petTheme, discoveryTheme];
}
