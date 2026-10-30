import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pet_brag_page.dart' show showPostDetail;

// 週間ランキング
// ・月曜0時〜日曜24時の1週間で集計（毎週月曜に新しい週が始まる）
// ・部門（かわいい／おもしろい／癒される／総合）と、動物の種類で分けて見られる
// ・1〜3位は表彰台、4位から下は1位との差がわかる棒
// ・先週の1位（チャンピオン）と、自分の子の順位も出す

const _orange = Color(0xFFE8845A);
const _brown = Color(0xFF3D2B1F);
const _cream = Color(0xFFFFF8F5);
const _gold = Color(0xFFF2B830);
const _silver = Color(0xFFB8C2CC);
const _bronze = Color(0xFFD08A57);

class _Dept {
  const _Dept(this.key, this.emoji, this.label);
  final String key; // votes の中の名前。'total' は合計（voteCount）
  final String emoji;
  final String label;
}

const _depts = [
  _Dept('kawaii', '😍', 'かわいい'),
  _Dept('omoshiroi', '🤣', 'おもしろい'),
  _Dept('iyashi', '🥹', '癒される'),
  _Dept('total', '👑', '総合'),
];

class _AnimalGroup {
  const _AnimalGroup(this.label, this.emoji, this.types);
  final String label;
  final String emoji;
  // 投稿の animalType がこの中にあれば、このグループ。null は「すべて」。
  final List<String>? types;
}

const _groups = [
  _AnimalGroup('すべて', '🐾', null),
  _AnimalGroup('犬', '🐶', ['犬']),
  _AnimalGroup('猫', '🐱', ['猫']),
  _AnimalGroup('うさぎ', '🐰', ['うさぎ']),
  _AnimalGroup('小鳥', '🐦', ['小鳥']),
  _AnimalGroup('小動物', '🐹',
      ['ハムスター・小動物', 'フェレット', 'フクロモモンガ・グライダー系']),
  _AnimalGroup('爬虫類', '🦎', ['爬虫類']),
  _AnimalGroup('その他', '🌈', []),
];

const _knownTypes = [
  '犬',
  '猫',
  'うさぎ',
  '小鳥',
  'ハムスター・小動物',
  'フェレット',
  'フクロモモンガ・グライダー系',
  '爬虫類',
];

DateTime _weekStart(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: now.weekday - 1));
}

class _Entry {
  _Entry(this.id, this.data, this.score);
  final String id;
  final Map<String, dynamic> data;
  final int score;
  String get petName => (data['petName'] ?? '').toString();
  String get imageUrl => (data['imageUrl'] ?? '').toString();
  String get uid => (data['uid'] ?? '').toString();
}

/// ホームの🏆から開くランキングの画面
class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text('ランキング 🏆',
            style: TextStyle(fontWeight: FontWeight.w900, color: _brown)),
      ),
      body: const WeeklyRankingView(),
    );
  }
}

/// ランキングの中身（ペット自慢の「週間ランキング」タブでも使う）
class WeeklyRankingView extends StatefulWidget {
  // embedded: ホームの中など、外側がスクロールする場所に置くときは true
  const WeeklyRankingView({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<WeeklyRankingView> createState() => _WeeklyRankingViewState();
}

class _WeeklyRankingViewState extends State<WeeklyRankingView>
    with SingleTickerProviderStateMixin {
  int _dept = 0;
  int _group = 0;
  late final AnimationController _bob;
  late final DateTime _thisWeek;
  late final DateTime _lastWeek;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _thisWeek = _weekStart(DateTime.now());
    _lastWeek = _thisWeek.subtract(const Duration(days: 7));
    _stream = FirebaseFirestore.instance
        .collection('petBrags')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_lastWeek))
        .orderBy('createdAt')
        .snapshots();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  int _score(Map<String, dynamic> d) {
    final key = _depts[_dept].key;
    if (key == 'total') return (d['voteCount'] as num?)?.toInt() ?? 0;
    final votes = d['votes'] as Map<String, dynamic>? ?? {};
    return (votes[key] as num?)?.toInt() ?? 0;
  }

  bool _inGroup(Map<String, dynamic> d) {
    final g = _groups[_group];
    if (g.types == null) return true;
    final t = d['animalType'] as String?;
    if (g.types!.isEmpty) return t == null || !_knownTypes.contains(t);
    return g.types!.contains(t);
  }

