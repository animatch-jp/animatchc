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
// 公園のページ（11/24 社長「最初は一つの画面で、あまり動かさない」「名前より、イラストや家の方が分かりやすい」
//   「画面を動かすのは機能ごとに分ける」「アプリを入れている人は、そのまま公園に入るように」）
//  ・公園は1画面に全部入る。ずらさない
//  ・場所は絵（📸 写真スポット・🏮 屋台・⛺ 相談テント・🪑 ベンチ・🏠 保護団体の家・🗺️ 案内所・🌳 どうぶつエリア）
//  ・場所を押す → うちの子がそこまで歩いて、着いたらその機能の画面に入る
//  ・タブを開いたら、名札なしで自動で公園に入る（うちの子を押すと名札を直せる）
//  ・芝生を押すと歩く。ひとことは頭の上のふきだし。ほかの子を押すと、あいさつ・いっしょに歩く
// ============================================================

const _bgPhoto =
    'https://images.unsplash.com/photo-1759750909584-b96825e93de8?auto=format&fit=crop&w=1200&q=70';
const _bgCredit = '写真：Maxim Nikiforov / Unsplash';

// アプリのチェック用のお試し表示（テスト用のページだけ。PARK_PREVIEW をつけてビルドしたときだけ使える）
const parkPreviewAllowed = bool.fromEnvironment('PARK_PREVIEW');

class _Spot {
  final String key, emoji, label;
  final double x, y; // 画面の中の位置（0〜1）
  const _Spot(this.key, this.emoji, this.label, this.x, this.y);
}

const _spots = [
  _Spot('areas', '🌳', 'どうぶつエリア', .5, .19),
  _Spot('photo', '📸', '写真スポット', .17, .27),
  _Spot('yatai', '🏮', '屋台', .83, .27),
  _Spot('tent', '⛺', '相談テント', .14, .5),
  _Spot('bench', '🪑', 'ベンチ', .86, .5),
  _Spot('org', '🏠', '保護団体の家', .2, .75),
  _Spot('info', '🗺️', '案内所', .8, .75),
];

const _soudanRoom = HirobaRoom(
  id: 'soudan',
  emoji: '💬',
  name: 'お悩み相談テント',
  desc: '飼い方のこと、先輩の飼い主さんに聞いてみよう',
  colors: [Color(0xFF7BC6FF), Color(0xFF4B8FE2)],
  starters: ['はじめて飼うので', 'こんなとき、どうしていますか？'],
);

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

class AnimalParkPage extends StatefulWidget {
  const AnimalParkPage({super.key, this.preview = false});
  final bool preview;

  @override
  State<AnimalParkPage> createState() => _AnimalParkPageState();
}

