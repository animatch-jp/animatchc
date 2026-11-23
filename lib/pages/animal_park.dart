// 下のタブ「イベント」＝どうぶつ公園（11/20 社長「芝生の公園で、いろんなペットが散歩して交流する感じ」）
//
// 調べて取り入れたこと
//  ・アメーバピグ：現実の場所に似せた空間・季節の飾り → 本物の日本の公園の形、季節と時間で景色が変わる
//  ・ピクミン ブルーム：来た人の跡が残ると世界がにぎやかになる → 今日来た子は、その日ずっと芝生にいる
//  ・Gather：行く場所を自分でえらべると入りやすい → テントやエリアに好きに入れる
//  ・黄色いリボン（Yellow Dog Project）：距離がほしい子の印 → 名札のリボン
//  ・ねこあつめ：来た子が手帳に残る・写真で広がる → 2回目で「公園の手帳」と記念写真
//
// データ：users/{uid} の park（今日の名札・位置・ふきだし・あいさつの相手）。いまのルールのままで動く
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/blocked_users.dart';
import '../services/content_filter.dart';
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

DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
    FirebaseFirestore.instance.collection('users').doc(uid);

// ほかの人の users に書かれた park は、だれでも書けてしまうので、読むときに確かめる
class _Visitor {
  _Visitor(this.id, this._p);
  final String id;
  final Map<String, dynamic> _p;
  Map<String, dynamic> data() => _p;
  String get path => 'users/$id';
}

const _okEmojis = ['🐾', '🐶', '🐱', '🐰', '🐦', '🐹', '🦎', '🐟'];

_Visitor? _visitorOf(QueryDocumentSnapshot<Map<String, dynamic>> doc, String day) {
  final raw = doc.data()['park'];
  if (raw is! Map || raw['day'] != day) return null;
  String? str(String k, int max) {
    final v = raw[k];
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty || t.length > max ? null : t;
  }

  var name = str('petName', 20) ?? '動物好きさん';
  if (ContentFilter.check([name]) != null) name = '動物好きさん';
  var animal = str('animal', 20);
  if (animal != null && ContentFilter.check([animal]) != null) animal = null;
  final img = raw['petImage'];
  final ribbon = raw['ribbon'];
  final say = raw['say'];
  final emoji = raw['emoji'];
  final x = raw['x'], y = raw['y'];
  return _Visitor(doc.id, {
    'petName': name,
    'ribbon': ribbon is String && const ['ok', 'look', 'slow'].contains(ribbon) ? ribbon : 'ok',
    if (img is String && _cloudinary(img)) 'petImage': img,
    if (animal != null) 'animal': animal,
    'emoji': emoji is String && _okEmojis.contains(emoji) ? emoji : '🐾',
    if (x is num) 'x': x.toDouble().clamp(0.0, 1.0),
    if (y is num) 'y': y.toDouble().clamp(0.0, 1.0),
    if (say is String && sayPhrases.contains(say)) 'say': say,
    if (raw['sayAt'] is Timestamp) 'sayAt': raw['sayAt'],
    if (raw['to'] is String) 'to': raw['to'],
    if (raw['at'] is String && (raw['at'] as String).length <= 12) 'at': raw['at'],
  });
}

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
const sayPhrases = ['こんにちは🐾', 'いい天気だね', 'かわいいね', 'おさんぽ中', 'なかよくしてね', 'またね👋', 'おつかれさま'];

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
// 公園のページ（11/24 社長「最初の画面にペットはいらない」「押したら交流会みたいに」「ちゃんと描いた絵で」）
//  ・最初の画面：描いた公園の絵（assets/images/park.webp。もとの絵は tools/park_art/gen.py）だけ。ペットは出さない
//    場所の下に名前と「いま◯匹」「開催中」だけ出す
//  ・場所を押す → その場所に近づいた画面（交流会）。そこに来ている子が集まって、歩く・ひとこと・あいさつ・いっしょに歩く
//    その場所のイベントや機能にも、そこから入る
//  ・タブを開いたら、名札なしで自動で公園に入る（うちの子を押すと名札を直せる）
// データ：users/{uid}.park（day・名札・at＝いる場所・x,y＝その場所の中の位置・say/sayAt/to）
// ============================================================

