// イベントで「書きこむ」以外にできること（11/25 社長「チャットしかできなさそう。できることを増やして。楽しいこと・新しいこと・気軽にできること」）
//  ・みんなでチャレンジ：「やった！」でみんなの合計が増える。目標まで進むバー
//  ・話しあい会：「参加する」（参加予定）。始まるまでの時間。話すことのカード
//  ・お祭り：今日のおみくじ。公園をまわるスタンプラリー
//  ・写真大会：写真の一覧と、いまの上位（表彰台）
//  ・どのイベントも：記念写真のフレーム、参加バッジ
// データは自分の users/{uid}.evt に書く（いまのルールのままで書ける）
//   evt.joined.{key}・evt.badges.{key}・evt.done.{key}・evt.rsvp.{key}・evt.omikuji・evt.rally.{key}
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/motion.dart';
import 'hiroba_data.dart';
import 'hiroba_room_page.dart';

const _ink = Color(0xFF3D2B1F);

// ============================================================
// データ
// ============================================================

String evtKey(HirobaRoom r) => (r.span ?? r.id).replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

OnlineEvent? eventOfRoom(HirobaRoom r, DateTime now) {
  for (final e in [...liveOnlineEvents(now), ...upcomingOnlineEvents(now)]) {
    if (e.roomId == r.id && e.span == r.span) return e;
  }
  return null;
}

DocumentReference<Map<String, dynamic>>? _myDoc() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid);
}

// 自分の evt（イベントの記録）を見続ける
Stream<Map<String, dynamic>> myEvtStream() {
  final d = _myDoc();
  if (d == null) return Stream.value(const {});
  return d.snapshots().map((s) {
    final e = s.data()?['evt'];
    return e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
  });
}

Map<String, dynamic> evtMap(Map<String, dynamic> evt, String name) {
  final m = evt[name];
  return m is Map ? Map<String, dynamic>.from(m) : <String, dynamic>{};
}

// 参加したことと、参加バッジを残す（すでにあれば何もしない）
final Set<String> _joinedThisSession = {};

Future<void> evtJoin(HirobaRoom r) async {
  final d = _myDoc();
  final key = evtKey(r);
  if (d == null || _joinedThisSession.contains(key)) return;
  _joinedThisSession.add(key);
  try {
    final s = await d.get();
    final evt = s.data()?['evt'];
    final joined = evt is Map && evt['joined'] is Map ? evt['joined'] as Map : const {};
    if (joined.containsKey(key)) return;
    final info = {
      'room': r.id,
      'span': r.span ?? '',
      'name': r.name,
      'emoji': r.emoji,
      'at': FieldValue.serverTimestamp(),
    };
    await d.update({
      FieldPath(['evt', 'joined', key]): info,
      FieldPath(['evt', 'badges', key]): {'name': r.name, 'emoji': r.emoji, 'at': FieldValue.serverTimestamp()},
    });
  } catch (e) {
    _joinedThisSession.remove(key);
    debugPrint('参加の記録のエラー: $e');
  }
}

Future<void> evtSet(List<String> path, Object? value) async {
  final d = _myDoc();
  if (d == null) return;
  try {
    await d.update({FieldPath(['evt', ...path]): value});
  } catch (e) {
    debugPrint('イベントの記録のエラー: $e');
  }
}

Future<void> evtAddRally(String fesKey, String spot) async {
  final d = _myDoc();
  if (d == null) return;
  try {
    await d.update({FieldPath(['evt', 'rally', fesKey]): FieldValue.arrayUnion([spot])});
  } catch (e) {
    debugPrint('スタンプラリーのエラー: $e');
  }
}

// evt.{name}.{key} が true の人（多くて limit 人）
Future<List<String>> evtUsers(String name, String key, {int limit = 200}) async {
  try {
    final q = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath(['evt', name, key]), isEqualTo: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.id).toList();
  } catch (e) {
    debugPrint('数えられませんでした: $e');
    return const [];
  }
}

// ============================================================
// 見た目の部品
// ============================================================

class _Board extends StatelessWidget {
  const _Board({required this.title, required this.emoji, required this.color, required this.child});
  final String title, emoji;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .35), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink))),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

