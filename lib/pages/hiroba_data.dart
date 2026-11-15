// 「ひろば」で使う決まったデータ（部屋・今日のお題・期間限定のお祭り・話しはじめのことば）
//
// ・部屋は、いつでも開いている。入っただけでは、だれにも知らされない（見るだけでもよい）
// ・投稿は 140 文字まで。名前を出さずに「ないしょさん」として書くこともできる
// ・ここから 1対1 のメッセージは送れない（名前を押してもプロフィールは開かない）
import 'package:flutter/material.dart';

// 背景の絵の種類
enum BackdropStyle { bunting, lantern, stars }

class HirobaRoom {
  final String id; // Firestore の hiroba/{id}
  final String emoji;
  final String name;
  final String desc;
  final List<Color> colors; // 背景のグラデーション（上→下）
  final BackdropStyle style;
  final List<String> starters; // この部屋だけの「話しはじめのことば」
  // お題・お祭りの部屋だけ：同じ部屋の中で、その日（その年）の分だけを見せる印
  final String? span;
  final String? prompt; // 上に出す問いかけ
  final bool allowPhoto; // 写真をつけて投稿できる
  final DateTime? opensAt; // 決まった時間だけ書ける部屋（話しあい会）
  final DateTime? closesAt;
  final bool showPopular; // 「スタンプの多い順」も見られる（写真大会）
  const HirobaRoom({
    required this.id,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.colors,
    this.style = BackdropStyle.bunting,
    this.starters = const [],
    this.span,
    this.prompt,
    this.allowPhoto = false,
    this.opensAt,
    this.closesAt,
    this.showPopular = false,
  });
}

// どうぶつ別の集まり（いつでも開いている部屋）。犬・猫だけでなく、うさぎ・小鳥・爬虫類なども同じように並べる
class AnimalGroup {
  final String key; // 部屋は ani_{key}
  final String emoji;
  final String name; // イベントの「どの動物の会」と同じ文字
  final List<Color> colors;
  final String note; // 会うイベントでの気づかい
  const AnimalGroup(this.key, this.emoji, this.name, this.colors, this.note);

  HirobaRoom get room => HirobaRoom(
        id: 'ani_$key',
        emoji: emoji,
        name: '$nameの部屋',
        desc: '$nameと暮らす人・$nameが好きな人の部屋',
        colors: colors,
        style: BackdropStyle.stars,
        starters: ['うちの$nameは', '$nameのことで聞きたいんですが、'],
        allowPhoto: true,
      );
}

const _restNote = '移動や温度の変化が負担になりやすい子も多いので、会うイベントは「動物はお留守番（人だけ）」の会がおすすめです。アプリの中のイベントなら、おうちからいっしょに参加できます。';

const List<AnimalGroup> animalGroups = [
  AnimalGroup('dog', '🐶', '犬', [Color(0xFFFFA26B), Color(0xFFE8845A)],
      'おさんぽ会では、ほかの犬が苦手な子もいます。あいさつは飼い主さんに声をかけてから。'),
  AnimalGroup('cat', '🐱', '猫', [Color(0xFFF78CA0), Color(0xFFC86DD7)],
      '猫は外へ連れ出すのが負担になりやすいので、人だけの会や、アプリの中のイベントがおすすめです。'),
  AnimalGroup('rabbit', '🐰', 'うさぎ', [Color(0xFFFFB7C5), Color(0xFFFF8FA3)], _restNote),
  AnimalGroup('bird', '🐦', '小鳥', [Color(0xFF7BE0AD), Color(0xFF2D9C8F)], _restNote),
  AnimalGroup('small', '🐹', 'ハムスター・小動物', [Color(0xFFFFD36B), Color(0xFFF2A65A)], _restNote),
  AnimalGroup('ferret', '🐾', 'フェレット', [Color(0xFFC3A27A), Color(0xFF8D6E63)], _restNote),
  AnimalGroup('reptile', '🦎', '爬虫類', [Color(0xFF8BC34A), Color(0xFF33691E)], _restNote),
  AnimalGroup('other', '🐟', '魚・両生類・そのほか', [Color(0xFF48C6EF), Color(0xFF3B6FD6)], _restNote),
];

// 会うイベントで選べる「どの動物の会」
List<String> get eventAnimalChoices => ['どの動物でも', ...animalGroups.map((g) => g.name)];