class _AnimalParkPageState extends State<AnimalParkPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Duration _now = Duration.zero;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
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
  bool _autoTried = false;
  String? _goal;
  String? _follow;
  double _pawDist = 0;
  Timer? _posTimer;
  DateTime _lastFollowWrite = DateTime.fromMillisecondsSinceEpoch(0);

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
        _Visitor('a', {'petName': 'こむぎ', 'ribbon': 'ok', 'emoji': '🐶', 'animal': '柴犬', 'x': .38, 'y': .45}),
        _Visitor('b', {'petName': 'もち', 'ribbon': 'slow', 'emoji': '🐰', 'animal': 'うさぎ', 'x': .62, 'y': .4}),
        _Visitor('c', {'petName': 'ぎん', 'ribbon': 'look', 'emoji': '🐱', 'animal': 'ねこ', 'x': .66, 'y': .66}),
        _Visitor('d', {'petName': 'ぴーちゃん', 'ribbon': 'ok', 'emoji': '🐦', 'animal': 'インコ', 'x': .34, 'y': .72}),
      ];
      for (final d in _docs) {
        _m[d.id] = _Mover((d.data()['x'] as double), (d.data()['y'] as double));
      }
      _bubble('a', 'いい天気だね');
      return;
    }
    BlockedUsers.instance.ensureListening();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .where('park.day', isEqualTo: _day)
        .limit(60)
        .snapshots()
        .listen(_onVisitors, onError: (e) => debugPrint('公園のエラー: $e'));
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
    super.dispose();
  }

  // ---------- データ ----------

  double _seed(String id, int salt) {
    final h = id.codeUnits.fold<int>(salt * 7919, (a, b) => (a * 31 + b) & 0x7fffffff);
    return (h % 1000) / 1000;
  }

  void _onVisitors(QuerySnapshot<Map<String, dynamic>> q) {
    final docs = q.docs
        .map((d) => _visitorOf(d, _day))
        .whereType<_Visitor>()
        .where((v) => !BlockedUsers.instance.isBlocked(v.id))
        .toList();
    final ids = docs.map((d) => d.id).toSet();
    _m.removeWhere((k, _) => !ids.contains(k));
    for (final d in docs) {
      final data = d.data();
      final x = ((data['x'] as num?)?.toDouble() ?? (.3 + _seed(d.id, 1) * .4)).clamp(0.0, 1.0);
      final y = ((data['y'] as num?)?.toDouble() ?? (.4 + _seed(d.id, 2) * .4)).clamp(0.0, 1.0);
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
    if (_meDoc == null) _autoEnter();
    if (mounted) setState(() {});
  }

  // アプリを入れている人は、タブを開いたらそのまま公園に入る（名札はうちの子を押すと直せる）
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
          'x': double.parse((.35 + _rnd.nextDouble() * .3).toStringAsFixed(3)),
          'y': double.parse((.55 + _rnd.nextDouble() * .2).toStringAsFixed(3)),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('公園に入りました🌳 うちの子を押すと、名札を直せます'),
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      debugPrint('公園に入れませんでした: $e');
    }
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

  // ---------- 動き ----------

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
          o.tx = (f.x + 44 / W).clamp(0.05, 0.95);
          o.ty = (f.y + 10 / H).clamp(0.2, 0.88);
        }
      }
      final dx = (o.tx - o.x) * W, dy = (o.ty - o.y) * H;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > 2) {
        final st = _still ? d : math.min(d, (isMe ? 150.0 : 50.0) * dt);
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
        if (isMe && _goal != null) {
          final g = _goal!;
          _goal = null;
          WidgetsBinding.instance.addPostFrameCallback((_) => _openSpot(g));
        }
        if (!isMe && !_still) {
          o.wait -= dt;
          if (o.wait <= 0) {
            o.tx = (o.hx + (_rnd.nextDouble() - .5) * 60 / W).clamp(0.05, 0.95);
            o.ty = (o.hy + (_rnd.nextDouble() - .5) * 40 / H).clamp(0.2, 0.88);
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

  void _walkTo(double fx, double fy, {String? goal, bool keepFollow = false}) {
    final uid = _uid;
    final me = uid == null ? null : _m[uid];
    if (me == null) return;
    if (!keepFollow) _follow = null;
    me.tx = fx.clamp(0.05, 0.95);
    me.ty = fy.clamp(0.2, 0.88);
    _goal = goal;
    _writePos(me.tx, me.ty);
  }

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

  // 場所に着いたら、その機能の画面に入る
  void _openSpot(String key) {
    if (!mounted) return;
    final now = DateTime.now();
    void open(Widget page) {
      if (widget.preview) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('（お試し表示）ここで「$key」の画面に入ります')));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    switch (key) {
      case 'areas':
        open(const AnimalAreasPage());
      case 'tent':
        open(HirobaRoomPage(room: _soudanRoom));
      case 'org':
        open(const AnimalMapPage(initialCategory: 'org'));
      case 'info':
        open(const MeetBoardPage());
      default:
        final e = _eventAt(key, now);
        if (e == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(key == 'photo'
                ? 'いまは写真大会はありません'
                : key == 'bench'
                    ? 'いまは話しあい会はありません'
                    : '屋台はいまお休みです'),
          ));
        } else {
          open(HirobaRoomPage(room: e.room));
        }
    }
  }

  // ---------- 画面 ----------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dt = _timeOf(now);
    final top = MediaQuery.of(context).padding.top;
    final tint = switch (dt) {
      _DayTime.morning => const Color(0x14FFDCAA),
      _DayTime.day => const Color(0x00000000),
      _DayTime.evening => const Color(0x33FF783C),
      _DayTime.night => const Color(0x590F1946),
    };
    final lit = dt == _DayTime.evening || dt == _DayTime.night;
    return Scaffold(
      backgroundColor: const Color(0xFF6FA35A),
      body: LayoutBuilder(builder: (context, c) {
        _size = c.biggest;
        final W = _size.width, H = _size.height;
        final uid = _uid;
        final order = _m.keys.toList()..sort((a, b) => _m[a]!.y.compareTo(_m[b]!.y));
        final byId = {for (final d in _docs) d.id: d};
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _walkTo(d.localPosition.dx / W, d.localPosition.dy / H),
              child: Stack(children: [
                Positioned.fill(
                  child: Image.network(_bgPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(color: const Color(0xFF6FA35A))),
                ),
                Positioned.fill(child: IgnorePointer(child: ColoredBox(color: tint))),
                if (lit)
                  for (final l in const [Offset(.32, .38), Offset(.7, .62)])
                    Positioned(
                      left: l.dx * W - 90,
                      top: l.dy * H - 90,
                      child: IgnorePointer(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [Color(0x66FFE296), Color(0x00FFE296)], stops: [0, .7]),
                          ),
                        ),
                      ),
                    ),
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
                for (final s in _spots) _spot(s, now),
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
                  if (byId[id] != null) _petIcon(byId[id]!, _m[id]!, id == uid),
              ]),
            ),
          ),
          Positioned(left: 12, right: 12, top: top + 8, child: _header(now)),
          Positioned(left: 12, right: 12, bottom: 14, child: _bottomBar()),
        ]);
      }),
    );
  }

  Widget _spot(_Spot s, DateTime now) {
    final e = (s.key == 'photo' || s.key == 'yatai' || s.key == 'bench') ? _eventAt(s.key, now) : null;
    final live = e != null && e.isLive(now);
    final soon = e != null && !live && e.start.difference(now).inHours < 24;
    return Positioned(
      left: s.x * _size.width - 50,
      top: s.y * _size.height - 52,
      width: 100,
      child: GestureDetector(
        onTap: () => _walkTo(s.x + (s.x < .4 ? .16 : s.x > .6 ? -.16 : 0), s.y + (s.x >= .4 && s.x <= .6 ? .1 : .02), goal: s.key),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 18,
            child: e != null && (live || soon)
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: live ? const Color(0xFFE84A5F) : const Color(0xFF4B8FE2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(live ? '開催中' : '${e.start.hour}:${e.start.minute.toString().padLeft(2, '0')}〜',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  )
                : null,
          ),
          Stack(alignment: Alignment.bottomCenter, children: [
            Container(
              width: 58,
              height: 14,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(s.emoji, style: const TextStyle(fontSize: 44)),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xF0FFFAF4),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(s.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
          ),
        ]),
      ),
    );
  }

  Widget _petIcon(_Visitor doc, _Mover o, bool isMe) {
    final d = doc.data();
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    final size = isMe ? 54.0 : 48.0;
    final hop = o.walking ? math.sin(_now.inMilliseconds / 90) * 3 - 3 : 0.0;
    final at = _bubbleAt[doc.id];
    final bubble = at != null && DateTime.now().difference(at).inMilliseconds < 4000 ? _bubbleText[doc.id] : null;
    return Positioned(
      left: o.x * _size.width - 60,
      top: o.y * _size.height - size - 40,
      width: 120,
      child: GestureDetector(
        onTap: isMe ? () => _editTag(d) : () => _openTag(doc),
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
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .25), borderRadius: BorderRadius.circular(20)),
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

  Widget _header(DateTime now) {
    final n = _docs.length;
    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xF0FFFAF4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3))],
          ),
          child: Row(children: [
            const Text('どうぶつ公園', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${_sceneLabel(now)}・いま$n匹',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Pressable(
        onTap: _howTo,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xF0FFFAF4),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3))],
          ),
          child: const Icon(Icons.help_outline_rounded, color: _ink, size: 22),
        ),
      ),
    ]);
  }

  Widget _bottomBar() {
    Widget btn(String label, VoidCallback onTap) => Expanded(
          child: Pressable(
            onTap: onTap,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xF5FFFAF4),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _ink)),
            ),
          ),
        );
    return Row(children: [
      btn('💬 ひとこと', _sayMenu),
      const SizedBox(width: 10),
      btn('📖 手帳 ${_met.length}', _book),
    ]);
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
        Text('うちの子の頭の上に出ます。公園にいるみんなに見えます。', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in sayPhrases)
            ActionChip(
              label: Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                Navigator.pop(ctx);
                _say(s);
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

  void _howTo() {
    _sheet(const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('どうぶつ公園の使い方', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
      SizedBox(height: 12),
      Text('🐾 このタブを開くと、うちの子が公園に入ります。今日いっぱい公園にいます。', style: TextStyle(height: 1.6)),
      Text('👆 芝生を押すと、そこまで歩きます。', style: TextStyle(height: 1.6)),
      Text('🏠 絵の場所を押すと、そこまで歩いて中に入ります。', style: TextStyle(height: 1.6)),
      Text('   📸 写真大会　🏮 お祭り・チャレンジ　🪑 話しあい会', style: TextStyle(height: 1.6)),
      Text('   ⛺ 相談　🏠 保護団体　🗺️ 会うイベント　🌳 動物ごとの場所', style: TextStyle(height: 1.6)),
      Text('💬 ひとことは、頭の上に出て、みんなに見えます。', style: TextStyle(height: 1.6)),
      Text('👋 ほかの子を押すと、あいさつや「いっしょに歩く」ができます。', style: TextStyle(height: 1.6)),
      Text('🎀 うちの子を押すと名札を直せます。黄色いリボンは「ゆっくりね」、灰色は「見るだけ」です。', style: TextStyle(height: 1.6)),
      SizedBox(height: 10),
      Text(_bgCredit, style: TextStyle(fontSize: 11, color: Colors.grey)),
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
      builder: (_) => _ReceptionSheet(uid: uid, current: current),
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
      _goal = null;
      _met.putIfAbsent(d.id, () => {'name': d.data()['petName'], 'image': d.data()['petImage'], 'phrase': 'いっしょに歩いた'});
    });
    _say('おさんぽ中');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.data()['petName'] ?? ''}といっしょに歩いています'), duration: const Duration(seconds: 2)),
    );
  }
}

