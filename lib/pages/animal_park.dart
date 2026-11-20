// 下のタブ「イベント」＝どうぶつ公園（11/20 社長「芝生の公園で、いろんなペットが散歩して交流する感じ」）
//
// 調べて取り入れたこと
//  ・アメーバピグ：現実の場所に似せた空間・季節の飾り → 本物の日本の公園の形、季節と時間で景色が変わる
//  ・ピクミン ブルーム：来た人の跡が残ると世界がにぎやかになる → 今日来た子は、その日ずっと芝生にいる
//  ・Gather：行く場所を自分でえらべると入りやすい → テントやエリアに好きに入れる
//  ・黄色いリボン（Yellow Dog Project）：距離がほしい子の印 → 名札のリボン
//  ・ねこあつめ：来た子が手帳に残る・写真で広がる → 2回目で「公園の手帳」と記念写真
//
// データ：park/{日付}/visitors/{uid}（名札）、park/{日付}/visitors/{uid}/hellos/{送った人}（あいさつ）
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/blocked_users.dart';
import '../services/content_filter.dart';
import '../services/tab_reselect.dart';
import '../widgets/motion.dart';
import 'animal_map_page.dart';
import 'event_hub_page.dart' show AnimalGroupPage, MeetBoardPage;
import 'hiroba_data.dart';
import 'hiroba_room_page.dart';
import 'report_page.dart';

const _ink = Color(0xFF2B2B2B);
const _orange = Color(0xFFFF8A5B);
const _yellowRibbon = Color(0xFFFFD43B);