Widget _bigButton(String label, Color color, VoidCallback? onTap, {IconData? icon, bool outlined = false}) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
  final text = Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900));
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: outlined
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color, width: 2), shape: shape),
            onPressed: onTap,
            icon: Icon(icon ?? Icons.check_rounded),
            label: text,
          )
        : FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: color, shape: shape),
            onPressed: onTap,
            icon: Icon(icon ?? Icons.check_rounded),
            label: text,
          ),
  );
}

// ---------- みんなでチャレンジ ----------

class ChallengeBoard extends StatelessWidget {
  const ChallengeBoard({
    super.key,
    required this.count,
    required this.goal,
    required this.done,
    required this.onDone,
    required this.color,
    this.faces,
    this.howTo,
  });
  final int count, goal;
  final bool done;
  final VoidCallback? onDone;
  final Color color;
  final Widget? faces;
  final String? howTo;

  @override
  Widget build(BuildContext context) {
    final reached = count >= goal;
    final p = goal <= 0 ? 0.0 : (count / goal).clamp(0.0, 1.0);
    return _Board(
      title: 'みんなで目標まで',
      emoji: '🏁',
      color: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: count.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()}',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color, height: 1)),
          ),
          Text(' / $goal匹', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
          const Spacer(),
          Text(reached ? '目標たっせい！' : 'あと${goal - count}匹',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: reached ? const Color(0xFFE84A5F) : _ink)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 16, color: color.withValues(alpha: .15)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: .7), color]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // 目印（25%ごと）
            Positioned.fill(
              child: Row(children: [
                for (var i = 1; i < 4; i++) ...[
                  const Spacer(),
                  Container(width: 2, color: Colors.white.withValues(alpha: .8)),
                ],
                const Spacer(),
              ]),
            ),
          ]),
        ),
        if (faces != null) ...[const SizedBox(height: 10), faces!],
        const SizedBox(height: 12),
        if (done)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(24)),
            child: Text('🎉 やりました！ 参加ありがとう', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          )
        else
          _bigButton('やった！', color, onDone, icon: Icons.check_circle_rounded),
        if (howTo != null) ...[
          const SizedBox(height: 6),
          Text(howTo!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ]),
    );
  }
}

// ---------- 話しあい会 ----------

const Map<String, List<String>> _talkCards = {
  '': [
    'うちの子のいちばん好きな時間は？',
    'はじめて会った日のこと',
    'これは買ってよかった、という物',
    'ちょっと困っていること',
    '名前の由来',
  ],
};

class TalkBoard extends StatefulWidget {
  const TalkBoard({
    super.key,
    required this.start,
    required this.end,
    required this.theme,
    required this.rsvpCount,
    required this.rsvped,
    required this.onRsvp,
    required this.onTopic,
    required this.color,
    this.faces,
  });
  final DateTime start, end;
  final String theme;
  final int rsvpCount;
  final bool rsvped;
  final VoidCallback? onRsvp;
  final void Function(String) onTopic;
  final Color color;
  final Widget? faces;

  @override
  State<TalkBoard> createState() => _TalkBoardState();
}