const _art = 'assets/images/park.webp';
const _artW = 1200.0, _artH = 2400.0;

// アプリのチェック用のお試し表示（テスト用のページだけ。PARK_PREVIEW をつけてビルドしたときだけ使える）
const parkPreviewAllowed = bool.fromEnvironment('PARK_PREVIEW');

class _Spot {
  final String key, label;
  final double ax, ay; // 絵の中の建物の位置
  final double lx, ly; // 名前を出す位置
  const _Spot(this.key, this.label, this.ax, this.ay, this.lx, this.ly);
}

const _spots = [
  _Spot('areas', 'どうぶつエリア', 600, 300, 600, 445),
  _Spot('photo', '写真スタジオ', 230, 700, 230, 830),
  _Spot('yatai', '屋台', 970, 700, 970, 830),
  _Spot('tent', '相談テント', 200, 1330, 200, 1450),
  _Spot('bench', 'ベンチ広場', 990, 1330, 990, 1500),
  _Spot('org', '保護団体の家', 250, 1880, 230, 2055),
  _Spot('info', '案内所', 950, 1880, 950, 2045),
];

const _soudanRoom = HirobaRoom(
  id: 'soudan',
  emoji: '💬',
  name: 'お悩み相談テント',
  desc: '飼い方のこと、先輩の飼い主さんに聞いてみよう',
  colors: [Color(0xFF7BC6FF), Color(0xFF4B8FE2)],
  starters: ['はじめて飼うので', 'こんなとき、どうしていますか？'],
);

// 動物ごとの場所の写真（Unsplash）
const _groupPhotos = {
  'dog': 'photo-1704895598909-dd19e72fc3ae',
  'cat': 'photo-1574158622682-e40e69881006',
  'rabbit': 'photo-1630535590772-ed554b4f4096',
  'bird': 'photo-1594911588637-c9e891bd7858',
  'small': 'photo-1721327900411-b315dce4388e',
  'reptile': 'photo-1633767319476-d43c16b828c4',
  'other': 'photo-1625369708811-65ebfc5ca632',
};

String _spotOfEvent(OnlineEvent e) => switch (e.kind) {
      'photo' => 'photo',
      'talk' => 'bench',
      _ => 'yatai',
    };

OnlineEvent? _eventAt(String spot, DateTime now) {
  for (final e in [...liveOnlineEvents(now), ...upcomingOnlineEvents(now)]) {
    if (_spotOfEvent(e) == spot) return e;
  }
  return null;
}

Color _tintOf(DateTime now) => switch (_timeOf(now)) {
      _DayTime.morning => const Color(0x14FFDCAA),
      _DayTime.day => const Color(0x00000000),
      _DayTime.evening => const Color(0x33FF783C),
      _DayTime.night => const Color(0x590F1946),
    };

Stream<List<_Visitor>> _parkStream(String day) => FirebaseFirestore.instance
    .collection('users')
    .where('park.day', isEqualTo: day)
    .limit(80)
    .snapshots()
    .map((q) => q.docs
        .map((d) => _visitorOf(d, day))
        .whereType<_Visitor>()
        .where((v) => !BlockedUsers.instance.isBlocked(v.id))
        .toList());

// ---------- 最初の画面 ----------

class AnimalParkPage extends StatefulWidget {
  const AnimalParkPage({super.key, this.preview = false});
  final bool preview;

  @override
  State<AnimalParkPage> createState() => _AnimalParkPageState();
}

class _AnimalParkPageState extends State<AnimalParkPage> {
  final String _day = parkDateKey();
  StreamSubscription<List<_Visitor>>? _sub;
  List<_Visitor> _all = [];
  bool _autoTried = false;