  List<_Entry> _rank(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = docs
        .where((d) => _inGroup(d.data()))
        .map((d) => _Entry(d.id, d.data(), _score(d.data())))
        .toList();
    list.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      // 同じ票数なら、先に投稿した方が上
      final at = a.data['createdAt'] as Timestamp?;
      final bt = b.data['createdAt'] as Timestamp?;
      if (at == null || bt == null) return 0;
      return at.compareTo(bt);
    });
    return list;
  }

  String _timeLeft() {
    final end = _thisWeek.add(const Duration(days: 7));
    final left = end.difference(DateTime.now());
    if (left.inDays >= 1) return 'あと${left.inDays}日${left.inHours % 24}時間';
    if (left.inHours >= 1) return 'あと${left.inHours}時間';
    return 'あと${math.max(1, left.inMinutes)}分';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final all = snapshot.data?.docs ?? [];
        final thisWeekDocs = all.where((d) {
          final t = d.data()['createdAt'] as Timestamp?;
          // まだ時刻が入っていない（投稿した直後の）ものは今週に入れる
          return t == null || !t.toDate().isBefore(_thisWeek);
        });
        final lastWeekDocs = all.where((d) {
          final t = d.data()['createdAt'] as Timestamp?;
          return t != null && t.toDate().isBefore(_thisWeek);
        });
        final ranking = _rank(thisWeekDocs);
        final lastRanking = _rank(lastWeekDocs);
        final champion =
            lastRanking.isNotEmpty && lastRanking.first.score > 0 ? lastRanking.first : null;

        return CustomScrollView(
          shrinkWrap: widget.embedded,
          physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _deptChips()),
            SliverToBoxAdapter(child: _groupChips()),
            if (snapshot.hasError)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('ランキングを読みこめませんでした',
                          style: TextStyle(color: Colors.grey))),
                ),
              )
            else if (!snapshot.hasData)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: _orange)),
                ),
              )
            else ...[
              if (champion != null) SliverToBoxAdapter(child: _championCard(champion)),
              SliverToBoxAdapter(child: _myRank(ranking)),
              if (ranking.isEmpty)
                SliverToBoxAdapter(child: _empty())
              else ...[
                SliverToBoxAdapter(
                  child: _Podium(
                    key: ValueKey('podium-$_dept-$_group'),
                    top: ranking.take(3).toList(),
                    bob: _bob,
                    unit: _depts[_dept].emoji,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final e = ranking[i + 3];
                        final best = ranking.first.score;
                        return _RankRow(
                          key: ValueKey('row-$_dept-$_group-${e.id}'),
                          rank: i + 4,
                          entry: e,
                          ratio: best <= 0 ? 0 : e.score / best,
                          emoji: _depts[_dept].emoji,
                          delay: i,
                        );
                      },
                      childCount: math.max(0, ranking.length - 3),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8845A), Color(0xFFF6B26B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Transform.rotate(
                angle: (_bob.value - 0.5) * 0.25,
                child: child,
              ),
              child: const Text('🏆', style: TextStyle(fontSize: 38)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今週のランキング',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('しめきりまで ${_timeLeft()}（毎週月曜に新しい週）',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 2),
                  const Text('投稿を開いて、気持ちを1票。',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deptChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: List.generate(_depts.length, (i) {
          final d = _depts[i];
          final sel = i == _dept;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dept = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? _orange : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _orange : const Color(0xFFF0DCD2)),
                  boxShadow: sel
                      ? [BoxShadow(color: _orange.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: sel ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: Text(d.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 2),
                    Text(d.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : Colors.grey[700])),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _groupChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final g = _groups[i];
          final sel = i == _group;
          return GestureDetector(
            onTap: () => setState(() => _group = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? _brown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _brown : const Color(0xFFF0DCD2)),
              ),
              child: Text('${g.emoji} ${g.label}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.white : _brown)),
            ),
          );
        },
      ),
    );
  }

  Widget _championCard(_Entry e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => showPostDetail(context, e.id),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              _Avatar(url: e.imageUrl, size: 44, ring: _gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('先週のチャンピオン（${_depts[_dept].label}${_groups[_group].types == null ? '' : '・${_groups[_group].label}'}）',
                        style: TextStyle(fontSize: 11, color: Colors.brown[400])),
                    Text(e.petName.isEmpty ? 'なまえなし' : e.petName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: _brown, fontSize: 15)),
                  ],
                ),
              ),
              const Text('👑', style: TextStyle(fontSize: 26)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myRank(List<_Entry> ranking) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return const SizedBox.shrink();
    final i = ranking.indexWhere((e) => e.uid == me);
    if (i < 0) return const SizedBox.shrink();
    final e = ranking[i];
    String sub;
    if (i == 0) {
      sub = 'いま1位！このまま守りきろう';
    } else {
      final diff = ranking[i - 1].score - e.score + 1;
      sub = 'あと$diff票で${i}位';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => showPostDetail(context, e.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _orange.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.pets, color: _orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${e.petName.isEmpty ? 'あなたの子' : e.petName}は いま${i + 1}位',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: _brown)),
                    TextSpan(
                        text: '　$sub',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final g = _groups[_group];
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _bob,
            builder: (_, child) => Transform.translate(
                offset: Offset(0, -6 * _bob.value), child: child),
            child: Text(g.emoji, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 12),
          Text(
            g.types == null
                ? '今週の投稿は、まだありません'
                : '今週の「${g.label}」の投稿は、まだありません',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _brown),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text('「ペット自慢」から投稿すると、ここに並びます。最初の1位になれるチャンス！',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// 1〜3位の表彰台。下からせり上がって、1位には王冠がゆれる。
class _Podium extends StatelessWidget {
  const _Podium({super.key, required this.top, required this.bob, required this.unit});
  final List<_Entry> top;
  final Animation<double> bob;
  final String unit;

  @override
  Widget build(BuildContext context) {
    // 並びは 2位・1位・3位
    final order = [1, 0, 2];
    final heights = [70.0, 100.0, 52.0];
    final colors = [_gold, _silver, _bronze];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((place) {
          if (place >= top.length) return const Expanded(child: SizedBox());
          final e = top[place];
          return Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 700 + (2 - place) * 120),
              curve: Curves.easeOutBack,
              builder: (context, t, _) {
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - t)),
                    child: GestureDetector(
                      onTap: () => showPostDetail(context, e.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (place == 0)
                            AnimatedBuilder(
                              animation: bob,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(0, -5 * bob.value),
                                child: Transform.rotate(
                                    angle: (bob.value - 0.5) * 0.2, child: child),
                              ),
                              child: const Text('👑', style: TextStyle(fontSize: 28)),
                            ),
                          _Avatar(
                            url: e.imageUrl,
                            size: place == 0 ? 84 : 66,
                            ring: colors[place],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.petName.isEmpty ? 'なまえなし' : e.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, color: _brown, fontSize: 13),
                          ),
                          Text('$unit ${e.score}票',
                              style: const TextStyle(
                                  fontSize: 12, color: _orange, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            height: heights[place] * t.clamp(0.0, 1.2),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors[place], colors[place].withOpacity(0.7)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${place + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 4位から下の1行。1位との差が棒でわかる。
class _RankRow extends StatelessWidget {
  const _RankRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.ratio,
    required this.emoji,
    required this.delay,
  });
  final int rank;
  final _Entry entry;
  final double ratio;
  final String emoji;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + math.min(delay, 8) * 60),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(24 * (1 - t), 0), child: child),
      ),
      child: GestureDetector(
        onTap: () => showPostDetail(context, entry.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[500])),
              ),
              _Avatar(url: entry.imageUrl, size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.petName.isEmpty ? 'なまえなし' : entry.petName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF5E6DE),
                          valueColor: const AlwaysStoppedAnimation(_orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$emoji ${entry.score}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _orange)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size, this.ring});
  final String url;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final img = url.isNotEmpty
        ? Image.network(url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder())
        : _placeholder();
    return Container(
      padding: EdgeInsets.all(ring == null ? 0 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring ?? Colors.transparent,
        boxShadow: ring == null
            ? null
            : [BoxShadow(color: ring!.withOpacity(0.45), blurRadius: 10)],
      ),
      child: ClipOval(child: img),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: const Color(0xFFFFEFE6),
        alignment: Alignment.center,
        child: Text('🐾', style: TextStyle(fontSize: size * 0.4)),
      );
}
