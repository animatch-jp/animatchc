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
  });
}

// いつでも開いている部屋
const List<HirobaRoom> hirobaRooms = [
  HirobaRoom(
    id: 'jiman',
    emoji: '🐶',
    name: 'うちの子じまん',
    desc: '「かわいい」を、ひとことで',
    colors: [Color(0xFFFF9A6B), Color(0xFFFF6F91)],
    starters: ['うちの子の今日のかわいいところ：', '見てください、うちの子が'],
  ),
  HirobaRoom(
    id: 'warai',
    emoji: '😂',
    name: 'くすっと話',
    desc: 'ペットのおもしろ話',
    colors: [Color(0xFFFFC94A), Color(0xFFFF9F43)],
    starters: ['さっきうちの子が', 'これ、うちだけ？'],
  ),
  HirobaRoom(
    id: 'soudan',
    emoji: '🔰',
    name: 'はじめての相談',
    desc: '小さな「どうしよう」を気軽に',
    colors: [Color(0xFF6BCB77), Color(0xFF2D9C8F)],
    style: BackdropStyle.stars,
    starters: ['はじめて飼う人です。', 'ちょっと聞きたいんですが、'],
  ),
  HirobaRoom(
    id: 'yoru',
    emoji: '🌙',
    name: '夜のまったり',
    desc: '寝る前に、のんびりおしゃべり',
    colors: [Color(0xFF3B3B98), Color(0xFF7B4397)],
    style: BackdropStyle.lantern,
    starters: ['こんばんは〜🌙', '今日のうちの子は'],
  ),
  HirobaRoom(
    id: 'hogo',
    emoji: '🏠',
    name: '保護っ子のはなし',
    desc: '保護犬・保護猫のこと、なんでも',
    colors: [Color(0xFF48C6EF), Color(0xFF6F86D6)],
    style: BackdropStyle.stars,
    starters: ['保護っ子をお迎えして', '保護犬・保護猫に興味があって'],
  ),
  HirobaRoom(
    id: 'suki',
    emoji: '💛',
    name: '飼ってなくても動物好き',
    desc: 'ペットがいなくても大歓迎',
    colors: [Color(0xFFF78CA0), Color(0xFFA18CD1)],
    starters: ['飼ってないけど、', 'いちばん好きな動物は'],
  ),
];

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

/* ---------------- 今日のお題 ---------------- */

const List<String> dailyTopics = [
  'うちの子の「寝相」、どんな感じ？',
  'ペットのおもしろい呼び名、ありますか？',
  '今日いちばんかわいかった瞬間は？',
  '好きな動物と、その理由をひとこと',
  'うちの子の好きなおやつは？',
  'ペットと行ってみたい場所は？',
  'うちの子の「くせ」を教えて',
  '子どものころ好きだった動物は？',
  'お散歩のとっておきの時間帯は？',
  '名前の由来、教えて！',
  'いつか飼ってみたい動物は？',
  'ペットにされてうれしかったことは？',
  '寒い日の、うちの子の過ごし方は？',
  'うちの子を、動物以外にたとえると？',
  '保護犬・保護猫について、知りたいことは？',
  'はじめてペットを迎えた日のこと、覚えてる？',
  'うちの子のチャームポイントは？',
  'ペットのおもちゃ、いちばん人気は？',
  '動物園・水族館で好きな場所は？',
  'ペットと一緒にしたい、小さな目標は？',
  'ペットのいる暮らしで、いちばん好きな時間は？',
  '今日の気分を、動物であらわすと？',
  '好きな動物の豆知識をひとつ',
  'うちの子の「おかえり」の迎え方は？',
  'もし動物と話せたら、何を聞いてみたい？',
  'うちの子の苦手なものは？',
  '最近ちょっとうれしかったこと（動物以外でもOK）',
  'うちの子の「おねだり」のしかたは？',
  '動物のどんなしぐさが好き？',
  'うちの子に、ひとことメッセージ！',
];

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

HirobaRoom todayTopicRoom(DateTime now) {
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(2026, 1, 1))
      .inDays;
  final topic = dailyTopics[days % dailyTopics.length];
  return HirobaRoom(
    id: 'topic',
    emoji: '💬',
    name: '今日のお題',
    desc: topic,
    colors: const [Color(0xFF00C9A7), Color(0xFF4D8076)],
    style: BackdropStyle.bunting,
    span: dayKey(now),
    prompt: topic,
    starters: const ['うちの場合は、', '飼っていないけど、'],
  );
}

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
      ...hirobaRooms.map((r) => r.id),
      'topic',
      ...hirobaFestivals.map((f) => 'fes_${f.id}'),
    ];

// 友達をさそうときの文
const String inviteUrl = 'https://animatch-jp.github.io/';
