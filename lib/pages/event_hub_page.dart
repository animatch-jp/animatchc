// 下のタブ「イベント」：アプリの中でも、外でも交流できる場所（ホームと同じくらい大きな、アプリの中心）
//
// 考え方（11/15 社長と決めた「参加の階段」）
//   👀 見る → 🐾 スタンプで応援 → 📸 写真やひとことで参加 → 🤝 会う
//   ・人見知りの人は多い（63%）。見るだけの人がふつう（90-9-1）。だから、どの段でも「参加」になる
//   ・同じ動物の人どうしだと話しやすい → どうぶつ別の集まり（犬・猫だけでなく、うさぎ・小鳥・爬虫類なども同じ大きさで並べる）
//   ・会うイベントには「安心のしるし」（はじめて歓迎・1人参加OK・見学だけOK・少人数・話さなくてOK・動物はお留守番）
// アプリの中のイベントは hiroba_data.dart の予定表から毎週自動でひらく（写真大会・チャレンジ・話しあい会・お祭り）
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/blocked_users.dart';
import '../services/tab_reselect.dart';
import '../widgets/festive_backdrop.dart';
import '../widgets/motion.dart';
import 'event_page.dart';
import 'hiroba_data.dart';
import 'hiroba_room_page.dart';

const _brown = Color(0xFF3D2B1F);
const _orange = Color(0xFFE8845A);

CollectionReference<Map<String, dynamic>> _posts(String roomId) =>
    FirebaseFirestore.instance.collection('hiroba').doc(roomId).collection('hirobaPosts');

Future<void> _share(BuildContext btnContext, String text) async {
  final box = btnContext.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  try {
    await SharePlus.instance.share(ShareParams(text: '$text\n$inviteUrl', sharePositionOrigin: origin));
  } catch (e) {
    debugPrint('イベントのシェアのエラー: $e');
  }
}

// 会うイベント（これから・終わっていないもの）を読む
Future<List<Map<String, dynamic>>> loadMeetEvents({int limit = 40}) async {
  final snap = await FirebaseFirestore.instance
      .collection('events')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .get();
  final now = DateTime.now();
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).where((e) {
    if (BlockedUsers.instance.isBlocked(e['organizerUid'])) return false;
    final end = e['endDate'];
    return end is! Timestamp || end.toDate().isAfter(now);
  }).toList();
}

class EventHubPage extends StatefulWidget {
  const EventHubPage({super.key});

  @override
  State<EventHubPage> createState() => _EventHubPageState();
}

class _EventHubPageState extends State<EventHubPage> {
  final _scroll = ScrollController();
  void _toTop() => TabReselect.toTop([_scroll]);

  final Map<String, int> _counts = {}; // span → 参加の数
  List<Map<String, dynamic>>? _meet;

  @override
  void initState() {
    super.initState();
    TabReselect.tabs[2].addListener(_toTop);
    BlockedUsers.instance.ensureListening();
    _load();
  }