String parkDateKey([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

CollectionReference<Map<String, dynamic>> _visitors(String day) =>
    FirebaseFirestore.instance.collection('park').doc(day).collection('visitors');

bool _cloudinary(String? u) =>
    u != null && u.startsWith('https://res.cloudinary.com/dx2xqewxb/') && u.length <= 500;

// リボン（名札の気持ち）
class Ribbon {
  final String id;
  final String label;
  final String meaning;
  final Color color;
  const Ribbon(this.id, this.label, this.meaning, this.color);
}

const ribbons = [
  Ribbon('ok', 'あいさつOK', 'あいさつしてくれたらうれしい', Color(0xFF4CC38A)),
  Ribbon('slow', 'ゆっくりね', '黄色いリボン。少しずつ、そっとね', _yellowRibbon),
  Ribbon('look', '見るだけ', '今日は見て回るだけ。あいさつは届きません', Color(0xFF9AA5B1)),
];
Ribbon ribbonOf(String? id) => ribbons.firstWhere((r) => r.id == id, orElse: () => ribbons.first);

const helloPhrases = ['こんにちは🐾', 'かわいいね', 'なかよくしてね', 'またね👋', 'おつかれさま'];

// 動物ごとのエリア（生き物に合った場所）
const _areaNames = {
  'dog': 'ドッグラン',
  'cat': 'ねこの日だまり',
  'rabbit': 'うさぎの芝',
  'bird': '小鳥の木かげ',
  'small': '小さな広場',
  'ferret': 'トンネル広場',
  'reptile': '温室テント',
  'other': '水辺',
};

// 季節と時間
enum _Season { spring, summer, autumn, winter }

enum _DayTime { morning, day, evening, night }

_Season _seasonOf(DateTime d) {
  final m = d.month;
  if (m >= 3 && m <= 5) return _Season.spring;
  if (m >= 6 && m <= 8) return _Season.summer;
  if (m >= 9 && m <= 11) return _Season.autumn;
  return _Season.winter;
}

_DayTime _timeOf(DateTime d) {
  final h = d.hour;
  if (h >= 5 && h < 10) return _DayTime.morning;
  if (h >= 10 && h < 16) return _DayTime.day;
  if (h >= 16 && h < 18) return _DayTime.evening;
  return _DayTime.night;
}

String _sceneLabel(DateTime d) {
  const s = {_Season.spring: '春', _Season.summer: '夏', _Season.autumn: '秋', _Season.winter: '冬'};
  const t = {_DayTime.morning: 'の朝', _DayTime.day: 'の昼', _DayTime.evening: 'の夕方', _DayTime.night: 'の夜'};
  return '${s[_seasonOf(d)]}${t[_timeOf(d)]}';
}

// ============================================================
// 公園のページ
// ============================================================

class AnimalParkPage extends StatefulWidget {
  const AnimalParkPage({super.key});

  @override
  State<AnimalParkPage> createState() => _AnimalParkPageState();
}

class _AnimalParkPageState extends State<AnimalParkPage> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _walk;
  void _toTop() => TabReselect.toTop([_scroll]);

  @override
  void initState() {
    super.initState();
    TabReselect.tabs[2].addListener(_toTop);
    BlockedUsers.instance.ensureListening();
    _walk = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    TabReselect.tabs[2].removeListener(_toTop);
    _scroll.dispose();
    _walk.dispose();
    super.dispose();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = parkDateKey(now);
    final dt = _timeOf(now);
    final night = dt == _DayTime.night;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: night ? const Color(0xFF1F2A4A) : const Color(0xFFEAF7FF),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _visitors(day).orderBy('updatedAt', descending: true).limit(40).snapshots(),
        builder: (context, snap) {
          final docs = (snap.data?.docs ?? const [])
              .where((d) => !BlockedUsers.instance.isBlocked(d.id))
              .toList();
          final mine = docs.where((d) => d.id == _uid).toList();
          final me = mine.isEmpty ? null : mine.first;
          return Stack(children: [
            ListView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(0, top + 10, 0, 120),
              children: [
                _header(now, docs.length, night),
                const SizedBox(height: 10),
                _timetable(now, night),
                const SizedBox(height: 12),
                _ParkMap(
                  now: now,
                  visitors: docs,
                  myUid: _uid,
                  walk: _walk,
                  onTapVisitor: (d) => _openNameTag(d, me),
                ),
                const SizedBox(height: 18),
                _areas(night),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: me == null
                  ? _bigButton('🎫 受付で名札をつけて、公園に入る', () => _reception(null))
                  : _MyTagBar(day: day, me: me, onEdit: () => _reception(me.data())),
            ),
          ]);
        },
      ),
    );
  }

  Widget _header(DateTime now, int count, bool night) {
    final fg = night ? Colors.white : _ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('どうぶつ公園', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: fg)),
            const SizedBox(height: 2),
            Text('${_sceneLabel(now)}・今日 $count匹が来ています',
                style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.75))),
          ]),
        ),
        IconButton(
          tooltip: '公園の使い方',
          onPressed: _howTo,
          icon: Icon(Icons.help_outline_rounded, color: fg),
        ),
      ]),
    );
  }

  // 今日のタイムテーブル（いまの時間で、開いているイベントがわかる）
  Widget _timetable(DateTime now, bool night) {
    final list = <OnlineEvent>[...liveOnlineEvents(now), ...upcomingOnlineEvents(now)].take(5).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = list[i];
          final live = e.isLive(now);
          return Pressable(
            onTap: () => _openRoom(e.room),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: live ? _orange : const Color(0xFFDDE6EE), width: live ? 2 : 1),
              ),
              child: Row(children: [
                Text(e.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(live ? 'いま開催中' : whenText(e.start),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: live ? _orange : Colors.grey[600])),
                  Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _areas(bool night) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text('動物ごとのエリア',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: night ? Colors.white : _ink)),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in animalGroups)
            Pressable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalGroupPage(group: g))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: g.colors.last.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Text('${g.emoji} ${_areaNames[g.key] ?? g.name}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ink)),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _bigButton(String label, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(29),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  void _openRoom(HirobaRoom room) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: room)));

  void _howTo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('どうぶつ公園の使い方', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
          SizedBox(height: 12),
          Text('🎫 受付で名札をつけると、うちの子のアイコンが芝生に出ます。今日いっぱい、公園にいます。', style: TextStyle(height: 1.6)),
          Text('🎀 名札のリボンで、今日の気持ちを伝えられます。黄色いリボンは「ゆっくりね」の印です。', style: TextStyle(height: 1.6)),
          Text('👋 ほかの子のアイコンを押すと名札が見られて、あいさつを送れます。', style: TextStyle(height: 1.6)),
          Text('⛺ テントや看板を押すと、写真大会・話しあい会・お祭りなどに入れます。', style: TextStyle(height: 1.6)),
          Text('🔒 名札に出るのは、うちの子の名前と写真とリボンだけです。', style: TextStyle(height: 1.6)),
        ]),
      ),
    );
  }

  // 受付：名札を作る・直す
  Future<void> _reception(Map<String, dynamic>? current) async {
    final uid = _uid;
    if (uid == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReceptionSheet(uid: uid, current: current),
    );
    if (done == true && current == null && mounted) {
      showHappyBurst(context, message: '公園に入りました', sub: '芝生にうちの子が出ています', emoji: '🌳');
    }
  }

  // 名札を見る・あいさつする
  void _openNameTag(QueryDocumentSnapshot<Map<String, dynamic>> d, QueryDocumentSnapshot<Map<String, dynamic>>? me) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NameTagSheet(doc: d, me: me, myUid: _uid),
    );
  }
}

