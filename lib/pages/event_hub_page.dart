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
import '../widgets/event_board.dart';
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

  @override
  void initState() {
    super.initState();
    TabReselect.tabs[2].addListener(_toTop);
    BlockedUsers.instance.ensureListening();
  }

  @override
  void dispose() {
    TabReselect.tabs[2].removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final live = liveOnlineEvents(now);
    final upcoming = upcomingOnlineEvents(now);
    final today = live.isNotEmpty ? live.first : (upcoming.isNotEmpty ? upcoming.first : null);
    final others = [...live.skip(1), ...upcoming.where((e) => e != today)].take(4).toList();
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: CorkBoard(
        child: ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(18, top + 14, 18, 40),
          children: [
            // 掲示板の名前（上にテープでとめた紙）
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 190,
                child: PaperFlyer(
                  attach: FlyerAttach.tape,
                  angle: -2,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: const Text('イベントの掲示板',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (today != null) TodayFlyer(event: today, now: now),
            const SizedBox(height: 26),
            _choices(today),
            if (others.isNotEmpty) ...[
              const SizedBox(height: 28),
              _boardLabel('ほかの貼り紙'),
              const SizedBox(height: 14),
              _otherFlyers(others, now),
            ],
            const SizedBox(height: 28),
            _boardLabel('動物ごとの集まり'),
            const SizedBox(height: 12),
            _animalStickers(),
          ],
        ),
      ),
    );
  }

  Widget _boardLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)]));

  // 「今日はどうする？」：気分でえらぶ3つ
  Widget _choices(OnlineEvent? today) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _boardLabel('今日はどうする？'),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Sticker(
          emoji: '👀',
          label: '見るだけ',
          color: kPaperBlue,
          size: 70,
          onTap: () {
            if (today == null) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: today.room)));
          },
        ),
        Sticker(
          emoji: '🐾',
          label: 'スタンプで\n参加',
          color: kPaperYellow,
          size: 70,
          onTap: () {
            if (today != null) showQuickStampSheet(context, today);
          },
        ),
        Sticker(
          emoji: '🤝',
          label: '会いに行く',
          color: kPaperPink,
          size: 70,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetBoardPage())),
        ),
      ]),
    ]);
  }

  Widget _otherFlyers(List<OnlineEvent> list, DateTime now) {
    const colors = [kPaperYellow, kPaperGreen, kPaperBlue, kPaperPink];
    const angles = [-2.5, 2.0, 1.5, -1.5];
    return Wrap(
      spacing: 14,
      runSpacing: 22,
      children: [
        for (var i = 0; i < list.length; i++)
          LayoutBuilder(builder: (context, c) {
            final w = (MediaQuery.of(context).size.width - 36 - 14) / 2;
            final e = list[i];
            final live = e.isLive(now);
            return SizedBox(
              width: w,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: e.room))),
                child: PaperFlyer(
                  color: colors[i % colors.length],
                  angle: angles[i % angles.length],
                  attach: i.isEven ? FlyerAttach.pin : FlyerAttach.tape,
                  pinColor: i % 3 == 0 ? kPinRed : const Color(0xFF3E7BFA),
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(e.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 2),
                    Text(e.kind == 'photo' ? 'テーマ「${e.theme}」' : e.theme,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: kInk, height: 1.35)),
                    const SizedBox(height: 8),
                    Text(live ? 'いま開催中' : '${whenText(e.start)}から',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: live ? kPinRed : kInk.withValues(alpha: 0.6))),
                  ]),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _animalStickers() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      childAspectRatio: 0.78,
      children: [
        for (final g in animalGroups)
          Sticker(
            emoji: g.emoji,
            label: g.name,
            color: g.colors.first,
            size: 56,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalGroupPage(group: g))),
          ),
      ],
    );
  }
}

// ── 参加のしかた（スタンプ1つで参加） ──

String? _cachedName;
DateTime? _lastQuick;

Future<String> _myName() async {
  if (_cachedName != null) return _cachedName!;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return '名無しさん';
  try {
    final d = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final n = d.data()?['name'];
    _cachedName = (n is String && n.isNotEmpty) ? n : '名無しさん';
  } catch (_) {
    return '名無しさん';
  }
  return _cachedName!;
}

// 今日のイベントに、スタンプ1つで参加する。送れたら true
Future<bool> sendQuickStamp(BuildContext context, OnlineEvent e, String stamp) async {
  final messenger = ScaffoldMessenger.of(context);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  final now = DateTime.now();
  if (!e.isLive(now)) {
    messenger.showSnackBar(SnackBar(content: Text('${whenText(e.start)}から参加できます')));
    return false;
  }
  final last = _lastQuick;
  if (last != null && now.difference(last).inSeconds < 8) {
    messenger.showSnackBar(const SnackBar(content: Text('少しだけ時間をあけてから押してください🐾')));
    return false;
  }
  try {
    await _posts(e.roomId).add({
      'uid': uid,
      'name': await _myName(),
      'text': stamp,
      'createdAt': FieldValue.serverTimestamp(),
      'reactions': <String, dynamic>{},
      'span': e.span,
    });
    _lastQuick = DateTime.now();
    messenger.showSnackBar(SnackBar(content: Text('「${e.title}」に参加しました $stamp')));
    return true;
  } catch (err) {
    debugPrint('スタンプで参加のエラー: $err');
    messenger.showSnackBar(const SnackBar(content: Text('参加できませんでした。電波のよいところで、もう一度ためしてください')));
    return false;
  }
}