// ============================================================
// どうぶつエリア（公園の 🌳 から入る、別の画面）
// ============================================================

const _areaSpots = [
  Offset(.27, .24), Offset(.73, .26), Offset(.24, .43), Offset(.76, .45),
  Offset(.27, .62), Offset(.73, .64), Offset(.3, .8), Offset(.7, .82),
];

class AnimalAreasPage extends StatelessWidget {
  const AnimalAreasPage({super.key, this.preview = false});
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF6FA35A),
      body: LayoutBuilder(builder: (context, c) {
        final W = c.maxWidth, H = c.maxHeight;
        return Stack(children: [
          Positioned.fill(
            child: Image.network(_bgPhoto,
                fit: BoxFit.cover,
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stack) => Container(color: const Color(0xFF6FA35A))),
          ),
          Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: .08)))),
          for (var i = 0; i < animalGroups.length && i < _areaSpots.length; i++)
            Positioned(
              left: _areaSpots[i].dx * W - 60,
              top: _areaSpots[i].dy * H - 50,
              width: 120,
              child: GestureDetector(
                onTap: () {
                  if (preview) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalGroupPage(group: animalGroups[i])));
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xE6FFFAF4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Text(animalGroups[i].emoji, style: const TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xF0FFFAF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_areaNames[animalGroups[i].key] ?? animalGroups[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _ink)),
                  ),
                ]),
              ),
            ),
          Positioned(
            left: 8,
            right: 12,
            top: top + 8,
            child: Row(children: [
              Material(
                color: const Color(0xF0FFFAF4),
                shape: const CircleBorder(),
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
                    color: const Color(0xF0FFFAF4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('どうぶつエリア', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
                    Text('押すと、その動物の子たちの場所へ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
              ),
            ]),
          ),
        ]);
      }),
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