// ============================================================
// 公園の地図（絵）
// ============================================================

class _Spot {
  final String emoji;
  final String label;
  final Offset at; // 0〜1 の位置
  final VoidCallback onTap;
  const _Spot(this.emoji, this.label, this.at, this.onTap);
}

class _ParkMap extends StatelessWidget {
  const _ParkMap({
    required this.now,
    required this.visitors,
    required this.myUid,
    required this.walk,
    required this.onTapVisitor,
  });
  final DateTime now;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> visitors;
  final String? myUid;
  final Animation<double> walk;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onTapVisitor;

  OnlineEvent? _eventOf(String kind) {
    for (final e in [...liveOnlineEvents(now), ...upcomingOnlineEvents(now)]) {
      if (e.kind == kind) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    void open(HirobaRoom r) => Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: r)));
    final photo = _eventOf('photo');
    final talk = _eventOf('talk');
    final fes = _eventOf('fes');
    final challenge = _eventOf('challenge');
    final spots = <_Spot>[
      if (photo != null) _Spot('📸', '写真スポット', const Offset(0.2, 0.2), () => open(photo.room)),
      _Spot('💬', 'お悩み相談テント', const Offset(0.78, 0.17), () => open(const HirobaRoom(
            id: 'soudan',
            emoji: '💬',
            name: 'お悩み相談テント',
            desc: '飼い方のこと、先輩の飼い主さんに聞いてみよう',
            colors: [Color(0xFF7BC6FF), Color(0xFF4B8FE2)],
            starters: ['はじめて飼うので', 'こんなとき、どうしていますか？'],
          ))),
      if (fes != null)
        _Spot('🏮', '屋台・${fes.title}', const Offset(0.2, 0.55), () => open(fes.room))
      else if (challenge != null)
        _Spot('🚩', challenge.title, const Offset(0.2, 0.55), () => open(challenge.room)),
      if (talk != null) _Spot('🪑', 'ベンチ・話しあい会', const Offset(0.8, 0.5), () => open(talk.room)),
      _Spot('🏠', '保護団体テント', const Offset(0.22, 0.86), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnimalMapPage(initialCategory: 'org')));
      }),
      _Spot('🗺️', '案内所（会いに行く）', const Offset(0.78, 0.86), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetBoardPage()));
      }),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = w * 1.15;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CustomPaint(painter: _ParkPainter(_seasonOf(now), _timeOf(now)))),
          // 今日来た子（芝生の上をゆっくり歩く）
          for (var i = 0; i < visitors.length && i < 24; i++)
            _VisitorIcon(
              doc: visitors[i],
              index: i,
              mapW: w,
              mapH: h,
              walk: walk,
              isMe: visitors[i].id == myUid,
              onTap: () => onTapVisitor(visitors[i]),
            ),
          // テント・看板
          for (final s in spots)
            Positioned(
              left: (s.at.dx * w - 60).clamp(4.0, w - 124).toDouble(),
              top: s.at.dy * h - 26,
              child: Pressable(
                onTap: s.onTap,
                child: SizedBox(
                  width: 120,
                  child: Column(children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 30)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2D6C8)),
                      ),
                      child: Text(s.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
                    ),
                  ]),
                ),
              ),
            ),
          if (visitors.isEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: h * 0.36,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(14)),
                  child: const Text('今日いちばんに来る子になろう🐾',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ink)),
                ),
              ),
            ),
        ]),
      );
    });
  }
}