void showQuickStampSheet(BuildContext context, OnlineEvent e) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kPaperWhite,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('「${e.title}」にスタンプを送る',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, color: kInk, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('押すだけで参加になります', style: TextStyle(fontSize: 12, color: kInk)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final s in quickStamps)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(sheet);
                    sendQuickStamp(context, e, s);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kPaperYellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    ),
  );
}

// ── 今日の貼り紙（いちばん大きい1枚。下のタブをちぎると参加） ──

class TodayFlyer extends StatelessWidget {
  final OnlineEvent event;
  final DateTime now;
  final bool compact; // ホームにまぜるときは小さめ
  const TodayFlyer({super.key, required this.event, required this.now, this.compact = false});

  String _left() {
    final d = event.end.difference(now);
    if (d.inDays >= 1) return 'あと${d.inDays}日';
    if (d.inHours >= 1) return 'あと${d.inHours}時間';
    return 'あと${d.inMinutes}分';
  }

  @override
  Widget build(BuildContext context) {
    final live = event.isLive(now);
    final color = switch (event.kind) {
      'photo' => kPaperPink,
      'talk' => kPaperBlue,
      'challenge' => kPaperGreen,
      _ => kPaperYellow,
    };
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _posts(event.roomId).where('span', isEqualTo: event.span).limit(300).snapshots(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? const [])
            .where((d) => !BlockedUsers.instance.isBlocked(d.data()['uid']))
            .toList();
        int ms(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final t = d.data()['createdAt'];
          return t is Timestamp ? t.millisecondsSinceEpoch : 8640000000000000;
        }

        docs.sort((a, b) => ms(b).compareTo(ms(a)));
        final people = docs.map((d) => d.data()['uid']).toSet().length;
        final latest = docs.take(2).toList();
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: event.room))),
          child: PaperFlyer(
            color: color,
            angle: compact ? 0.8 : -1.2,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(live ? '開催中・${_left()}' : '${whenText(event.start)}から',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: live ? kPinRed : kInk)),
                const Spacer(),
                Builder(
                  builder: (bc) => IconButton(
                    tooltip: '友達をさそう',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.ios_share, size: 20, color: kInk),
                    onPressed: () => _share(bc,
                        'AniMatchの「${event.title}」に、いっしょに参加しませんか？${event.emoji}\n${event.kind == 'photo' ? 'テーマ「${event.theme}」' : event.theme}'),
                  ),
                ),
                Text(event.emoji, style: TextStyle(fontSize: compact ? 28 : 36)),
              ]),
              const SizedBox(height: 4),
              Text(event.title,
                  style: TextStyle(
                      fontSize: compact ? 22 : 28,
                      fontWeight: FontWeight.w900,
                      color: kInk,
                      height: 1.15)),
              const SizedBox(height: 6),
              Text(event.kind == 'photo' ? 'テーマ「${event.theme}」' : event.theme,
                  style: TextStyle(fontSize: compact ? 14 : 16, fontWeight: FontWeight.bold, color: kInk, height: 1.4)),
              const SizedBox(height: 6),
              Text(event.howTo, style: const TextStyle(fontSize: 12, color: kInk, height: 1.4)),
              const SizedBox(height: 12),
              // いまの様子（だれかがいる感じ）
              if (latest.isEmpty)
                Text(live ? 'まだだれも参加していません。いちばん乗りのチャンス' : 'はじまったら、ここに参加した人が出ます',
                    style: TextStyle(fontSize: 12, color: kInk.withValues(alpha: 0.7)))
              else ...[
                Text('$people人が参加中', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 4),
                for (final d in latest)
                  Text(
                    '${d.data()['name'] ?? '名無しさん'}：${_short((d.data()['text'] as String?) ?? '')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: kInk.withValues(alpha: 0.8)),
                  ),
              ],
              const SizedBox(height: 12),
              Text(live ? 'ちぎって参加（スタンプ🐾が1つ送られます）' : 'はじまったら、ちぎって参加できます',
                  style: TextStyle(fontSize: 11, color: kInk.withValues(alpha: 0.7))),
              const SizedBox(height: 4),
              TearTabs(
                taken: people,
                enabled: live,
                onTear: () => sendQuickStamp(context, event, '🐾'),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _short(String t) {
    if (t.isEmpty) return '📷 写真';
    return t.replaceAll('\n', ' ');
  }
}

// ── 会いに行く：会うイベントの掲示板 ──

class MeetBoardPage extends StatefulWidget {
  const MeetBoardPage({super.key});

  @override
  State<MeetBoardPage> createState() => _MeetBoardPageState();
}

class _MeetBoardPageState extends State<MeetBoardPage> {
  List<Map<String, dynamic>>? _events;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _events = await loadMeetEvents(limit: 60);
    } catch (_) {
      _events = const [];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kCork,
        foregroundColor: Colors.white,
        title: const Text('会いに行く', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: CorkBoard(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 22, 18, 40), children: [
            PaperFlyer(
              attach: FlyerAttach.tape,
              angle: 1,
              child: const Text(
                'おさんぽ会や、同じ動物の人の会など、会って楽しむイベントです（18歳以上）。「はじめて歓迎」「1人参加OK」「見学だけOK」のしるしを目印にどうぞ。',
                style: TextStyle(fontSize: 13, color: kInk, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            if (_events == null)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (_events!.isEmpty)
              const Text('いま募集中の会うイベントはありません',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            else
              for (final e in _events!) MeetEventTile(event: e, onBack: _load),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPaperWhite,
                foregroundColor: kInk,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventPage()));
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('会うイベントを見る・ひらく'),
            ),
          ]),
        ),
      ),
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