  @override
  void dispose() {
    TabReselect.tabs[2].removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final live = liveOnlineEvents(now);
    await Future.wait([
      for (final e in live)
        _posts(e.roomId).where('span', isEqualTo: e.span).count().get().then(
            (r) => _counts[e.span] = r.count ?? 0,
            onError: (_) => _counts[e.span] = 0),
      loadMeetEvents().then((v) => _meet = v, onError: (_) => _meet = const []),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _openRoom(HirobaRoom room) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: room)));
    _load();
  }

  void _showLadder() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🐾 自分のペースで参加しよう',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _brown)),
            const SizedBox(height: 12),
            for (final r in const [
              ('👀', '見る', 'イベントをのぞくだけでも参加です。入っても、だれにも知らされません'),
              ('🐾', '応援する', 'スタンプを1つ押すだけ。文を考えなくて大丈夫'),
              ('📸', '参加する', '写真1枚、ひとことだけ。名前を出さずに「ないしょさん」でも書けます'),
              ('🤝', '会う', '慣れてきたら、少人数の会へ。「はじめて歓迎」「1人参加OK」のしるしを目印に'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.$2, style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
                      Text(r.$3, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4)),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 4),
            Text('ここからは1対1のメッセージは送れません。いやな投稿は長押しで通報・ブロックできます。',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final live = liveOnlineEvents(now);
    final upcoming = upcomingOnlineEvents(now).take(5).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              sliver: SliverList.list(children: [
                _ladder(),
                const SizedBox(height: 18),
                _title('🎪 いま開催中', 'アプリの中で、おうちから参加'),
                const SizedBox(height: 10),
                if (live.isEmpty)
                  _emptyLive()
                else
                  for (final e in live) ...[_liveCard(e, now), const SizedBox(height: 12)],
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _title('🗓️ このあと', 'これから1週間の予定'),
                  const SizedBox(height: 8),
                  _upcoming(upcoming),
                ],
                const SizedBox(height: 22),
                _title('🐾 どうぶつ別の集まり', '同じ動物の人とだと話しやすい'),
                const SizedBox(height: 10),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 84,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _groupTile(animalGroups[i]),
                  childCount: animalGroups.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 22, 14, 30),
              sliver: SliverList.list(children: [
                _title('🤝 会うイベント', 'おさんぽ会・同じ動物の会など（18歳以上）'),
                const SizedBox(height: 10),
                ..._meetList(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _orange,
                    side: const BorderSide(color: _orange),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventPage()));
                    _load();
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: const Text('会うイベントをすべて見る・ひらく'),
                ),
                const SizedBox(height: 16),
                _inviteCard(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final top = MediaQuery.of(context).padding.top;
    final fes = currentFestival(DateTime.now());
    return SizedBox(
      height: 150 + top,
      child: FestiveBackdrop(
        colors: fes?.colors ?? const [Color(0xFFFFA26B), Color(0xFFFF6F91)],
        style: fes?.style ?? BackdropStyle.bunting,
        seed: 11,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, top + 50, 12, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('イベント',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
                SizedBox(height: 2),
                Text('アプリの中でも、外でも。見るだけでも参加です',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              ]),
            ),
            IconButton(
              tooltip: '参加のしかた',
              onPressed: _showLadder,
              icon: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _ladder() {
    const steps = [('👀', '見る'), ('🐾', '応援'), ('📸', '参加'), ('🤝', '会う')];
    return Pressable(
      onTap: _showLadder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _orange.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Row(children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Column(children: [
                  Text(steps[i].$1, style: const TextStyle(fontSize: 22)),
                  Text(steps[i].$2,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _brown)),
                ]),
              ),
              if (i < steps.length - 1) Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
            ],
          ]),
          const SizedBox(height: 4),
          Text('どの段でも「参加」です。自分のペースでどうぞ',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _title(String t, String sub) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brown)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(sub,
            overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ),
    ]);
  }

  Widget _emptyLive() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Text('いま開いているイベントはありません。下の「このあと」を見てください🐾',
          style: TextStyle(color: _brown)),
    );
  }

  String _left(OnlineEvent e, DateTime now) {
    final d = e.end.difference(now);
    if (d.inDays >= 1) return 'あと${d.inDays}日';
    if (d.inHours >= 1) return 'あと${d.inHours}時間';
    return 'あと${d.inMinutes}分';
  }

  Widget _liveCard(OnlineEvent e, DateTime now) {
    final n = _counts[e.span];
    final goal = e.goal;
    return Pressable(
      onTap: () => _openRoom(e.room),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FestiveBackdrop(
          colors: e.colors,
          style: e.style,
          seed: e.span.hashCode,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _whiteTag('● 開催中・${_left(e, now)}', e.colors.last),
                const SizedBox(width: 6),
                if (n != null) _whiteTag(n == 0 ? 'いちばん乗りのチャンス' : '$n件の参加', e.colors.last),
              ]),
              const SizedBox(height: 8),
              Text('${e.emoji} ${e.title}',
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              const SizedBox(height: 2),
              Text(e.kind == 'photo' ? 'テーマ「${e.theme}」' : e.theme,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(e.howTo, style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (goal != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: n == null ? null : (n / goal).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(n != null && n >= goal ? '🎉 みんなで$goalこ達成！' : 'みんなで$goalこ集めよう：${n ?? '…'} / $goal',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Expanded(
                  child: Text('のぞいてみる →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Builder(
                  builder: (bc) => TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2)),
                    onPressed: () => _share(bc,
                        'AniMatchで「${e.title}」をやっています${e.emoji}\n${e.kind == 'photo' ? 'テーマ「${e.theme}」' : e.theme}\nいっしょに参加しませんか？'),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('友達をさそう', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _whiteTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _upcoming(List<OnlineEvent> list) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) Divider(height: 1, color: Colors.grey[200]),
          ListTile(
            dense: true,
            leading: Text(list[i].emoji, style: const TextStyle(fontSize: 24)),
            title: Text(list[i].title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
            subtitle: Text(
                '${whenText(list[i].start)}から・${list[i].kind == 'photo' ? 'テーマ「${list[i].theme}」' : list[i].theme}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            onTap: () => _openRoom(list[i].room),
          ),
        ],
      ]),
    );
  }

  Widget _groupTile(AnimalGroup g) {
    return Pressable(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalGroupPage(group: g)));
        _load();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: g.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(g.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 2),
          Text(g.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
        ]),
      ),
    );
  }

  List<Widget> _meetList() {
    final list = _meet;
    if (list == null) return [const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))];
    if (list.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Text('いま募集中の会うイベントはありません。下のボタンから、ひらくこともできます（18歳以上）',
              style: TextStyle(color: _brown, height: 1.4)),
        ),
      ];
    }
    return [for (final e in list.take(4)) MeetEventTile(event: e, onBack: _load)];
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF1E6), Color(0xFFFFE3EC)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('👋', style: TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('友達といっしょに', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _brown)),
            SizedBox(height: 2),
            Text('知っている人がいると、はじめてでも安心です', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Builder(
          builder: (bc) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _share(bc, 'AniMatchのイベントに、いっしょに参加しませんか？🐾\n見るだけでも大丈夫です'),
            child: const Text('さそう'),
          ),
        ),
      ]),
    );
  }
}