class _VisitorIcon extends StatelessWidget {
  const _VisitorIcon({
    required this.doc,
    required this.index,
    required this.mapW,
    required this.mapH,
    required this.walk,
    required this.isMe,
    required this.onTap,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final int index;
  final double mapW, mapH;
  final Animation<double> walk;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    // その子だけの場所（名前から決める。毎回同じ場所あたりにいる）
    final seed = doc.id.codeUnits.fold<int>(index * 7919, (a, b) => (a * 31 + b) & 0x7fffffff);
    final rnd = math.Random(seed);
    final bx = 0.14 + rnd.nextDouble() * 0.72;
    final by = 0.3 + rnd.nextDouble() * 0.45;
    final phase = rnd.nextDouble() * math.pi * 2;
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    final still = reduceMotion(context);
    const size = 48.0;
    return AnimatedBuilder(
      animation: walk,
      builder: (context, child) {
        final t = still ? 0.0 : walk.value * math.pi * 2;
        final x = bx * mapW + math.sin(t + phase) * 16 - size / 2;
        final y = by * mapH + math.cos(t * 0.7 + phase) * 6 - size / 2;
        return Positioned(left: x, top: y, child: child!);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: isMe ? _orange : Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
                image: _cloudinary(img) ? DecorationImage(image: NetworkImage(img!), fit: BoxFit.cover) : null,
              ),
              child: _cloudinary(img)
                  ? null
                  : Center(child: Text((d['emoji'] as String?) ?? '🐾', style: const TextStyle(fontSize: 24))),
            ),
            // リボン
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: ribbon.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
          ]),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
            child: Text(isMe ? 'うちの子' : ((d['petName'] as String?) ?? ''),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ink)),
          ),
        ]),
      ),
    );
  }
}

// 公園の絵（空・芝生・散歩道・池・木・ベンチ）。季節と時間で色が変わる
class _ParkPainter extends CustomPainter {
  _ParkPainter(this.season, this.time);
  final _Season season;
  final _DayTime time;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = switch (time) {
      _DayTime.morning => const Color(0xFFCFF0FF),
      _DayTime.day => const Color(0xFFB8E6FF),
      _DayTime.evening => const Color(0xFFFFC9A3),
      _DayTime.night => const Color(0xFF2E3E6E),
    };
    final grass = switch (time) {
      _DayTime.night => const Color(0xFF3F7D4E),
      _DayTime.evening => const Color(0xFF8CC96A),
      _ => const Color(0xFF9EE07A),
    };
    final grassDark = Color.lerp(grass, Colors.black, 0.12)!;
    final path = time == _DayTime.night ? const Color(0xFFB9A57A) : const Color(0xFFF6E6B8);
    final water = time == _DayTime.night ? const Color(0xFF4C6FA8) : const Color(0xFF8ED8F8);