class _TalkBoardState extends State<TalkBoard> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _left(DateTime now) {
    if (!now.isBefore(widget.end)) return '終わりました';
    if (!now.isBefore(widget.start)) {
      final m = widget.end.difference(now).inMinutes + 1;
      return 'いま話しあい中（あと$m分）';
    }
    final d = widget.start.difference(now);
    if (d.inDays >= 1) return 'はじまるまで あと${d.inDays}日';
    if (d.inHours >= 1) return 'はじまるまで あと${d.inHours}時間${d.inMinutes % 60}分';
    return 'はじまるまで あと${d.inMinutes + 1}分';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final c = widget.color;
    final cards = [widget.theme, ...(_talkCards[''] ?? const [])];
    return _Board(
      title: '話しあい会',
      emoji: '🗓️',
      color: c,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_left(now), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
        const SizedBox(height: 2),
        Text('${whenText(widget.start)}〜${widget.end.hour}:${widget.end.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 10),
        if (widget.faces != null) widget.faces!,
        Text(widget.rsvpCount == 0 ? '参加予定はまだいません' : '${widget.rsvpCount}人が参加予定',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 10),
        _bigButton(widget.rsvped ? '参加予定にしています（やめる）' : '参加する（予定に入れる）', c, widget.onRsvp,
            icon: widget.rsvped ? Icons.event_available_rounded : Icons.event_rounded, outlined: widget.rsvped),
        const SizedBox(height: 4),
        Text('参加予定にすると、始まる前にホームでお知らせします',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 14),
        const Text('話すことのカード（押すと書く欄に入ります）',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Pressable(
              onTap: () => widget.onTopic(cards[i]),
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.withValues(alpha: i == 0 ? .9 : .14), c.withValues(alpha: i == 0 ? .7 : .06)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i == 0 ? '今日のテーマ' : 'カード $i',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: i == 0 ? Colors.white70 : c)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(cards[i],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: i == 0 ? Colors.white : _ink, height: 1.35)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- お祭り：おみくじ ----------

const List<(String, String, String)> _fortunes = [
  ('大吉', 'なでなで運が最高。今日はいつもより少し長く遊んであげよう', 'お気に入りのおもちゃ'),
  ('大吉', '仲よし運が最高。名前をたくさん呼んであげよう', 'やさしい声'),
  ('中吉', 'おさんぽ運◎。いつもとちがう道を少しだけ歩いてみよう', '新しい道'),
  ('中吉', '写真運◎。今日のいちばんの1枚を写真大会に出してみよう', '横顔'),
  ('小吉', 'おひるね運あり。いっしょにのんびりする時間をとろう', '日なた'),
  ('吉', 'おそうじ運。ベッドやケージをきれいにすると、ごきげんに', '洗いたてのタオル'),
  ('吉', 'おしゃべり運。公園でだれかにあいさつしてみよう', '🐾スタンプ'),
  ('末吉', 'ゆっくり運。今日はいつもどおりが、いちばんの幸せ', 'いつものごはん'),
];

(String, String, String) fortuneFor(String uid, String day) {
  final h = '$uid$day'.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  return _fortunes[h % _fortunes.length];
}

class OmikujiCard extends StatefulWidget {
  const OmikujiCard({super.key, required this.drawnToday, required this.onDrawn, required this.onShare, required this.color});
  final bool drawnToday;
  final VoidCallback onDrawn;
  final void Function(String text) onShare;
  final Color color;

  @override
  State<OmikujiCard> createState() => _OmikujiCardState();
}

class _OmikujiCardState extends State<OmikujiCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.drawnToday;
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    if (_open) return;
    if (!reduceMotion(context)) await _shake.forward(from: 0);
    if (!mounted) return;
    setState(() => _open = true);
    widget.onDrawn();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final f = fortuneFor(uid, dayKey(DateTime.now()));
    final c = widget.color;
    return _Board(
      title: '今日のおみくじ（うちの子の運勢）',
      emoji: '🎋',
      color: c,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
        child: !_open
            ? Column(key: const ValueKey('box'), children: [
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) =>
                      Transform.rotate(angle: math.sin(_shake.value * math.pi * 8) * .18 * (1 - _shake.value), child: child),
                  child: Pressable(
                    onTap: _draw,
                    child: Container(
                      width: 96,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE8473D), Color(0xFFB8322B)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('おみくじ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('🐾', style: TextStyle(fontSize: 28)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('箱を押すと、1日1回ひけます', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ])
            : Column(key: const ValueKey('paper'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8473D), width: 2),
                  ),
                  child: Column(children: [
                    Text(f.$1, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFE8473D))),
                    const SizedBox(height: 6),
                    Text(f.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: _ink, height: 1.5)),
                    const SizedBox(height: 6),
                    Text('ラッキーアイテム：${f.$3}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ]),
                ),
                const SizedBox(height: 10),
                _bigButton('みんなに見せる', c, () => widget.onShare('今日のおみくじは「${f.$1}」でした🎋'),
                    icon: Icons.campaign_rounded, outlined: true),
              ]),
        ),
      ),
    );
  }
}

