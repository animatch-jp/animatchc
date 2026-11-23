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

_Visitor? _visitorOf(_Visitor doc, String day) {
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
// 公園のページ
// 本物の公園の写真の上を、うちの子の写真アイコンが歩く（お試し版 web/park-demo と同じ動き）
//  ・芝生を押す → うちの子がそこまで歩く。位置はみんなに見える
//  ・ひとこと → 頭の上のふきだし（決まったことばだけ）。みんなに見える
//  ・ほかの子を押す → 名札・あいさつ・いっしょに歩く（あいさつOKの子だけ）
//  ・看板の場所に着く → そこでできること（イベント・動物の部屋・会）が下に出る
// ほかの子は、今日公園に来た本物の子だけ。自分の位置のまわりを少しだけうろうろする
// ============================================================

const _bgPhoto =
    'https://images.unsplash.com/photo-1759750909584-b96825e93de8?auto=format&fit=crop&w=1600&q=70';
const _bgCredit = '写真：Maxim Nikiforov / Unsplash';


class _Place {
  final String key;
  final String name;
  final double x, y; // 公園の中の位置（0〜1）
  const _Place(this.key, this.name, this.x, this.y);
}

const _places = [
  _Place('dog', 'ドッグラン', .22, .12),
  _Place('cat', 'ねこの日だまり', .78, .12),
  _Place('photo', '写真スポット', .5, .22),
  _Place('yatai', '屋台', .8, .31),
  _Place('tent', 'お悩み相談テント', .2, .34),
  _Place('bench', 'ベンチ', .78, .46),
  _Place('org', '保護団体のテント', .42, .52),
  _Place('rabbit', 'うさぎの芝', .18, .6),
  _Place('small', '小さな広場', .8, .62),
  _Place('ferret', 'トンネル広場', .58, .7),
  _Place('bird', '小鳥の木かげ', .2, .76),
  _Place('reptile', '温室テント', .84, .79),
  _Place('other', '水辺', .36, .86),
  _Place('info', '案内所', .64, .9),
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
  double x, y; // いま見えている位置（0〜1）
  double tx, ty; // 歩いていく先
  double hx, hy; // その子が本当にいる位置（Firestore）
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

class _Act {
  final String label;
  final VoidCallback onTap;
  const _Act(this.label, this.onTap);
}

class AnimalParkPage extends StatefulWidget {
  const AnimalParkPage({super.key});

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
  final Map<String, Map<String, dynamic>> _met = {}; // 今日あいさつした子
  final _rnd = math.Random();
  final String _day = parkDateKey();
  Size _screen = Size.zero;
  Size _world = Size.zero;
  Offset _cam = Offset.zero;
  bool _camReady = false;
  bool _dragging = false;
  bool _still = false;
  String? _goal;
  String? _arrived;
  String? _follow;
  double _pawDist = 0;
  Timer? _posTimer;
  DateTime _lastFollowWrite = DateTime.fromMillisecondsSinceEpoch(0);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  _Visitor? get _meDoc {
    for (final d in _docs) {
      if (d.id == _uid) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    BlockedUsers.instance.ensureListening();
    TabReselect.tabs[2].addListener(_centerOnMe);
    _ticker = createTicker(_tick)..start();
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
    TabReselect.tabs[2].removeListener(_centerOnMe);
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
      final x = ((data['x'] as num?)?.toDouble() ?? (.15 + _seed(d.id, 1) * .7)).clamp(0.0, 1.0);
      final y = ((data['y'] as num?)?.toDouble() ?? (.2 + _seed(d.id, 2) * .65)).clamp(0.0, 1.0);
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
          // うちの子へのあいさつ
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
    if (uid == null) return;
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
    if (_world.isEmpty) return;
    final W = _world.width, H = _world.height;
    final uid = _uid;
    for (final e in _m.entries) {
      final o = e.value;
      final isMe = e.key == uid;
      if (isMe && _follow != null) {
        final f = _m[_follow];
        if (f != null) {
          o.tx = (f.x + 44 / W).clamp(0.02, 0.98);
          o.ty = (f.y + 14 / H).clamp(0.05, 0.98);
        }
      }
      final dx = (o.tx - o.x) * W, dy = (o.ty - o.y) * H;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > 2) {
        final st = _still ? d : math.min(d, (isMe ? 95.0 : 55.0) * dt);
        o.x += dx / d * st / W;
        o.y += dy / d * st / H;
        o.walking = !_still;
        if (isMe && !_still) {
          _pawDist += st;
          if (_pawDist > 22) {
            _pawDist = 0;
            _paws.add(_Paw(o.x, o.y, now));
          }
        }
      } else {
        o.walking = false;
        if (isMe && _goal != null) {
          _arrived = _goal;
          _goal = null;
        }
        if (!isMe && !_still) {
          // 本当の位置のまわりで、少しだけうろうろ
          o.wait -= dt;
          if (o.wait <= 0) {
            o.tx = (o.hx + (_rnd.nextDouble() - .5) * 70 / W).clamp(0.02, 0.98);
            o.ty = (o.hy + (_rnd.nextDouble() - .5) * 50 / H).clamp(0.05, 0.98);
            o.wait = 3 + _rnd.nextDouble() * 5;
          }
        }
      }
    }
    _paws.removeWhere((p) => now - p.t > const Duration(seconds: 3));
    final me = uid == null ? null : _m[uid];
    if (me != null && me.walking && !_dragging) {
      final target = Offset(_screen.width / 2 - me.x * W, _screen.height * .5 - me.y * H);
      _cam = _clampCam(Offset.lerp(_cam, target, .06)!);
    }
    // いっしょに歩いているときは、ときどき位置をみんなに知らせる
    if (_follow != null && me != null && me.walking &&
        DateTime.now().difference(_lastFollowWrite) > const Duration(milliseconds: 2500)) {
      _lastFollowWrite = DateTime.now();
      _writePos(me.tx, me.ty);
    }
    if (mounted) setState(() {});
  }

  Offset _clampCam(Offset c) => Offset(
        c.dx.clamp(math.min(0.0, _screen.width - _world.width), 0.0),
        c.dy.clamp(math.min(0.0, _screen.height - _world.height), 0.0),
      );

  void _centerOnMe() {
    final me = _uid == null ? null : _m[_uid];
    if (me == null || _world.isEmpty) return;
    setState(() => _cam = _clampCam(
        Offset(_screen.width / 2 - me.x * _world.width, _screen.height * .5 - me.y * _world.height)));
  }

  void _walkTo(double fx, double fy, {String? goal, bool keepFollow = false}) {
    final uid = _uid;
    final me = uid == null ? null : _m[uid];
    if (me == null) {
      _reception(null);
      return;
    }
    if (!keepFollow) _follow = null;
    me.tx = fx.clamp(0.02, 0.98);
    me.ty = fy.clamp(0.05, 0.98);
    _goal = goal;
    _arrived = null;
    _writePos(me.tx, me.ty);
  }

  void _goTo(String key) {
    final p = _places.firstWhere((e) => e.key == key);
    _walkTo(p.x + (_rnd.nextDouble() - .5) * .04, p.y + .05, goal: key);
  }

  String _placeOfEvent(OnlineEvent e) => switch (e.kind) {
        'photo' => 'photo',
        'talk' => 'bench',
        _ => 'yatai',
      };

  OnlineEvent? _eventAt(String place, DateTime now) {
    for (final e in [...liveOnlineEvents(now), ...upcomingOnlineEvents(now)]) {
      if (_placeOfEvent(e) == place) return e;
    }
    return null;
  }

  // ---------- 画面 ----------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dt = _timeOf(now);
    final top = MediaQuery.of(context).padding.top;
    final meDoc = _meDoc;
    return Scaffold(
      backgroundColor: const Color(0xFF3C5A3A),
      body: LayoutBuilder(builder: (context, c) {
        _screen = c.biggest;
        _world = Size(math.max(_screen.width * 1.7, 700), math.max(_screen.height * 2.0, 1400));
        if (!_camReady) {
          _camReady = true;
          _cam = _clampCam(Offset(_screen.width / 2 - _world.width / 2, _screen.height - _world.height));
        }
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _dragging = true,
              onPanUpdate: (d) => setState(() => _cam = _clampCam(_cam + d.delta)),
              onPanEnd: (_) => _dragging = false,
              onTapUp: (d) {
                final p = d.localPosition - _cam;
                _walkTo(p.dx / _world.width, p.dy / _world.height);
              },
              child: ClipRect(
                child: Stack(children: [
                  Positioned(
                    left: _cam.dx,
                    top: _cam.dy,
                    width: _world.width,
                    height: _world.height,
                    child: _worldLayer(now, dt),
                  ),
                ]),
              ),
            ),
          ),
          Positioned(left: 12, right: 12, top: top + 8, child: _header(now)),
          if (_arrived != null && meDoc != null)
            Positioned(left: 12, right: 12, bottom: 84, child: _arrivalCard(_arrived!, now)),
          Positioned(left: 12, right: 12, bottom: 14, child: _bottomBar(meDoc)),
        ]);
      }),
    );
  }

  Widget _worldLayer(DateTime now, _DayTime dt) {
    final W = _world.width, H = _world.height;
    final tint = switch (dt) {
      _DayTime.morning => const Color(0x1FFFDCAA),
      _DayTime.day => const Color(0x00000000),
      _DayTime.evening => const Color(0x47FF783C),
      _DayTime.night => const Color(0x8C0F1946),
    };
    final lit = dt == _DayTime.evening || dt == _DayTime.night;
    final uid = _uid;
    final order = _m.keys.toList()..sort((a, b) => _m[a]!.y.compareTo(_m[b]!.y));
    final byId = {for (final d in _docs) d.id: d};
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Image.network(
          _bgPhoto,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF6FA35A)),
        ),
      ),
      Positioned.fill(child: IgnorePointer(child: ColoredBox(color: tint))),
      if (lit)
        for (final l in const [Offset(.38, .3), Offset(.66, .4), Offset(.32, .66), Offset(.68, .64), Offset(.5, .82), Offset(.5, .14)])
          Positioned(
            left: l.dx * W - 110,
            top: l.dy * H - 110,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x8CFFE296), Color(0x00FFE296)], stops: [0, .65]),
                ),
              ),
            ),
          ),
      for (final p in _paws)
        Positioned(
          left: p.x * W - 5,
          top: p.y * H - 9,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - (_now - p.t).inMilliseconds / 3000).clamp(0.0, 1.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xC0FFFFFF), shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      for (final p in _places) _sign(p, now),
      if (_follow != null && uid != null && _m[uid] != null && _m[_follow] != null)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LeashPainter(
                Offset(_m[uid]!.x * W, _m[uid]!.y * H - 30),
                Offset(_m[_follow]!.x * W, _m[_follow]!.y * H - 30),
              ),
            ),
          ),
        ),
      for (final id in order)
        if (byId[id] != null) _petIcon(byId[id]!, _m[id]!, id == uid),
      Positioned(
        left: 10,
        bottom: 6,
        child: Text(_bgCredit, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .7))),
      ),
    ]);
  }

  Widget _sign(_Place p, DateTime now) {
    final e = _eventAt(p.key, now);
    final live = e != null && e.isLive(now);
    final name = p.key == 'yatai' && e != null ? '屋台・${e.title}' : p.name;
    return Positioned(
      left: p.x * _world.width - 80,
      top: p.y * _world.height - 44,
      width: 160,
      child: Center(
        child: GestureDetector(
          onTap: () => _goTo(p.key),
          child: Stack(clipBehavior: Clip.none, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA87A52), Color(0xFF7A5236)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF4E321F), offset: Offset(0, 2)),
                    BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFFF6E6))),
              ),
              Container(width: 5, height: 16, color: const Color(0xFF4E321F)),
            ]),
            if (live)
              Positioned(
                right: -12,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE84A5F), borderRadius: BorderRadius.circular(9)),
                  child: const Text('開催中',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _petIcon(_Visitor doc, _Mover o, bool isMe) {
    final d = doc.data();
    final ribbon = ribbonOf(d['ribbon'] as String?);
    final img = d['petImage'] as String?;
    final size = isMe ? 58.0 : 52.0;
    final hop = o.walking ? math.sin(_now.inMilliseconds / 90) * 3 - 3 : 0.0;
    final at = _bubbleAt[doc.id];
    final bubble = at != null && DateTime.now().difference(at).inMilliseconds < 4000 ? _bubbleText[doc.id] : null;
    return Positioned(
      left: o.x * _world.width - 60,
      top: o.y * _world.height - size - 46,
      width: 120,
      child: GestureDetector(
        onTap: isMe ? () => _reception(d) : () => _openTag(doc),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 36,
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
                    : Center(child: Text((d['emoji'] as String?) ?? '🐾', style: const TextStyle(fontSize: 26))),
              ),
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                      color: ribbon.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ]),
          ),
          Container(
            width: 40,
            height: 8,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28), borderRadius: BorderRadius.circular(20)),
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

  Widget _pill({required Widget child, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xF0FFFAF4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _header(DateTime now) {
    final others = _docs.where((d) => d.id != _uid).length;
    final events = [...liveOnlineEvents(now), ...upcomingOnlineEvents(now)].take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: _pill(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('どうぶつ公園', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
              Text(
                  others == 0
                      ? '${_sceneLabel(now)}・まだだれも来ていません'
                      : '${_sceneLabel(now)}・いま ${others + (_meDoc != null ? 1 : 0)}匹が来ています',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Pressable(
          onTap: _howTo,
          child: _pill(
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.help_outline_rounded, color: _ink, size: 22),
          ),
        ),
      ]),
      if (events.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final e = events[i];
              final live = e.isLive(now);
              return Pressable(
                onTap: () => _goTo(_placeOfEvent(e)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xF0FFFAF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: live ? const Color(0xFFE84A5F) : Colors.transparent, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Text('${e.emoji} ${live ? 'いま開催中' : whenText(e.start)}：${e.title}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  Widget _bottomBar(_Visitor? meDoc) {
    if (meDoc == null) {
      return Pressable(
        onTap: () => _reception(null),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: const Text('🎫 受付で名札をつけて、公園に入る',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      );
    }
    Widget btn(String label, VoidCallback onTap, {bool main = false}) => Expanded(
          child: Pressable(
            onTap: onTap,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: main ? _orange : const Color(0xF5FFFAF4),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: main ? Colors.white : _ink)),
            ),
          ),
        );
    return Row(children: [
      btn('💬 ひとこと', _sayMenu),
      const SizedBox(width: 8),
      btn('📍 行き先', _placesMenu, main: true),
      const SizedBox(width: 8),
      btn('📖 手帳 ${_met.length}', _book),
    ]);
  }

  List<_Visitor> _near(_Place p) => _docs.where((d) {
        final o = _m[d.id];
        if (o == null || d.id == _uid) return false;
        final dx = (o.x - p.x) * _world.width, dy = (o.y - p.y - .05) * _world.height;
        return dx * dx + dy * dy < 170 * 170;
      }).toList();

  Widget _arrivalCard(String key, DateTime now) {
    final p = _places.firstWhere((e) => e.key == key);
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    String title = p.name;
    String desc;
    final acts = <_Act>[];
    final e = _eventAt(key, now);
    AnimalGroup? g;
    for (final x in animalGroups) {
      if (x.key == key) g = x;
    }
    if (g != null) {
      final group = g;
      title = _areaNames[group.key] ?? p.name;
      desc = '${group.name}の子たちの場所です。${group.note}';
      acts.add(_Act('${group.name}の部屋で話す', () => open(HirobaRoomPage(room: group.room))));
      acts.add(_Act('${group.name}の会', () => open(AnimalGroupPage(group: group))));
    } else {
      switch (key) {
        case 'photo':
        case 'bench':
        case 'yatai':
          if (e == null) {
            desc = key == 'photo'
                ? '写真を撮るのにいい場所です。いまは写真大会はありません。'
                : key == 'bench'
                    ? 'ゆっくり話せるベンチです。いまは話しあい会はありません。'
                    : '屋台はいまお休み中です。';
          } else {
            desc = e.isLive(now) ? 'いま「${e.title}」をやっています。' : '${whenText(e.start)}から「${e.title}」があります。';
            acts.add(_Act('${e.title}に入る', () => open(HirobaRoomPage(room: e.room))));
          }
        case 'tent':
          desc = '飼い方で困ったことを、先輩の飼い主さんに聞けます。';
          acts.add(_Act('相談テントに入る', () => open(HirobaRoomPage(room: _soudanRoom))));
        case 'org':
          desc = '保護団体の人たちのテントです。新しい家族をさがしている子に会えます。';
          acts.add(_Act('保護団体を見る', () => open(const AnimalMapPage(initialCategory: 'org'))));
        default:
          desc = '近くで会うイベント（18歳以上）をさがしたり、ひらいたりできます。';
          acts.add(_Act('会うイベントを見る', () => open(const MeetBoardPage())));
      }
    }
    final here = _near(p);
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF4),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 20, offset: Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text('$titleに着きました',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
            ),
            IconButton(
              tooltip: '閉じる',
              onPressed: () => setState(() => _arrived = null),
              icon: const Icon(Icons.close_rounded, color: _ink),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(desc, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[800])),
          ),
          const SizedBox(height: 8),
          Text(here.isEmpty ? 'いまは、ほかにだれもいません' : 'ここにいる子 ${here.length}匹',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
          if (here.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final d in here)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _openTag(d),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF2F5F8),
                        backgroundImage: _cloudinary(d.data()['petImage'] as String?)
                            ? NetworkImage(d.data()['petImage'] as String)
                            : null,
                        child: _cloudinary(d.data()['petImage'] as String?)
                            ? null
                            : Text((d.data()['emoji'] as String?) ?? '🐾'),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
          if (acts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(children: [
                for (var i = 0; i < acts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: i == 0
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: _orange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
                              onPressed: acts[i].onTap,
                              child: Text(acts[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900)),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: _orange,
                                  side: const BorderSide(color: _orange, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
                              onPressed: acts[i].onTap,
                              child: Text(acts[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                    ),
                  ),
                ],
              ]),
            ),
          ],
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

  void _placesMenu() {
    final now = DateTime.now();
    _sheet(Builder(
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('📍 どこへ行く？', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 8),
        for (final p in _places)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('🪧', style: TextStyle(fontSize: 22)),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: () {
              final e = _eventAt(p.key, now);
              if (e == null) return null;
              return Text(e.isLive(now) ? 'いま開催中：${e.title}' : '${whenText(e.start)}：${e.title}');
            }(),
            onTap: () {
              Navigator.pop(ctx);
              _goTo(p.key);
            },
          ),
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
      Text('🎫 受付で名札をつけると、うちの子が公園に入ります。今日いっぱい公園にいます。', style: TextStyle(height: 1.6)),
      Text('🐾 芝生を押すと、そこまで歩きます。指でずらすと、公園を見回せます。', style: TextStyle(height: 1.6)),
      Text('💬 ひとことは、うちの子の頭の上に出て、みんなに見えます。', style: TextStyle(height: 1.6)),
      Text('👋 ほかの子を押すと、名札を見て、あいさつや「いっしょに歩く」ができます。', style: TextStyle(height: 1.6)),
      Text('🎀 黄色いリボンは「ゆっくりね」、灰色は「見るだけ」の印です。', style: TextStyle(height: 1.6)),
      Text('🪧 看板の場所に行くと、写真大会・話しあい会・動物ごとの部屋などに入れます。', style: TextStyle(height: 1.6)),
      Text('🔒 名札に出るのは、うちの子の名前と写真とリボンだけです。', style: TextStyle(height: 1.6)),
      SizedBox(height: 10),
      Text(_bgCredit, style: TextStyle(fontSize: 11, color: Colors.grey)),
    ]));
  }

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
      showHappyBurst(context, message: '公園に入りました', sub: '芝生を押すと、そこまで歩きます', emoji: '🌳');
      // 入口から少し中へ歩いて入る
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _walkTo(.5, .82);
      });
    }
  }

  void _openTag(_Visitor d) {
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
          _walkTo(o.x - 46 / _world.width, o.y + 10 / _world.height, keepFollow: true);
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
      _arrived = null;
      _goal = null;
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