    // 空
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.14), Paint()..color = sky);
    // 太陽・月
    canvas.drawCircle(Offset(w * 0.86, h * 0.06), 16,
        Paint()..color = time == _DayTime.night ? const Color(0xFFFFF4C2) : const Color(0xFFFFD84D));
    // 芝生
    final lawn = RRect.fromRectAndCorners(Rect.fromLTWH(0, h * 0.12, w, h * 0.88),
        topLeft: const Radius.circular(36), topRight: const Radius.circular(36));
    canvas.drawRRect(lawn, Paint()..color = grass);
    // 芝生のもよう
    final dot = Paint()..color = grassDark.withValues(alpha: 0.35);
    final r = math.Random(7);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * w, h * 0.15 + r.nextDouble() * h * 0.83), 1.6, dot);
    }
    // 散歩道（入口から上へ、ぐるっと）
    final p = Path()
      ..moveTo(w * 0.5, h)
      ..cubicTo(w * 0.5, h * 0.82, w * 0.12, h * 0.78, w * 0.18, h * 0.6)
      ..cubicTo(w * 0.24, h * 0.42, w * 0.82, h * 0.5, w * 0.8, h * 0.3)
      ..cubicTo(w * 0.78, h * 0.16, w * 0.3, h * 0.2, w * 0.2, h * 0.14);
    canvas.drawPath(
        p,
        Paint()
          ..color = path
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round);
    // 池と噴水
    final pond = Rect.fromCenter(center: Offset(w * 0.5, h * 0.42), width: w * 0.3, height: h * 0.11);
    canvas.drawOval(pond, Paint()..color = water);
    canvas.drawOval(pond.deflate(10), Paint()..color = Colors.white.withValues(alpha: 0.25));
    canvas.drawCircle(pond.center, 5, Paint()..color = Colors.white.withValues(alpha: 0.8));
    // 木（季節で葉の色）
    final leaf = switch (season) {
      _Season.spring => const Color(0xFFFFB7CF),
      _Season.summer => const Color(0xFF4CAF50),
      _Season.autumn => const Color(0xFFFF9A3C),
      _Season.winter => const Color(0xFFE6EEF5),
    };
    final leaf2 = switch (season) {
      _Season.autumn => const Color(0xFFE85D3A),
      _Season.spring => const Color(0xFFFFD6E4),
      _ => Color.lerp(leaf, Colors.black, 0.12)!,
    };
    const trees = [
      Offset(0.06, 0.2), Offset(0.94, 0.28), Offset(0.05, 0.42), Offset(0.95, 0.66),
      Offset(0.08, 0.72), Offset(0.62, 0.2), Offset(0.4, 0.62), Offset(0.92, 0.94), Offset(0.06, 0.96),
    ];
    for (var i = 0; i < trees.length; i++) {
      final c = Offset(trees[i].dx * w, trees[i].dy * h);
      canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 14), width: 6, height: 16),
          Paint()..color = const Color(0xFF8D6E63));
      canvas.drawCircle(c, 17, Paint()..color = i.isEven ? leaf : leaf2);
      canvas.drawCircle(c + const Offset(-7, -6), 9, Paint()..color = Colors.white.withValues(alpha: 0.18));
    }
    // 冬は雪、夜は街灯のあかり
    if (season == _Season.winter) {
      final snow = Paint()..color = Colors.white.withValues(alpha: 0.8);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h), 1.8, snow);
      }
    }
    if (time == _DayTime.night || time == _DayTime.evening) {
      for (final l in const [Offset(0.32, 0.7), Offset(0.68, 0.36), Offset(0.3, 0.24)]) {
        final c = Offset(l.dx * w, l.dy * h);
        canvas.drawCircle(c, 26, Paint()..color = const Color(0x33FFE08A));
        canvas.drawCircle(c, 5, Paint()..color = const Color(0xFFFFE08A));
      }
    }
    // 入口のアーチ
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.985), width: 90, height: 14),
            const Radius.circular(7)),
        Paint()..color = const Color(0xFF8D6E63));
  }

  @override
  bool shouldRepaint(_ParkPainter old) => old.season != season || old.time != time;
}

// ============================================================
// 受付（名札を作る）
// ============================================================

class _ReceptionSheet extends StatefulWidget {
  const _ReceptionSheet({required this.uid, this.current});
  final String uid;
  final Map<String, dynamic>? current;

  @override
  State<_ReceptionSheet> createState() => _ReceptionSheetState();
}