// 会うイベントの小さなカード（ハブとどうぶつ別の集まりで使う）
class MeetEventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onBack;
  const MeetEventTile({super.key, required this.event, this.onBack});

  @override
  Widget build(BuildContext context) {
    final img = event['imageUrl'] as String?;
    return Pressable(
      onTap: () async {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => EventPage(initialEventId: event['id'] as String)));
        onBack?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: img != null && img.isNotEmpty
                ? Image.network(img, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event['title'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
              const SizedBox(height: 2),
              Text('${event['date'] ?? ''}・${event['location'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              eventTagChips(event),
            ]),
          ),
          Text('${event['participantCount'] ?? 0}人',
              style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: _orange.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: const Text('🐾', style: TextStyle(fontSize: 28)),
      );
}

// どうぶつ別の集まり：その動物の部屋・その動物の会うイベント・会うときの気づかい
class AnimalGroupPage extends StatefulWidget {
  final AnimalGroup group;
  const AnimalGroupPage({super.key, required this.group});

  @override
  State<AnimalGroupPage> createState() => _AnimalGroupPageState();
}

class _AnimalGroupPageState extends State<AnimalGroupPage> {
  List<Map<String, dynamic>>? _events;
  int? _today;

  AnimalGroup get g => widget.group;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    await Future.wait([
      loadMeetEvents(limit: 80).then((v) => _events = v.where((e) => e['animal'] == g.name).toList(),
          onError: (_) => _events = const []),
      _posts(g.room.id)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .count()
          .get()
          .then((r) => _today = r.count ?? 0, onError: (_) => _today = 0),
    ]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: FestiveBackdrop(colors: g.colors, style: BackdropStyle.stars, seed: g.key.hashCode),
        title: Text('${g.emoji} ${g.name}の集まり',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(14), children: [
          Pressable(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: g.room)));
              _load();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: g.colors),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Text(g.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${g.name}の部屋',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(
                        _today == null
                            ? 'いつでも開いています'
                            : (_today == 0 ? '今日はまだ静か。いちばん乗りのチャンス' : '今日 $_today件の投稿'),
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const Text('写真・ひとこと・スタンプで。見るだけでもOK',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: g.colors.first.withValues(alpha: 0.5)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(g.note, style: const TextStyle(color: _brown, fontSize: 13, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 18),
          Text('🤝 ${g.name}の会うイベント',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brown)),
          const SizedBox(height: 10),
          if (_events == null)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_events!.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text('いま募集中の${g.name}の会はありません。18歳以上なら、ひらくこともできます。「どの動物の会？」で「${g.name}」をえらんでください',
                  style: const TextStyle(color: _brown, height: 1.4)),
            )
          else
            for (final e in _events!) MeetEventTile(event: e, onBack: _load),
          const SizedBox(height: 8),
          if (uid != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: const BorderSide(color: _orange),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventPage()));
                _load();
              },
              icon: const Icon(Icons.add),
              label: Text('${g.name}の会をひらく・ほかの会を見る'),
            ),
        ]),
      ),
    );
  }
}