// ---------- お祭り：スタンプラリー ----------

const parkRallySpots = [
  ('areas', '🌳', 'どうぶつエリア'),
  ('photo', '📸', '写真スタジオ'),
  ('yatai', '🏮', '屋台'),
  ('tent', '⛺', '相談テント'),
  ('bench', '🪑', 'ベンチ広場'),
  ('org', '🏠', '保護団体の家'),
  ('info', '🗺️', '案内所'),
];

class RallyCard extends StatelessWidget {
  const RallyCard({super.key, required this.have, required this.color});
  final Set<String> have;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final n = parkRallySpots.where((s) => have.contains(s.$1)).length;
    final all = n == parkRallySpots.length;
    return _Board(
      title: '公園スタンプラリー（$n / ${parkRallySpots.length}）',
      emoji: '🗺️',
      color: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final (i, s) in parkRallySpots.indexed)
            Column(children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: have.contains(s.$1) ? color.withValues(alpha: .15) : const Color(0xFFF3EFEA),
                  border: Border.all(
                      color: have.contains(s.$1) ? color : const Color(0xFFDDD5CB), width: 2, style: BorderStyle.solid),
                ),
                child: have.contains(s.$1)
                    ? Transform.rotate(angle: (i.isEven ? -1 : 1) * .2, child: Text(s.$2, style: const TextStyle(fontSize: 26)))
                    : Text('${i + 1}', style: const TextStyle(fontSize: 16, color: Color(0xFFBDB3A7), fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 60,
                child: Text(s.$3,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: _ink)),
              ),
            ]),
        ]),
        const SizedBox(height: 10),
        Text(all ? '🎉 ぜんぶ集めました！ 手帳にバッジが入ります' : 'お祭りのあいだに公園の場所に入ると、スタンプがたまります',
            style: TextStyle(fontSize: 12, color: all ? color : Colors.grey[700], fontWeight: all ? FontWeight.w900 : null)),
      ]),
    );
  }
}

// ---------- お祭り・チャレンジ共通：みんなで集める ----------