class _ReceptionSheetState extends State<_ReceptionSheet> {
  List<Map<String, dynamic>> _pets = [];
  int _pick = 0; // -1 = うちの子なしで入る
  String _ribbon = 'ok';
  String _emoji = '🐾';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ribbon = (widget.current?['ribbon'] as String?) ?? 'ok';
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final pets = await db.collection('users').doc(widget.uid).collection('pets').limit(10).get();
      _pets = pets.docs.map((d) => d.data()).toList();
      final curName = widget.current?['petName'] as String?;
      final idx = _pets.indexWhere((p) => p['name'] == curName);
      _pick = _pets.isEmpty ? -1 : (idx >= 0 ? idx : 0);
    } catch (_) {
      _pick = -1;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final pet = _pick >= 0 ? _pets[_pick] : null;
    // 名札には飼い主の名前を出さない。うちの子がいないときは「動物好きさん」
    final petName = ((pet?['name'] as String?) ?? '').trim();
    final name = petName.isNotEmpty ? petName : '動物好きさん';
    final type = ((pet?['type'] as String?) ?? '').trim();
    if (ContentFilter.blocked(context, [name])) return;
    setState(() => _saving = true);
    final img = pet?['imageUrl'] as String?;
    final data = <String, dynamic>{
      'petName': name.length > 20 ? name.substring(0, 20) : name,
      'ribbon': _ribbon,
      'emoji': _emoji,
      'updatedAt': FieldValue.serverTimestamp(),
      if (_cloudinary(img)) 'petImage': img,
      if (type.isNotEmpty) 'animal': type.length > 20 ? type.substring(0, 20) : type,
    };
    try {
      await _visitors(parkDateKey()).doc(widget.uid).set(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('名札のエラー: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名札を作れませんでした。もう一度ためしてください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: _loading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: _orange)))
            : SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.current == null ? '🎫 受付' : '🎫 名札を直す',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 4),
                  Text('名札に出るのは、うちの子の名前・写真・リボンだけです',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  const Text('いっしょに行く子', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (var i = 0; i < _pets.length; i++)
                        _petChoice(
                          selected: _pick == i,
                          label: (_pets[i]['name'] as String?) ?? '',
                          image: _pets[i]['imageUrl'] as String?,
                          onTap: () => setState(() => _pick = i),
                        ),
                      _petChoice(
                        selected: _pick == -1,
                        label: '動物好きとして',
                        emoji: _emoji,
                        onTap: () => setState(() => _pick = -1),
                      ),
                    ]),
                  ),
                  if (_pick == -1) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: [
                      for (final g in animalGroups)
                        ChoiceChip(
                          label: Text(g.emoji, style: const TextStyle(fontSize: 18)),
                          selected: _emoji == g.emoji,
                          onSelected: (_) => setState(() => _emoji = g.emoji),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  const Text('今日のリボン', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 8),
                  for (final r in ribbons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Pressable(
                        onTap: () => setState(() => _ribbon = r.id),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _ribbon == r.id ? r.color.withValues(alpha: 0.18) : const Color(0xFFF7F9FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _ribbon == r.id ? r.color : Colors.transparent, width: 2),
                          ),
                          child: Row(children: [
                            Container(width: 18, height: 18, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.label, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                                Text(r.meaning, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27))),
                      onPressed: _saving ? null : _save,
                      child: Text(widget.current == null ? '名札をつけて入る' : 'この名札にする',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }

  Widget _petChoice({required bool selected, required String label, String? image, String? emoji, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F5F8),
                border: Border.all(color: selected ? _orange : Colors.transparent, width: 3),
                image: _cloudinary(image) ? DecorationImage(image: NetworkImage(image!), fit: BoxFit.cover) : null,
              ),
              child: _cloudinary(image) ? null : Center(child: Text(emoji ?? '🐾', style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _ink)),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// 名札（ほかの子）・あいさつ
// ============================================================

class _NameTagSheet extends StatefulWidget {
  const _NameTagSheet({required this.doc, required this.me, required this.myUid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final QueryDocumentSnapshot<Map<String, dynamic>>? me;
  final String? myUid;

  @override
  State<_NameTagSheet> createState() => _NameTagSheetState();
}

class _NameTagSheetState extends State<_NameTagSheet> {
  String? _sent;
  bool _sending = false;

  Future<void> _hello(String phrase) async {
    final me = widget.me;
    final uid = widget.myUid;
    if (uid == null) return;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('先に受付で名札をつけてください')));
      return;
    }
    setState(() => _sending = true);
    final myImg = me.data()['petImage'] as String?;
    try {
      await widget.doc.reference.collection('hellos').doc(uid).set({
        'phrase': phrase,
        'fromPet': ((me.data()['petName'] as String?) ?? '').trim(),
        if (_cloudinary(myImg)) 'fromImage': myImg,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _sent = phrase);
    } catch (e) {
      debugPrint('あいさつのエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('あいさつを送れませんでした')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data();
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    final isMe = widget.doc.id == widget.myUid;
    final canHello = !isMe && ribbon.id != 'look';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF2F5F8),
              border: Border.all(color: ribbon.color, width: 5),
              image: _cloudinary(img) ? DecorationImage(image: NetworkImage(img!), fit: BoxFit.cover) : null,
            ),
            child: _cloudinary(img) ? null : Center(child: Text((d['emoji'] as String?) ?? '🐾', style: const TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 10),
          Text((d['petName'] as String?) ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
          if ((d['animal'] as String?)?.isNotEmpty == true)
            Text(d['animal'] as String, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: ribbon.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('🎀 ${ribbon.label}：${ribbon.meaning}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ink)),
          ),
          const SizedBox(height: 16),
          if (isMe)
            const Text('うちの子の名札です', style: TextStyle(color: _ink))
          else if (!canHello)
            const Text('今日は見て回るだけの日です。そっと見守ってね', style: TextStyle(color: _ink))
          else if (_sent != null)
            Text('「$_sent」を送りました', style: const TextStyle(fontWeight: FontWeight.bold, color: _ink))
          else ...[
            const Text('あいさつを送る', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final p in helloPhrases)
                ActionChip(
                  label: Text(p),
                  onPressed: _sending ? null : () => _hello(p),
                ),
            ]),
          ],
          if (!isMe) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(
                      userName: (d['petName'] as String?) ?? '',
                      targetUid: widget.doc.id,
                      contentLabel: 'どうぶつ公園の名札',
                      contentRef: widget.doc.reference.path,
                      contentText: (d['petName'] as String?) ?? '',
                    ),
                  ),
                );
              },
              child: Text('通報する', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          ],
        ]),
      ),
    );
  }
}