  String? get _uid => widget.preview ? 'me' : FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.preview) {
      _all = [
        _Visitor('a', {'petName': 'こむぎ', 'at': 'bench'}),
        _Visitor('b', {'petName': 'もち', 'at': 'bench'}),
        _Visitor('c', {'petName': 'ぎん', 'at': 'photo'}),
      ];
      return;
    }
    BlockedUsers.instance.ensureListening();
    _sub = _parkStream(_day).listen((v) {
      _all = v;
      if (!v.any((d) => d.id == _uid)) _autoEnter();
      if (mounted) setState(() {});
    }, onError: (e) => debugPrint('公園のエラー: $e'));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // アプリを入れている人は、タブを開いたらそのまま公園に入る
  Future<void> _autoEnter() async {
    final uid = _uid;
    if (_autoTried || widget.preview || uid == null) return;
    _autoTried = true;
    try {
      final pets = await _userDoc(uid).collection('pets').limit(1).get();
      final p = pets.docs.isEmpty ? null : pets.docs.first.data();
      final name = ((p?['name'] as String?) ?? '').trim();
      final type = ((p?['type'] as String?) ?? '').trim();
      final img = p?['imageUrl'] as String?;
      await _userDoc(uid).update({
        'park': {
          'day': _day,
          'petName': name.isEmpty || name.length > 20 ? '動物好きさん' : name,
          'ribbon': 'ok',
          'emoji': '🐾',
          if (_cloudinary(img)) 'petImage': img,
          if (type.isNotEmpty && type.length <= 20) 'animal': type,
          'at': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      debugPrint('公園に入れませんでした: $e');
    }
  }

  void _open(_Spot s) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => _ParkScenePage(spot: s, preview: widget.preview),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(c), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF8FD068),
      body: LayoutBuilder(builder: (context, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final sc = math.max(W / _artW, H / _artH);
        final ox = (W - _artW * sc) / 2, oy = (H - _artH * sc) / 2;
        Offset at(double x, double y) => Offset(ox + x * sc, oy + y * sc);
        return Stack(children: [
          Positioned.fill(child: Image.asset(_art, fit: BoxFit.cover)),
          Positioned.fill(child: IgnorePointer(child: ColoredBox(color: _tintOf(now)))),
          // 建物を押す
          for (final s in _spots)
            Positioned(
              left: at(s.ax, s.ay).dx - 150 * sc,
              top: at(s.ax, s.ay).dy - 160 * sc,
              width: 300 * sc,
              height: (s.ly - s.ay + 200) * sc,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _open(s)),
            ),
          for (final s in _spots) _label(s, at(s.lx, s.ly), now),
          Positioned(
            left: 12,
            right: 12,
            top: top + 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xF2FFFAF4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3))],
              ),
              child: Row(children: [
                const Text('どうぶつ公園', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${_sceneLabel(now)}・場所を押すと入れます',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _label(_Spot s, Offset p, DateTime now) {
    final n = _all.where((v) => v.data()['at'] == s.key).length;
    final e = (s.key == 'photo' || s.key == 'yatai' || s.key == 'bench') ? _eventAt(s.key, now) : null;
    final live = e != null && e.isLive(now);
    return Positioned(
      left: p.dx - 80,
      top: p.dy - 14,
      width: 160,
      child: IgnorePointer(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xF5FFFAF4),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(s.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _ink)),
              if (n > 0) ...[
                const SizedBox(width: 5),
                Text('$n匹', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _orange)),
              ],
            ]),
          ),
          if (live)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE84A5F), borderRadius: BorderRadius.circular(9)),
              child: const Text('開催中', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
        ]),
      ),
    );
  }
}

// ---------- 場所の中（交流会） ----------

class _Mover {
  double x, y;
  double tx, ty;
  double hx, hy;
  double wait = 0;
  bool walking = false;
  _Mover(this.x, this.y)
      : tx = x,
        ty = y,
        hx = x,
        hy = y;
}

class _Paw {
  final double x, y;
  final Duration t;
  const _Paw(this.x, this.y, this.t);
}

class _ParkScenePage extends StatefulWidget {
  const _ParkScenePage({required this.spot, this.preview = false});
  final _Spot spot;
  final bool preview;

  @override
  State<_ParkScenePage> createState() => _ParkScenePageState();
}