class GoalBar extends StatelessWidget {
  const GoalBar({super.key, required this.count, required this.goal, required this.color, required this.label});
  final int count, goal;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = goal <= 0 ? 0.0 : (count / goal).clamp(0.0, 1.0);
    return _Board(
      title: label,
      emoji: '🎯',
      color: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$count / $goal', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 14,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- 写真大会：写真の一覧と表彰台 ----------

class PhotoEntry {
  final String id, url, uid, name;
  final int paws;
  final bool voted;
  const PhotoEntry({
    required this.id,
    required this.url,
    required this.uid,
    required this.name,
    required this.paws,
    required this.voted,
  });
}

class PhotoPodium extends StatelessWidget {
  const PhotoPodium({super.key, required this.top, required this.color, required this.onOpen});
  final List<PhotoEntry> top;
  final Color color;
  final void Function(PhotoEntry) onOpen;

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) return const SizedBox.shrink();
    // 2位・1位・3位の順に並べる
    final order = <int>[if (top.length > 1) 1, 0, if (top.length > 2) 2];
    const medals = ['🥇', '🥈', '🥉'];
    const heights = [92.0, 66.0, 50.0];
    return _Board(
      title: 'いまの上位',
      emoji: '🏆',
      color: color,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final i in order)
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + i * 200),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.translate(offset: Offset(0, 30 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
              child: GestureDetector(
                onTap: () => onOpen(top[i]),
                child: Column(children: [
                  Text(medals[i], style: const TextStyle(fontSize: 26)),
                  Container(
                    width: i == 0 ? 78 : 62,
                    height: i == 0 ? 78 : 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: i == 0 ? const Color(0xFFFFC83D) : Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3))],
                      image: DecorationImage(image: NetworkImage(top[i].url), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(top[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 4),
                  Container(
                    height: heights[i],
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: .85), color.withValues(alpha: .55)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Text('🐾 ${top[i].paws}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.photos, required this.color, required this.onOpen, required this.onVote});
  final List<PhotoEntry> photos;
  final Color color;
  final void Function(PhotoEntry) onOpen;
  final void Function(PhotoEntry) onVote;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('まだ写真がありません。いちばんに出してみよう', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .8,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final p = photos[i];
        return GestureDetector(
          onTap: () => onOpen(p),
          onDoubleTap: () => onVote(p),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(fit: StackFit.expand, children: [
              Image.network(p.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDE6DE))),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x00000000), Color(0x99000000)],
                    stops: [0, .6, 1],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(children: [
                  Expanded(
                    child: Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  Pressable(
                    onTap: () => onVote(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.voted ? color : Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('🐾 ${p.paws}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: p.voted ? Colors.white : _ink)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ---------- 参加バッジ ----------

class BadgeShelf extends StatelessWidget {
  const BadgeShelf({super.key, required this.badges});
  final Map<String, dynamic> badges;

  @override
  Widget build(BuildContext context) {
    final list = badges.entries.where((e) => e.value is Map).toList()
      ..sort((a, b) {
        final ta = (a.value as Map)['at'], tb = (b.value as Map)['at'];
        final ma = ta is Timestamp ? ta.millisecondsSinceEpoch : 0, mb = tb is Timestamp ? tb.millisecondsSinceEpoch : 0;
        return mb.compareTo(ma);
      });
    if (list.isEmpty) {
      return Text('まだバッジはありません。イベントに参加すると、ここに集まります', style: TextStyle(fontSize: 13, color: Colors.grey[700]));
    }
    return Wrap(spacing: 10, runSpacing: 12, children: [
      for (final e in list)
        SizedBox(
          width: 70,
          child: Column(children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB547)]),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Text('${(e.value as Map)['emoji'] ?? '🏅'}', style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 4),
            Text('${(e.value as Map)['name'] ?? ''}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _ink)),
          ]),
        ),
    ]);
  }
}

// ============================================================
// 記念写真のフレーム
// ============================================================

class KeepsakeFramePage extends StatefulWidget {
  const KeepsakeFramePage({super.key, required this.room, this.petImageUrl, this.petName});
  final HirobaRoom room;
  final String? petImageUrl;
  final String? petName;

  @override
  State<KeepsakeFramePage> createState() => _KeepsakeFramePageState();
}

class _KeepsakeFramePageState extends State<KeepsakeFramePage> {
  final _key = GlobalKey();
  ImageProvider? _img;
  int _style = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = widget.petImageUrl;
    if (u != null && u.startsWith('https://')) _img = NetworkImage(u);
  }

  Future<void> _pick() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (mounted) setState(() => _img = MemoryImage(bytes));
    } catch (e) {
      debugPrint('写真をえらべませんでした: $e');
    }
  }

  Future<void> _save() async {
    if (_img == null || _busy) return;
    setState(() => _busy = true);
    try {
      final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return;
      final image = await b.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final file = XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'animatch_${evtKey(widget.room)}.png');
      await SharePlus.instance.share(ShareParams(files: [file], text: '${widget.room.emoji} ${widget.room.name}（AniMatch）'));
    } catch (e) {
      debugPrint('記念写真のエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存できませんでした。写真を自分でえらんで、もう一度ためしてください')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final c1 = r.colors.first, c2 = r.colors.last;
    final now = DateTime.now();
    final styles = [
      [c1, c2],
      [const Color(0xFFFFF4E0), const Color(0xFFFFD6A5)],
      [const Color(0xFF2B2B4A), const Color(0xFF5A4A8A)],
    ];
    final dark = _style != 1;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(title: const Text('記念写真をつくる'), backgroundColor: const Color(0xFFFFF8F0)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        RepaintBoundary(
          key: _key,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: styles[_style]),
              ),
              child: Column(children: [
                Row(children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dark ? Colors.white : _ink)),
                  ),
                  Text('${now.year}.${now.month}.${now.day}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: dark ? Colors.white70 : _ink)),
                ]),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                      image: _img == null ? null : DecorationImage(image: _img!, fit: BoxFit.cover),
                    ),
                    child: _img == null
                        ? const Center(child: Text('写真をえらんでください', style: TextStyle(color: Colors.grey)))
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text(
                        widget.petName == null || widget.petName!.isEmpty ? (r.prompt ?? r.desc) : '${widget.petName}・${r.prompt ?? r.desc}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: dark ? Colors.white : _ink)),
                  ),
                  Text('🐾 AniMatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: dark ? Colors.white : _ink)),
                ]),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < styles.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _style = i),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: styles[i]),
                    border: Border.all(color: _style == i ? _ink : Colors.white, width: 3),
                  ),
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_library_outlined), label: const Text('写真をえらぶ')),
        ]),
        const SizedBox(height: 10),
        _bigButton(_busy ? 'つくっています…' : '保存する・SNSに送る', c2, _img == null || _busy ? null : _save, icon: Icons.ios_share_rounded),
        const SizedBox(height: 8),
        Text('写真はスマホの中でつくります。アプリには送られません', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]),
    );
  }
}