// 会うイベントの「安心のしるし」（ルールでは8こまで）
const List<String> eventSafetyTags = [
  'はじめて歓迎',
  '1人参加OK',
  '見学だけOK',
  '少人数（10人まで）',
  '話さなくてOK',
  '動物はお留守番（人だけ）',
];

// むかしの部屋（もう出さないが、ルール・削除・通報では使う）
const List<String> legacyRoomIds = ['jiman', 'warai', 'soudan', 'yoru', 'hogo', 'suki', 'topic'];

// どの部屋でも出す「話しはじめのことば」
const List<String> commonStarters = [
  'はじめまして！見るだけでしたが、書いてみます🐾',
  'わかります〜！',
  'うちの子も同じです！',
  'かわいい…！',
  'ありがとうございます😊',
];

// 押すとすぐ送れる大きなスタンプ（文を考えなくても参加できる）
const List<String> quickStamps = ['👋', '🐾', '😊', '🥰', '😂', '🙌', '💐', '🌙'];

// 投稿につけるリアクション（ルールの reactionsOk と同じ名前）
const List<(String, String, String)> hirobaReactions = [
  ('paw', '🐾', 'わかる'),
  ('love', '😍', 'かわいい'),
  ('laugh', '😂', 'わらった'),
  ('good', '👍', 'いいね'),
  ('thanks', '🙏', 'ありがとう'),
];

// 名前を出さないで書くときの名前（ルールと同じ文字）
const String hiddenName = 'ないしょさん';

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/* ---------------- アプリの中のイベント（運営が毎週ひらく） ---------------- */

// 写真大会のテーマ（どの動物でも撮れるもの）
const List<String> photoThemes = [
  'おやすみ姿',
  'ごはんタイム',
  'お気に入りの場所',
  '横顔',
  'おめめ',
  'あし・手・しっぽ',
  'おうち自慢（ケージ・水そうも）',
  '日なたぼっこ',
  'おもちゃといっしょ',
  'ふしぎなポーズ',
  'まんまる',
  'うちの子のドヤ顔',
];

// みんなでチャレンジ（みんなで目標の数を集める）
const List<String> challengeThemes = [
  'うちの子に「ありがとう」を伝えよう',
  'おうちの安全チェック（かじる物・飲みこむ物を片づけた）',
  '温度と湿度をチェックしよう（小鳥・うさぎ・爬虫類にも大事）',
  '保護動物のことを、1つ知ろう',
  'うちの子の体重をはかろう',
  '防災の準備をひとつ（キャリー・ごはん・お薬）',
];

// 話しあい会のテーマ（犬・猫以外の子の回も同じように入れる）
const List<String> talkTopics = [
  'はじめて飼うなら？ みんなの体験',
  '爬虫類・両生類の冬じたく（温度と湿度）',
  '保護犬・保護猫を迎えて変わったこと',
  '小鳥の放鳥タイム、どうしてる？',
  'シニアになったうちの子との暮らし',
  'うさぎの換毛期の乗りきり方',
  '旅行や外出のとき、うちの子はどうしてる？',
  'ハムスター・小動物のおうちづくり',
  'うちの子の名前の由来',
  'フェレットのいたずら話',
];

class OnlineEvent {
  final String kind; // photo / challenge / talk / fes
  final String emoji;
  final String title;
  final String theme;
  final DateTime start, end;
  final List<Color> colors;
  final BackdropStyle style;
  final String span;
  final int? goal;
  final String howTo; // 参加のしかた（1行）
  const OnlineEvent({
    required this.kind,
    required this.emoji,
    required this.title,
    required this.theme,
    required this.start,
    required this.end,
    required this.colors,
    required this.style,
    required this.span,
    required this.howTo,
    this.goal,
  });