class _ParkScenePageState extends State<_ParkScenePage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Duration _now = Duration.zero;
  StreamSubscription<List<_Visitor>>? _sub;
  List<_Visitor> _docs = [];
  final Map<String, _Mover> _m = {};
  final Map<String, String> _bubbleText = {};
  final Map<String, DateTime> _bubbleAt = {};
  final Map<String, DateTime> _sayShown = {};
  final List<_Paw> _paws = [];
  final Map<String, Map<String, dynamic>> _met = {};
  final _rnd = math.Random();
  final String _day = parkDateKey();
  Size _size = Size.zero;
  bool _still = false;
  String? _follow;
  double _pawDist = 0;
  Timer? _posTimer;
  DateTime _lastFollowWrite = DateTime.fromMillisecondsSinceEpoch(0);

  _Spot get s => widget.spot;
  String? get _uid => widget.preview ? 'me' : FirebaseAuth.instance.currentUser?.uid;

  _Visitor? get _meDoc {
    for (final d in _docs) {
      if (d.id == _uid) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    if (widget.preview) {
      _docs = [
        _Visitor('me', {'petName': 'うちの子', 'ribbon': 'ok', 'emoji': '🐶', 'x': .5, 'y': .62}),
        _Visitor('a', {'petName': 'こむぎ', 'ribbon': 'ok', 'emoji': '🐶', 'animal': '柴犬', 'x': .3, 'y': .55}),
        _Visitor('b', {'petName': 'もち', 'ribbon': 'slow', 'emoji': '🐰', 'animal': 'うさぎ', 'x': .72, 'y': .52}),
        _Visitor('c', {'petName': 'ぎん', 'ribbon': 'look', 'emoji': '🐱', 'animal': 'ねこ', 'x': .75, 'y': .66}),
      ];
      for (final d in _docs) {
        _m[d.id] = _Mover((d.data()['x'] as double), (d.data()['y'] as double));
      }
      _bubble('a', 'いい天気だね');
      return;
    }
    BlockedUsers.instance.ensureListening();
    _enter();
    _sub = _parkStream(_day).listen(_onVisitors, onError: (e) => debugPrint('公園のエラー: $e'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = reduceMotion(context);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    _posTimer?.cancel();
    final uid = _uid;
    if (!widget.preview && uid != null) {
      _userDoc(uid).update({'park.at': '', 'park.updatedAt': FieldValue.serverTimestamp()}).catchError((e) {
        debugPrint('公園を出るときのエラー: $e');
      });
    }
    super.dispose();
  }

  // この場所に入る（うちの子が、この場所の芝生に出てくる）
  Future<void> _enter() async {
    final uid = _uid;
    if (uid == null) return;
    final x = .3 + _rnd.nextDouble() * .4, y = .52 + _rnd.nextDouble() * .14;
    _m[uid] = _Mover(.5, .95)
      ..tx = x
      ..ty = y;
    try {
      await _userDoc(uid).update({
        'park.at': s.key,
        'park.x': double.parse(x.toStringAsFixed(3)),
        'park.y': double.parse(y.toStringAsFixed(3)),
        'park.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('場所に入れませんでした: $e');
    }
  }

  void _onVisitors(List<_Visitor> all) {
    final docs = all.where((v) => v.data()['at'] == s.key || v.id == _uid).toList();
    final ids = docs.map((d) => d.id).toSet();
    _m.removeWhere((k, _) => !ids.contains(k) && k != _uid);
    for (final d in docs) {
      final data = d.data();
      final x = ((data['x'] as num?)?.toDouble() ?? .5).clamp(0.0, 1.0);
      final y = ((data['y'] as num?)?.toDouble() ?? .7).clamp(0.0, 1.0);
      final o = _m[d.id];
      if (o == null) {
        _m[d.id] = _Mover(x, y);
      } else if (d.id != _uid) {
        if ((o.hx - x).abs() > .001 || (o.hy - y).abs() > .001) {
          o.tx = x;
          o.ty = y;
          o.wait = 6;
        }
        o.hx = x;
        o.hy = y;
      }
      final say = data['say'] as String?;
      final at = (data['sayAt'] as Timestamp?)?.toDate();
      if (say != null && at != null && _sayShown[d.id] != at) {
        _sayShown[d.id] = at;
        final fresh = DateTime.now().difference(at).inSeconds.abs() < 60;
        if (d.id != _uid && fresh) {
          _bubble(d.id, say);
          if (data['to'] == _uid && _uid != null) {
            _met[d.id] = {'name': data['petName'], 'image': data['petImage'], 'phrase': say};
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${data['petName']}が「$say」とあいさつしてくれました。押すと、かえせます'),
                duration: const Duration(seconds: 3),
              ));
            }
          }
        }
      }
    }
    if (_follow != null && !ids.contains(_follow)) _follow = null;
    _docs = docs;
    if (mounted) setState(() {});
  }

  void _bubble(String id, String text) {
    _bubbleText[id] = text;
    _bubbleAt[id] = DateTime.now();
  }

  void _writePos(double x, double y) {
    final uid = _uid;
    if (uid == null || widget.preview) return;
    _posTimer?.cancel();
    _posTimer = Timer(const Duration(milliseconds: 400), () {
      _userDoc(uid).update({
        'park.x': double.parse(x.toStringAsFixed(3)),
        'park.y': double.parse(y.toStringAsFixed(3)),
        'park.updatedAt': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint('位置のエラー: $e'));
    });
  }

  Future<void> _say(String phrase) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _bubble(uid, phrase));
    if (widget.preview) return;
    try {
      await _userDoc(uid).update({
        'park.say': phrase,
        'park.sayAt': FieldValue.serverTimestamp(),
        'park.to': FieldValue.delete(),
        'park.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ふきだしのエラー: $e');
    }
  }

  // 歩ける場所（画面の中の芝生と広場。上の建物と下のボタンにはかからない）
  static const _minY = .46, _maxY = .7;

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _now = now;
    if (_size.isEmpty) return;
    final W = _size.width, H = _size.height;
    final uid = _uid;
    for (final e in _m.entries) {
      final o = e.value;
      final isMe = e.key == uid;
      if (isMe && _follow != null) {
        final f = _m[_follow];
        if (f != null) {
          o.tx = (f.x + 44 / W).clamp(0.06, 0.94);
          o.ty = (f.y + 10 / H).clamp(_minY, _maxY);
        }
      }
      final dx = (o.tx - o.x) * W, dy = (o.ty - o.y) * H;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > 2) {
        final st = _still ? d : math.min(d, (isMe ? 130.0 : 45.0) * dt);
        o.x += dx / d * st / W;
        o.y += dy / d * st / H;
        o.walking = !_still;
        if (isMe && !_still) {
          _pawDist += st;
          if (_pawDist > 20) {
            _pawDist = 0;
            _paws.add(_Paw(o.x, o.y, now));
          }
        }
      } else {
        o.walking = false;
        if (!isMe && !_still) {
          o.wait -= dt;
          if (o.wait <= 0) {
            o.tx = (o.hx + (_rnd.nextDouble() - .5) * 60 / W).clamp(0.06, 0.94);
            o.ty = (o.hy + (_rnd.nextDouble() - .5) * 40 / H).clamp(_minY, _maxY);
            o.wait = 3 + _rnd.nextDouble() * 5;
          }
        }
      }
    }
    _paws.removeWhere((p) => now - p.t > const Duration(seconds: 3));
    final me = uid == null ? null : _m[uid];
    if (_follow != null && me != null && me.walking &&
        DateTime.now().difference(_lastFollowWrite) > const Duration(milliseconds: 2500)) {
      _lastFollowWrite = DateTime.now();
      _writePos(me.tx, me.ty);
    }
    if (mounted) setState(() {});
  }

  void _walkTo(double fx, double fy, {bool keepFollow = false}) {
    final uid = _uid;
    final me = uid == null ? null : _m[uid];
    if (me == null) return;
    if (!keepFollow) _follow = null;
    me.tx = fx.clamp(0.06, 0.94);
    me.ty = fy.clamp(_minY, _maxY);
    _writePos(me.tx, me.ty);
  }

  // ---------- この場所でできること ----------

  void _go(Widget page) {
    if (widget.preview) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('（お試し表示）ここで中に入ります')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  ({String desc, String? button, VoidCallback? onTap}) _what(DateTime now) {
    switch (s.key) {
      case 'areas':
        return (desc: '動物ごとの場所への入口です。下からえらぶと、同じ動物を飼っている人の部屋と会に行けます。', button: null, onTap: null);
      case 'tent':
        return (
          desc: '飼い方で困ったことを、先輩の飼い主さんに聞けるテントです。',
          button: '相談テントに入る',
          onTap: () => _go(HirobaRoomPage(room: _soudanRoom))
        );
      case 'org':
        return (
          desc: '保護団体の人たちの家です。新しい家族をさがしている子に会えます。',
          button: '保護団体を見る',
          onTap: () => _go(const AnimalMapPage(initialCategory: 'org'))
        );
      case 'info':
        return (
          desc: '近くで会うイベント（18歳以上）をさがしたり、ひらいたりできます。',
          button: '会うイベントを見る',
          onTap: () => _go(const MeetBoardPage())
        );
      default:
        final e = _eventAt(s.key, now);
        if (e == null) {
          return (
            desc: s.key == 'photo'
                ? '写真大会をする場所です。いまは写真大会はありません。'
                : s.key == 'bench'
                    ? '話しあい会をする広場です。いまは話しあい会はありません。'
                    : 'お祭りやチャレンジのときに屋台が出ます。いまはお休みです。',
            button: null,
            onTap: null
          );
        }
        final live = e.isLive(now);
        return (
          desc: live ? 'いま「${e.title}」をやっています。' : '${whenText(e.start)}から「${e.title}」があります。',
          button: live ? '${e.title}に参加する' : 'のぞいてみる',
          onTap: () => _go(HirobaRoomPage(room: e.room))
        );
    }
  }

  // ---------- 画面 ----------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF83C55F),
      body: LayoutBuilder(builder: (context, c) {
        _size = c.biggest;
        final W = _size.width, H = _size.height;
        // 絵を近づける：建物が画面の上のほうに来るように
        final sc = W / 560;
        var left = W / 2 - s.ax * sc;
        var topOff = H * .3 - s.ay * sc;
        left = left.clamp(W - _artW * sc, 0.0);
        topOff = math.min(topOff, 0.0); // 下の場所は、絵の下に芝生を足して、建物の位置をそろえる
        final uid = _uid;
        final order = _m.keys.toList()..sort((a, b) => _m[a]!.y.compareTo(_m[b]!.y));
        final byId = {for (final d in _docs) d.id: d};
        final what = _what(now);
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _walkTo(d.localPosition.dx / W, d.localPosition.dy / H),
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned(
                  left: left,
                  top: topOff,
                  width: _artW * sc,
                  height: _artH * sc,
                  child: Image.asset(_art, fit: BoxFit.fill),
                ),
                // 下のほうは、ほかの建物が気にならないように、芝生の色でぼかす
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x0083C55F), Color(0x0083C55F), Color(0xF283C55F), Color(0xFF83C55F)],
                          stops: [0, .62, .76, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: IgnorePointer(child: ColoredBox(color: _tintOf(now)))),
                for (final p in _paws)
                  Positioned(
                    left: p.x * W - 5,
                    top: p.y * H - 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - (_now - p.t).inMilliseconds / 3000).clamp(0.0, 1.0),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: Color(0xC0FFFFFF), shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                if (_follow != null && uid != null && _m[uid] != null && _m[_follow] != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LeashPainter(
                          Offset(_m[uid]!.x * W, _m[uid]!.y * H - 28),
                          Offset(_m[_follow]!.x * W, _m[_follow]!.y * H - 28),
                        ),
                      ),
                    ),
                  ),
                for (final id in order)
                  if (byId[id] != null || id == uid) _petIcon(byId[id], id, _m[id]!, id == uid),
              ]),
            ),
          ),
          // 上：もどる・場所の名前・いる子の数
          Positioned(
            left: 10,
            right: 12,
            top: top + 8,
            child: Row(children: [
              Material(
                color: const Color(0xF2FFFAF4),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: '公園にもどる',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFFAF4),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  child: Row(children: [
                    Text(s.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          _docs.length <= 1 ? 'まだほかにだれもいません' : 'いま ${_docs.length}匹が来ています',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          // 下：この場所でできること
          Positioned(left: 12, right: 12, bottom: 12, child: _panel(what)),
        ]);
      }),
    );
  }

  Widget _panel(({String desc, String? button, VoidCallback? onTap}) what) {
    Widget small(String label, VoidCallback onTap) => Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE6DCD0)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFAF4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(what.desc, style: const TextStyle(fontSize: 13, height: 1.5, color: _ink)),
        if (s.key == 'areas') ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final g in animalGroups)
                GestureDetector(
                  onTap: () => _go(AnimalGroupPage(group: g)),
                  child: SizedBox(
                    width: 70,
                    child: Column(children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF2EBE2),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))],
                          image: _groupPhotos[g.key] == null
                              ? null
                              : DecorationImage(
                                  image: NetworkImage(
                                      'https://images.unsplash.com/${_groupPhotos[g.key]}?auto=format&fit=crop&crop=entropy&w=160&h=160&q=70'),
                                  fit: BoxFit.cover),
                        ),
                        child: _groupPhotos[g.key] == null ? Center(child: Text(g.emoji, style: const TextStyle(fontSize: 24))) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
        if (what.button != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: what.onTap,
              child: Text(what.button!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          small('💬 ひとこと', _sayMenu),
          const SizedBox(width: 8),
          small('📖 手帳 ${_met.length}', _book),
        ]),
      ]),
    );
  }

  Widget _petIcon(_Visitor? doc, String id, _Mover o, bool isMe) {
    final d = doc?.data() ?? const <String, dynamic>{};
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    final size = isMe ? 56.0 : 50.0;
    final hop = o.walking ? math.sin(_now.inMilliseconds / 90) * 3 - 3 : 0.0;
    final at = _bubbleAt[id];
    final bubble = at != null && DateTime.now().difference(at).inMilliseconds < 4000 ? _bubbleText[id] : null;
    return Positioned(
      left: o.x * _size.width - 60,
      top: o.y * _size.height - size - 40,
      width: 120,
      child: GestureDetector(
        onTap: isMe ? () => _editTag(d) : (doc == null ? null : () => _openTag(doc)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 32,
            child: bubble == null
                ? null
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Text(bubble,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Transform.translate(
            offset: Offset(0, hop),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: isMe ? _orange : Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 3))],
                  image: _cloudinary(img) ? DecorationImage(image: NetworkImage(img!), fit: BoxFit.cover) : null,
                ),
                child: _cloudinary(img)
                    ? null
                    : Center(child: Text((d['emoji'] as String?) ?? '🐾', style: const TextStyle(fontSize: 24))),
              ),
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: ribbon.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ]),
          ),
          Container(
            width: 36,
            height: 7,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .22), borderRadius: BorderRadius.circular(20)),
          ),
          Text(isMe ? 'うちの子' : ((d['petName'] as String?) ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0xCC000000), blurRadius: 3)],
              )),
        ]),
      ),
    );
  }

  // ---------- 下から出る紙 ----------

  Future<T?> _sheet<T>(Widget child) => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFFFAF4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .75),
            child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: child),
          ),
        ),
      );

  void _sayMenu() {
    _sheet(Builder(
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('💬 ひとこと', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 4),
        Text('うちの子の頭の上に出ます。ここにいるみんなに見えます。', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in sayPhrases)
            ActionChip(
              label: Text(p, style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                Navigator.pop(ctx);
                _say(p);
              },
            ),
        ]),
      ]),
    ));
  }

  void _book() {
    _sheet(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('📖 公園の手帳', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 4),
      Text('今日あいさつした子・あいさつしてくれた子が残ります。', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      const SizedBox(height: 10),
      if (_met.isEmpty)
        const Text('まだだれもいません。ほかの子を押して、あいさつしてみよう。')
      else
        for (final e in _met.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF2F5F8),
              backgroundImage: _cloudinary(e.value['image'] as String?) ? NetworkImage(e.value['image'] as String) : null,
              child: _cloudinary(e.value['image'] as String?) ? null : const Text('🐾'),
            ),
            title: Text((e.value['name'] as String?) ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text((e.value['phrase'] as String?) ?? ''),
          ),
    ]));
  }

  Future<void> _editTag(Map<String, dynamic> current) async {
    final uid = _uid;
    if (uid == null || widget.preview) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReceptionSheet(uid: uid, current: {...current, 'at': s.key}),
    );
  }

  void _openTag(_Visitor d) {
    if (widget.preview) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NameTagSheet(
        doc: d,
        me: _meDoc,
        myUid: _uid,
        following: _follow == d.id,
        onWalk: () => _toggleFollow(d),
        onSent: (phrase) {
          final uid = _uid;
          final o = _m[d.id];
          if (uid == null || o == null) return;
          _met[d.id] = {'name': d.data()['petName'], 'image': d.data()['petImage'], 'phrase': phrase};
          setState(() => _bubble(uid, phrase));
          _walkTo(o.x - 46 / _size.width, o.y + 8 / _size.height, keepFollow: true);
        },
      ),
    );
  }

  void _toggleFollow(_Visitor d) {
    if (_follow == d.id) {
      setState(() => _follow = null);
      _say('またね👋');
      return;
    }
    setState(() {
      _follow = d.id;
      _met.putIfAbsent(d.id, () => {'name': d.data()['petName'], 'image': d.data()['petImage'], 'phrase': 'いっしょに歩いた'});
    });
    _say('おさんぽ中');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.data()['petName'] ?? ''}といっしょに歩いています'), duration: const Duration(seconds: 2)),
    );
  }
}