// テスト用のページだけで使う、お試し表示（?preview=extras）
class EventExtrasPreview extends StatelessWidget {
  const EventExtrasPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF4D8076);
    const fes = Color(0xFFE8473D);
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(title: const Text('イベントでできること（お試し）')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        ChallengeBoard(count: 32, goal: 100, done: false, onDone: () {}, color: c, howTo: 'やったら「やった！」を押すだけ'),
        TalkBoard(
          start: now.add(const Duration(hours: 2, minutes: 15)),
          end: now.add(const Duration(hours: 3)),
          theme: 'うちの子の好きな遊び',
          rsvpCount: 5,
          rsvped: false,
          onRsvp: () {},
          onTopic: (_) {},
          color: const Color(0xFF3B3B98),
        ),
        const GoalBar(count: 64, goal: 100, color: fes, label: 'みんなで100こ集めよう'),
        OmikujiCard(drawnToday: false, onDrawn: () {}, onShare: (_) {}, color: fes),
        const RallyCard(have: {'photo', 'yatai', 'bench'}, color: fes),
        const SizedBox(height: 12),
        const BadgeShelf(badges: {
          'a': {'emoji': '📸', 'name': '週末の写真大会'},
          'b': {'emoji': '🤝', 'name': 'みんなでチャレンジ'},
          'c': {'emoji': '🎃', 'name': 'ハロウィン'},
        }),
      ]),
    );
  }
}

// ============================================================
// ホーム：開催中のイベントを大きく。参加予定の話しあい会が近いときは、お知らせ
// ============================================================

class LiveEventBanner extends StatelessWidget {
  const LiveEventBanner({super.key});

  void _open(BuildContext context, OnlineEvent e) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: e.room)));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final live = liveOnlineEvents(now);
    final soon = upcomingOnlineEvents(now);
    return StreamBuilder<Map<String, dynamic>>(
      stream: myEvtStream(),
      builder: (context, snap) {
        final rsvp = evtMap(snap.data ?? const {}, 'rsvp');
        OnlineEvent? remind;
        for (final e in [...live, ...soon]) {
          if (e.kind == 'talk' && rsvp[evtKey(e.room)] == true && e.start.difference(now).inMinutes <= 60 && now.isBefore(e.end)) {
            remind = e;
            break;
          }
        }
        final main = live.isNotEmpty ? live.first : null;
        if (main == null && remind == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            if (remind != null)
              Pressable(
                onTap: () => _open(context, remind!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B3B98),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Text(remind.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          remind.isLive(now)
                              ? '参加予定の「${remind.title}」が始まっています'
                              : 'もうすぐ「${remind.title}」（${remind.start.hour}:${remind.start.minute.toString().padLeft(2, '0')}から）',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ]),
                ),
              ),
            if (main != null)
              Pressable(
                onTap: () => _open(context, main),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: main.colors),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: main.colors.last.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Row(children: [
                    Text(main.emoji, style: const TextStyle(fontSize: 42)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: const Text('いま開催中',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE84A5F))),
                        ),
                        const SizedBox(height: 4),
                        Text(main.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(main.theme,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.white)),
                        if (live.length > 1)
                          Text('ほかに${live.length - 1}つ開催中',
                              style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Text('参加する', style: TextStyle(fontWeight: FontWeight.w900, color: main.colors.last)),
                    ),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}