  String get roomId => kind == 'fes' ? 'fes_${span.split('-').first}' : kind;
  bool isLive(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  HirobaRoom get room => HirobaRoom(
        id: roomId,
        emoji: emoji,
        name: title,
        desc: theme,
        colors: colors,
        style: style,
        span: span,
        prompt: kind == 'photo' ? 'テーマ「$theme」' : theme,
        allowPhoto: kind == 'photo' || kind == 'fes',
        showPopular: kind == 'photo',
        opensAt: kind == 'talk' ? start : null,
        closesAt: kind == 'talk' ? end : null,
        starters: switch (kind) {
          'photo' => const ['うちの子の', 'はじめて参加します！'],
          'challenge' => const ['やりました！', 'うちでは'],
          'talk' => const ['こんばんは〜', 'うちの場合は、', '見てるだけですが、参考になります'],
          _ => const ['うちの子は'],
        },
      );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
int _weekIndex(DateTime monday) => monday.difference(DateTime(2026, 1, 5)).inDays ~/ 7;

// その週の月曜
DateTime mondayOf(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

List<OnlineEvent> _weekEvents(DateTime monday) {
  final w = _weekIndex(monday);
  final fri = monday.add(const Duration(days: 4));
  final wed = monday.add(const Duration(days: 2));
  final sun = monday.add(const Duration(days: 6));
  final photo = photoThemes[w % photoThemes.length];
  final ch = challengeThemes[w % challengeThemes.length];
  return [
    OnlineEvent(
      kind: 'challenge',
      emoji: '🤝',
      title: 'みんなでチャレンジ',
      theme: ch,
      start: monday,
      end: monday.add(const Duration(days: 4)),
      colors: const [Color(0xFF00C9A7), Color(0xFF4D8076)],
      style: BackdropStyle.bunting,
      span: 'ch-${dayKey(monday)}',
      goal: 100,
      howTo: 'やったら「やりました！」とひとこと。スタンプだけでもOK',
    ),
    OnlineEvent(
      kind: 'talk',
      emoji: '🌙',
      title: '水曜の話しあい会',
      theme: talkTopics[(w * 2) % talkTopics.length],
      start: wed.add(const Duration(hours: 21)),
      end: wed.add(const Duration(hours: 21, minutes: 45)),
      colors: const [Color(0xFF3B3B98), Color(0xFF7B4397)],
      style: BackdropStyle.lantern,
      span: 'talk-${dayKey(wed)}',
      howTo: '21:00〜21:45だけ開く部屋。見るだけでもOK',
    ),
    OnlineEvent(
      kind: 'photo',
      emoji: '📸',
      title: '週末の写真大会',
      theme: photo,
      start: fri,
      end: monday.add(const Duration(days: 7)),
      colors: const [Color(0xFFFF9A6B), Color(0xFFFF6F91)],
      style: BackdropStyle.bunting,
      span: 'photo-${dayKey(fri)}',
      howTo: 'テーマに合う写真を1枚。どの動物でもOK。スタンプで応援も',
    ),
    OnlineEvent(
      kind: 'talk',
      emoji: '☕',
      title: '日曜の話しあい会',
      theme: talkTopics[(w * 2 + 1) % talkTopics.length],
      start: sun.add(const Duration(hours: 20)),
      end: sun.add(const Duration(hours: 20, minutes: 45)),
      colors: const [Color(0xFF48C6EF), Color(0xFF6F86D6)],
      style: BackdropStyle.stars,
      span: 'talk-${dayKey(sun)}',
      howTo: '20:00〜20:45だけ開く部屋。見るだけでもOK',
    ),
  ];
}

OnlineEvent _festivalEvent(HirobaFestival f, int year) => OnlineEvent(
      kind: 'fes',
      emoji: f.emoji,
      title: f.name,
      theme: f.prompt,
      start: f.start(year),
      end: f.end(year).add(const Duration(seconds: 1)),
      colors: f.colors,
      style: f.style,
      span: '${f.id}-$year',
      goal: f.goal,
      howTo: '写真かひとことで参加。みんなで${f.goal}こ集めよう',
    );

// いま開いているイベント（お祭りがいちばん上）
List<OnlineEvent> liveOnlineEvents(DateTime now) {
  final list = <OnlineEvent>[];
  final f = currentFestival(now);
  if (f != null) list.add(_festivalEvent(f, now.year));
  list.addAll(_weekEvents(mondayOf(now)).where((e) => e.isLive(now)));
  return list;
}

// これから7日のうちに始まるイベント（始まる順）
List<OnlineEvent> upcomingOnlineEvents(DateTime now) {
  final m = mondayOf(now);
  final all = [..._weekEvents(m), ..._weekEvents(m.add(const Duration(days: 7)))];
  final limit = now.add(const Duration(days: 7));
  final list = all.where((e) => e.start.isAfter(now) && e.start.isBefore(limit)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final (nf, ny) = nextFestival(now);
  if (nf.start(ny).isBefore(limit)) list.insert(0, _festivalEvent(nf, ny));
  return list;
}

const List<String> weekdayJa = ['月', '火', '水', '木', '金', '土', '日'];

String whenText(DateTime d) =>
    '${d.month}/${d.day}（${weekdayJa[d.weekday - 1]}）${d.hour == 0 && d.minute == 0 ? '' : ' ${d.hour}:${d.minute.toString().padLeft(2, '0')}'}';

/* ---------------- 期間限定のお祭り ---------------- */

class HirobaFestival {
  final String id; // 部屋は fes_{id}
  final String emoji;
  final String name;
  final String prompt;
  final int month, startDay, endDay; // 毎年この期間（同じ月の中）
  final List<Color> colors;
  final BackdropStyle style;
  final int goal; // みんなで集める目標の数
  const HirobaFestival(this.id, this.emoji, this.name, this.prompt, this.month,
      this.startDay, this.endDay, this.colors,
      {this.style = BackdropStyle.bunting, this.goal = 100,
      this.starters = const ['うちの子は', 'わたしは']});
  final List<String> starters;

  DateTime start(int year) => DateTime(year, month, startDay);
  DateTime end(int year) => DateTime(year, month, endDay, 23, 59, 59);

  HirobaRoom room(int year) => HirobaRoom(
        id: 'fes_$id',
        emoji: emoji,
        name: name,
        desc: prompt,
        colors: colors,
        style: style,
        span: '$id-$year',
        prompt: prompt,
        starters: starters,
        allowPhoto: true,
      );
}

const List<HirobaFestival> hirobaFestivals = [
  HirobaFestival('shogatsu', '🎍', 'お正月まつり', '今年、うちの子といっしょにしたいことは？', 1, 1, 7,
      [Color(0xFFE53935), Color(0xFFFFB300)]),
  HirobaFestival('neko', '🐱', 'ねこの日まつり', 'ねこの好きなところを、ひとこと！（ねこ好きならだれでも）', 2, 16, 22,
      [Color(0xFFFFB347), Color(0xFFFF7EB3)]),
  HirobaFestival('tanabata', '🎋', 'たなばたまつり', 'うちの子への願いごとを書こう', 7, 1, 7,
      [Color(0xFF141E30), Color(0xFF35577D)],
      style: BackdropStyle.stars),
  HirobaFestival('inu', '🐶', 'いぬの日まつり', 'いぬの好きなところを、ひとこと！（いぬ好きならだれでも）', 8, 20, 26,
      [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
  HirobaFestival('aigo', '🏠', '動物愛護週間', '動物のために、自分ができる小さなことは？', 9, 20, 26,
      [Color(0xFF43C6AC), Color(0xFF191654)],
      style: BackdropStyle.stars),
  HirobaFestival('halloween', '🎃', 'ハロウィンまつり', 'うちの子に仮装させるなら、何にする？', 10, 25, 31,
      [Color(0xFFFF8008), Color(0xFF4A00E0)],
      style: BackdropStyle.lantern),
  HirobaFestival('arigato', '💐', 'ありがとうまつり', 'うちの子に「ありがとう」を伝えよう', 11, 15, 23,
      [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
      starters: ['いつもありがとう！', 'うちの子へ：']),
  HirobaFestival('xmas', '🎄', 'クリスマスまつり', 'うちの子へのプレゼント、何にする？', 12, 18, 25,
      [Color(0xFF1D976C), Color(0xFFC0392B)],
      style: BackdropStyle.lantern),
];

// いま開いているお祭り（なければ null）
HirobaFestival? currentFestival(DateTime now) {
  for (final f in hirobaFestivals) {
    if (!now.isBefore(f.start(now.year)) && !now.isAfter(f.end(now.year))) return f;
  }
  return null;
}

// 次のお祭りと、その年
(HirobaFestival, int) nextFestival(DateTime now) {
  HirobaFestival? best;
  int bestYear = now.year;
  for (final y in [now.year, now.year + 1]) {
    for (final f in hirobaFestivals) {
      if (f.start(y).isAfter(now) &&
          (best == null || f.start(y).isBefore(best.start(bestYear)))) {
        best = f;
        bestYear = y;
      }
    }
    if (best != null) break;
  }
  return (best!, bestYear);
}

// ルール・アカウント削除で使う、部屋の名前の一覧
List<String> get allHirobaRoomIds => [
      ...legacyRoomIds,
      'photo',
      'challenge',
      'talk',
      ...animalGroups.map((g) => 'ani_${g.key}'),
      ...hirobaFestivals.map((f) => 'fes_${f.id}'),
    ];

// 友達をさそうときの文
const String inviteUrl = 'https://animatch-jp.github.io/';