class _LeashPainter extends CustomPainter {
  _LeashPainter(this.a, this.b);
  final Offset a, b;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = d / len;
    for (double t = 0; t < len; t += 10) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + 5, len), paint);
    }
  }

  @override
  bool shouldRepaint(_LeashPainter old) => old.a != a || old.b != b;
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
      // 公園の中の位置。はじめて入るときは入口から
      'x': (widget.current?['x'] as num?)?.toDouble() ?? 0.5,
      'y': (widget.current?['y'] as num?)?.toDouble() ?? 0.97,
      'at': (widget.current?['at'] as String?) ?? '',
    };
    try {
      await _userDoc(widget.uid).update({'park': {...data, 'day': parkDateKey()}});
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
  const _NameTagSheet({
    required this.doc,
    required this.me,
    required this.myUid,
    this.following = false,
    this.onWalk,
    this.onSent,
  });
  final _Visitor doc;
  final _Visitor? me;
  final String? myUid;
  final bool following;
  final VoidCallback? onWalk; // いっしょに歩く（もう一度押すとやめる）
  final void Function(String phrase)? onSent;

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
    try {
      // うちの子の頭の上に、あいさつのふきだし。相手には「あいさつしてくれました」と出る
      await _userDoc(uid).update({
        'park.say': phrase,
        'park.sayAt': FieldValue.serverTimestamp(),
        'park.to': widget.doc.id,
        'park.updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _sent = phrase);
      widget.onSent?.call(phrase);
      if (mounted) Navigator.pop(context);
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
          if (!isMe && widget.me != null && ribbon.id == 'ok' && widget.onWalk != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: widget.following ? Colors.grey[600] : _orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onWalk!();
                },
                child: Text(widget.following ? 'いっしょに歩くのをやめる' : '🐾 いっしょに歩く',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
          if (!isMe && ribbon.id == 'slow')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('黄色いリボンの子とは、あいさつだけにしましょう', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ),
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
                      contentRef: widget.doc.path,
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


// テスト用のページだけで使う、交流会の画面のお試し表示（ベンチ広場）
class ParkScenePreview extends StatelessWidget {
  const ParkScenePreview({super.key});

  @override
  Widget build(BuildContext context) => _ParkScenePage(spot: _spots[4], preview: true);
}