// 自分の名札と、届いたあいさつ
class _MyTagBar extends StatelessWidget {
  const _MyTagBar({required this.day, required this.me, required this.onEdit});
  final String day;
  final QueryDocumentSnapshot<Map<String, dynamic>> me;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final d = me.data();
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: me.reference.collection('hellos').orderBy('createdAt', descending: true).limit(30).snapshots(),
      builder: (context, snap) {
        final hellos = (snap.data?.docs ?? const [])
            .where((h) => !BlockedUsers.instance.isBlocked(h.id))
            .toList();
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F5F8),
                border: Border.all(color: ribbon.color, width: 3),
                image: _cloudinary(img) ? DecorationImage(image: NetworkImage(img!), fit: BoxFit.cover) : null,
              ),
              child: _cloudinary(img) ? null : Center(child: Text((d['emoji'] as String?) ?? '🐾')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: hellos.isEmpty ? null : () => _showHellos(context, hellos),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('${(d['petName'] as String?) ?? ''}と公園にいます',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ink)),
                  Text(hellos.isEmpty ? 'あいさつが届くと、ここに出ます' : '👋 あいさつが${hellos.length}件（見る）',
                      style: TextStyle(fontSize: 12, color: hellos.isEmpty ? Colors.grey[600] : _orange, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            TextButton(onPressed: onEdit, child: const Text('名札', style: TextStyle(color: _ink))),
          ]),
        );
      },
    );
  }

  void _showHellos(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> hellos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), children: [
          const Text('👋 届いたあいさつ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 10),
          for (final h in hellos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF2F5F8),
                backgroundImage: _cloudinary(h.data()['fromImage'] as String?)
                    ? NetworkImage(h.data()['fromImage'] as String)
                    : null,
                child: _cloudinary(h.data()['fromImage'] as String?) ? null : const Text('🐾'),
              ),
              title: Text((h.data()['fromPet'] as String?) ?? ''),
              subtitle: Text((h.data()['phrase'] as String?) ?? ''),
            ),
        ]),
      ),
    );
  }
}
