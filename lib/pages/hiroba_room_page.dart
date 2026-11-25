// イベントの部屋（アプリの中のイベント・どうぶつ別の部屋）：ひとこと・写真・スタンプで参加する場所
// ・入っても、だれにも知らされない（見るだけでもよい）
// ・書いた人のペットの写真と飼い主の名前を出す。押すと、プロフィール（名前・ひとこと・ペット）だけ見られる（ここから 1対1 のメッセージは送れない）
// ・いちばん上にイベントのカードを大きく出す（11/25 社長「メインのイベントを大きく、真ん中に」）
// ・長押しで「通報」「この人をブロック」。自分の投稿は「消す」
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/blocked_users.dart';
import '../services/cloudinary_service.dart';
import '../services/content_filter.dart';
import '../widgets/festive_backdrop.dart';
import '../widgets/motion.dart';
import 'event_extras.dart';
import 'hiroba_data.dart';
import 'report_page.dart';

const _brown = Color(0xFF3D2B1F);

class HirobaRoomPage extends StatefulWidget {
  final HirobaRoom room;
  const HirobaRoomPage({super.key, required this.room});

  @override
  State<HirobaRoomPage> createState() => _HirobaRoomPageState();
}

class _HirobaRoomPageState extends State<HirobaRoomPage> {
  static bool _celebrated = false; // はじめて書いたときのお祝いは、1回だけ
  static DateTime? _lastPost; // 続けて送りすぎないように

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _hideName = false;
  bool _sending = false;
  bool _uploading = false;
  String? _imageUrl; // これから送る写真
  bool _popular = false; // 写真大会：スタンプの多い順
  String _myName = '名無しさん';

  HirobaRoom get room => widget.room;
  String? get _me => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance
      .collection('hiroba')
      .doc(room.id)
      .collection('hirobaPosts');

  @override
  void initState() {
    super.initState();
    BlockedUsers.instance.ensureListening();
    // 部屋を開くたびに、イベントのカードと参加している子は、ふわっと出す
    _Appear.shown.removeWhere((k) => k.startsWith('hero_') || k.startsWith('face_'));
    _loadName();
    _initExtras();
  }

  Future<void> _loadName() async {
    final me = _me;
    if (me == null) return;
    try {
      final d = await FirebaseFirestore.instance.collection('users').doc(me).get();
      final n = d.data()?['name'];
      if (n is String && n.isNotEmpty && mounted) setState(() => _myName = n);
    } catch (_) {}
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _evtSub?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _snack(String m, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: color));
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    final me = _me;
    final image = _imageUrl;
    if ((text.isEmpty && image == null) || me == null || _sending) return;
    if (!_isOpen) {
      _snack(_closedText);
      return;
    }
    if (text.runes.length > 140) {
      _snack('140文字までです。少し短くしてください');
      return;
    }
    final last = _lastPost;
    if (last != null && DateTime.now().difference(last).inSeconds < 8) {
      _snack('少しだけ時間をあけてから送ってください🐾');
      return;
    }
    if (text.isNotEmpty && ContentFilter.blocked(context, [text])) return;
    setState(() => _sending = true);
    try {
      await _col.add({
        'uid': me,
        'name': _hideName ? hiddenName : _myName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': <String, dynamic>{},
        if (room.span != null) 'span': room.span,
        if (image != null) 'imageUrl': image,
      });
      _lastPost = DateTime.now();
      evtJoin(room);
      _ctrl.clear();
      _imageUrl = null;
      _focus.unfocus();
      if (!_celebrated && mounted) {
        _celebrated = true;
        showHappyBurst(context,
            message: 'イベントに参加しました！', sub: '参加してくれて、ありがとう', emoji: room.emoji, color: room.colors.last);
      }
    } catch (e) {
      debugPrint('ひろばの投稿のエラー: $e');
      _snack('送れませんでした。電波のよいところで、もう一度ためしてください', color: Colors.red);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool get _isOpen {
    final now = DateTime.now();
    final o = room.opensAt, c = room.closesAt;
    if (o != null && now.isBefore(o)) return false;
    if (c != null && !now.isBefore(c)) return false;
    return true;
  }

  String get _closedText {
    final o = room.opensAt, c = room.closesAt;
    if (o != null && DateTime.now().isBefore(o)) {
      return '${whenText(o)}に開きます。それまでは読むだけです';
    }
    if (c != null) return 'この会は終わりました。読むことはできます';
    return 'いまは書きこめません';
  }

  Future<void> _pickImage() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) _imageUrl = url;
    });
    if (url == null) _snack('写真を入れられませんでした。もう一度ためしてください');
  }

  Future<void> _toggleReaction(String postId, String key, bool mine) async {
    final me = _me;
    if (me == null) return;
    try {
      await _col.doc(postId).update({
        FieldPath(['reactions', key]):
            mine ? FieldValue.arrayRemove([me]) : FieldValue.arrayUnion([me]),
      });
    } catch (e) {
      debugPrint('ひろばのリアクションのエラー: $e');
      _snack('スタンプを押せませんでした');
    }
  }

  void _pickReaction(String postId, Map<String, dynamic> reactions) {
    final me = _me;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('スタンプをえらぶ', style: TextStyle(fontWeight: FontWeight.bold, color: _brown)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: hirobaReactions.map((r) {
                final mine = ((reactions[r.$1] as List?) ?? const []).contains(me);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(sheet);
                    _toggleReaction(postId, r.$1, mine);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mine ? room.colors.first.withValues(alpha: 0.18) : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      Text(r.$2, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 2),
                      Text(r.$3, style: const TextStyle(fontSize: 11, color: _brown)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  void _postMenu(String postId, Map<String, dynamic> d) {
    final mine = d['uid'] == _me;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          if (mine)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('この投稿を消す'),
              onTap: () async {
                Navigator.pop(sheet);
                try {
                  await _col.doc(postId).delete();
                  _snack('消しました');
                } catch (_) {
                  _snack('消せませんでした', color: Colors.red);
                }
              },
            ),
          if (!mine) ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('通報する'),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(
                      userName: (d['name'] as String?) ?? 'このユーザー',
                      targetUid: (d['uid'] as String?) ?? '',
                      contentLabel: 'イベントの投稿',
                      contentRef: 'hiroba/${room.id}/hirobaPosts/$postId',
                      contentText: d['text'] as String?,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('この人をブロックする'),
              subtitle: const Text('この人の投稿が見えなくなり、あなたにスタンプも押せなくなります'),
              onTap: () {
                Navigator.pop(sheet);
                _confirmBlock((d['uid'] as String?) ?? '');
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('閉じる'),
            onTap: () => Navigator.pop(sheet),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmBlock(String uid) async {
    final me = _me;
    if (uid.isEmpty || me == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('ブロックしますか？'),
        content: const Text('この人の投稿は、イベントやほかの場所で見えなくなります。あとからマイページの「ブロックした人」で外せます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('やめる')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dc, true),
            child: const Text('ブロック'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('blocks')
          .doc(me)
          .collection('blocked')
          .doc(uid)
          .set({'createdAt': FieldValue.serverTimestamp()});
      _snack('ブロックしました', color: Colors.orange);
    } catch (_) {
      _snack('ブロックできませんでした', color: Colors.red);
    }
  }

  void _showStamps() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('スタンプだけ送る', style: TextStyle(fontWeight: FontWeight.bold, color: _brown)),
            const SizedBox(height: 4),
            Text('文を考えなくても大丈夫。押すとすぐ送られます',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: quickStamps
                  .map((s) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheet);
                          _send(s);
                        },
                        child: Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: room.colors.first.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 32)),
                        ),
                      ))
                  .toList(),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------- イベントで書きこむ以外にできること ----------

  bool _photoTab = true; // 写真大会：写真の一覧／おしゃべり
  late final OnlineEvent? _ev = eventOfRoom(room, DateTime.now());
  StreamSubscription<Map<String, dynamic>>? _evtSub;
  Map<String, dynamic> _evt = const {};
  List<String> _doneUsers = const [];
  List<String> _rsvpUsers = const [];
  Map<String, dynamic>? _myPet;

  String get _key => evtKey(room);
  bool get _isFes => room.id.startsWith('fes_');

  void _initExtras() {
    _evtSub = myEvtStream().listen((e) {
      if (mounted) setState(() => _evt = e);
    }, onError: (e) => debugPrint('イベントの記録の読みこみエラー: $e'));
    _loadCounts();
    _loadMyPet();
  }

  Future<void> _loadMyPet() async {
    final me = _me;
    if (me == null) return;
    try {
      final q = await FirebaseFirestore.instance.collection('users').doc(me).collection('pets').limit(1).get();
      if (q.docs.isNotEmpty && mounted) setState(() => _myPet = q.docs.first.data());
    } catch (e) {
      debugPrint('ペットの読みこみエラー: $e');
    }
  }

  Future<void> _loadCounts() async {
    if (room.id == 'challenge') {
      final u = await evtUsers('done', _key);
      if (mounted) setState(() => _doneUsers = u);
    } else if (room.id == 'talk') {
      final u = await evtUsers('rsvp', _key);
      if (mounted) setState(() => _rsvpUsers = u);
    }
  }

  Future<void> _doDone() async {
    final me = _me;
    if (me == null) return;
    setState(() => _doneUsers = [..._doneUsers.where((u) => u != me), me]);
    await evtSet(['done', _key], true);
    await evtJoin(room);
    if (!mounted) return;
    showHappyBurst(context, message: 'やりました！', sub: 'みんなの合計に入りました', emoji: '🎉', color: room.colors.last);
    _loadCounts();
  }

  Future<void> _toggleRsvp(bool now) async {
    final me = _me;
    if (me == null) return;
    setState(() => _rsvpUsers = now ? _rsvpUsers.where((u) => u != me).toList() : [..._rsvpUsers, me]);
    await evtSet(['rsvp', _key], !now);
    if (!now) await evtJoin(room);
    _loadCounts();
  }

  Widget _facesRow(List<String> uids) {
    if (uids.isEmpty) return const SizedBox.shrink();
    final show = uids.take(8).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        height: 34,
        child: Stack(children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: 24.0 * i,
              child: _Appear(
                id: 'face_${room.id}_x_${show[i]}',
                delayMs: 150 + i * 70,
                pop: true,
                child: FutureBuilder<_Author?>(
                  future: _author(show[i]),
                  builder: (context, s) {
                    final img = s.data == null || s.data!.pets.isEmpty ? null : _okImg(s.data!.pets.first['imageUrl']);
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: room.colors.first.withValues(alpha: .2),
                        border: Border.all(color: Colors.white, width: 2),
                        image: img == null ? null : DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                      ),
                      child: img == null ? const Center(child: Text('🐾', style: TextStyle(fontSize: 14))) : null,
                    );
                  },
                ),
              ),
            ),
        ]),
      ),
    );
  }

  List<Widget> _extras(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final ev = _ev;
    final c = room.colors.last;
    final out = <Widget>[];
    if (room.id == 'challenge' && ev != null) {
      out.add(ChallengeBoard(
        count: _doneUsers.length,
        goal: ev.goal ?? 100,
        done: evtMap(_evt, 'done')[_key] == true,
        onDone: _isOpen ? _doDone : null,
        color: c,
        faces: _facesRow(_doneUsers),
        howTo: 'やったら「やった！」を押すだけ。書きこみはなくても大丈夫',
      ));
    }
    if (room.id == 'talk' && ev != null) {
      final rsvped = evtMap(_evt, 'rsvp')[_key] == true;
      out.add(TalkBoard(
        start: ev.start,
        end: ev.end,
        theme: ev.theme,
        rsvpCount: _rsvpUsers.length,
        rsvped: rsvped,
        onRsvp: DateTime.now().isBefore(ev.end) ? () => _toggleRsvp(rsvped) : null,
        onTopic: (t) {
          _ctrl.text = t;
          _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
          if (_isOpen) _focus.requestFocus();
        },
        color: c,
        faces: _facesRow(_rsvpUsers),
      ));
    }
    if (_isFes && ev != null) {
      out.add(GoalBar(count: docs.length, goal: ev.goal ?? 100, color: c, label: 'みんなで${ev.goal ?? 100}こ集めよう'));
      out.add(OmikujiCard(
        drawnToday: _evt['omikuji'] == dayKey(DateTime.now()),
        onDrawn: () {
          evtSet(['omikuji'], dayKey(DateTime.now()));
          evtJoin(room);
        },
        onShare: (t) => _send(t),
        color: c,
      ));
      final rally = evtMap(_evt, 'rally')[_key];
      out.add(RallyCard(have: rally is List ? rally.whereType<String>().toSet() : <String>{}, color: c));
    }
    if (room.id == 'photo') {
      final top = _photoEntries(docs).where((p) => p.paws > 0).toList()..sort((a, b) => b.paws.compareTo(a.paws));
      if (top.isNotEmpty) out.add(PhotoPodium(top: top.take(3).toList(), color: c, onOpen: _openPhoto));
    }
    return out;
  }

  // 記念写真・バッジ
  Widget _toolRow() {
    Widget tool(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: Pressable(
            onTap: onTap,
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: room.colors.first.withValues(alpha: .4)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18, color: room.colors.last),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _brown, fontSize: 13)),
              ]),
            ),
          ),
        );
    return Row(children: [
      tool(Icons.photo_camera_back_rounded, '記念写真をつくる', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KeepsakeFramePage(
              room: room,
              petImageUrl: _okImg(_myPet?['imageUrl']),
              petName: _myPet?['name'] as String?,
            ),
          ),
        );
      }),
      const SizedBox(width: 8),
      tool(Icons.military_tech_rounded, '参加バッジ ${evtMap(_evt, 'badges').length}', () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFFFFFAF4),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🏅 参加バッジ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _brown)),
                const SizedBox(height: 4),
                Text('参加したイベントのバッジが集まります', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 14),
                BadgeShelf(badges: evtMap(_evt, 'badges')),
              ]),
            ),
          ),
        );
      }),
    ]);
  }

  List<PhotoEntry> _photoEntries(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final me = _me;
    final out = <PhotoEntry>[];
    for (final d in docs) {
      final m = d.data();
      final url = _okImg(m['imageUrl']);
      if (url == null) continue;
      final paws = ((m['reactions'] as Map<String, dynamic>?)?['paw'] as List?) ?? const [];
      out.add(PhotoEntry(
        id: d.id,
        url: url,
        uid: (m['uid'] as String?) ?? '',
        name: m['name'] == hiddenName ? hiddenName : ((m['name'] as String?) ?? ''),
        paws: paws.length,
        voted: paws.contains(me),
      ));
    }
    return out;
  }

  void _openPhoto(PhotoEntry p) {
    showDialog(
      context: context,
      builder: (dc) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 4 / 5, child: Image.network(p.url, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Expanded(
                child: Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: p.voted ? Colors.grey : room.colors.last),
                onPressed: () {
                  Navigator.pop(dc);
                  _toggleReaction(p.id, 'paw', p.voted);
                },
                icon: const Text('🐾'),
                label: Text(p.voted ? '応援をやめる' : '応援する（${p.paws}）'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------- 書いた人（ペットの写真・飼い主のプロフィール） ----------

  static final Map<String, Future<_Author?>> _authors = {};

  Future<_Author?> _author(String uid) => _authors.putIfAbsent(uid, () async {
        try {
          final db = FirebaseFirestore.instance;
          final u = await db.collection('users').doc(uid).get();
          final p = await db.collection('users').doc(uid).collection('pets').limit(4).get();
          final d = u.data() ?? const <String, dynamic>{};
          return _Author(
            name: ((d['name'] as String?) ?? '').trim(),
            icon: _okImg(d['profileImageUrl']),
            motto: ((d['motto'] as String?) ?? '').trim(),
            pets: p.docs.map((e) => e.data()).toList(),
          );
        } catch (e) {
          debugPrint('書いた人を読みこめませんでした: $e');
          return null;
        }
      });

  void _showAuthor(String uid, _Author a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFAF4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: room.colors.first.withValues(alpha: .2),
                backgroundImage: a.icon == null ? null : NetworkImage(a.icon!),
                child: a.icon == null ? const Icon(Icons.person, color: _brown) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name.isEmpty ? '名無しさん' : a.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _brown)),
                  if (a.motto.isNotEmpty)
                    Text(a.motto, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('いっしょに暮らしている子', style: TextStyle(fontWeight: FontWeight.w800, color: _brown)),
            const SizedBox(height: 10),
            if (a.pets.isEmpty)
              Text('まだ登録されていません', style: TextStyle(color: Colors.grey[600]))
            else
              SizedBox(
                height: 112,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final p in a.pets)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 84,
                        child: Column(children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: room.colors.first.withValues(alpha: .15),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
                              image: _okImg(p['imageUrl']) == null
                                  ? null
                                  : DecorationImage(image: NetworkImage(_okImg(p['imageUrl'])!), fit: BoxFit.cover),
                            ),
                            child: _okImg(p['imageUrl']) == null
                                ? const Center(child: Text('🐾', style: TextStyle(fontSize: 28)))
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text((p['name'] as String?) ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _brown)),
                          Text((p['type'] as String?) ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ]),
                      ),
                    ),
                ]),
              ),
            const SizedBox(height: 6),
            Text('イベントの中では、プロフィールを見ることだけができます', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ),
    );
  }

  // ---------- 画面 ----------

  late Stream<QuerySnapshot<Map<String, dynamic>>> _streamObj = _makeStream();
  Timer? _slowTimer;
  bool _slow = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _makeStream() {
    _slowTimer?.cancel();
    _slow = false;
    _slowTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _slow = true);
    });
    return room.span == null
        ? _col.orderBy('createdAt', descending: true).limit(80).snapshots()
        : _col.where('span', isEqualTo: room.span).limit(300).snapshots();
  }

  String get _status {
    final now = DateTime.now();
    final o = room.opensAt, c = room.closesAt;
    if (o != null && now.isBefore(o)) return '${whenText(o)}から';
    if (c != null && !now.isBefore(c)) return '終わりました（読むことはできます）';
    if (c != null) {
      final left = c.difference(now);
      return left.inHours >= 1 ? '開催中・あと${left.inHours}時間' : '開催中・あと${left.inMinutes + 1}分';
    }
    return '開催中';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: FestiveBackdrop(colors: room.colors, style: room.style, seed: room.id.hashCode),
        title: Text('${room.emoji} ${room.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _streamObj,
            builder: (context, snap) {
              // 読みこみ中・読みこめないときも、イベントのカードはすぐ出す
              if (snap.hasError) {
                return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), children: [
                  _hero(0, const []),
                  _toolRow(),
                  ..._extras(const []),
                  const SizedBox(height: 14),
                  _retry('みんなの投稿を読みこめませんでした。電波のよいところで、もう一度ためしてください'),
                ]);
              }
              if (!snap.hasData) {
                return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), children: [
                  _hero(0, const []),
                  _toolRow(),
                  ..._extras(const []),
                  const SizedBox(height: 14),
                  Center(
                    child: _slow
                        ? _retry('読みこみに時間がかかっています')
                        : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ),
                ]);
              }
              _slowTimer?.cancel();
              return ValueListenableBuilder<Set<String>>(
                valueListenable: BlockedUsers.instance.ids,
                builder: (context, blocked, _) {
                  final docs = snap.data!.docs.where((d) => !blocked.contains(d.data()['uid'])).toList();
                  int ms(QueryDocumentSnapshot<Map<String, dynamic>> d) {
                    final t = d.data()['createdAt'];
                    return t is Timestamp ? t.millisecondsSinceEpoch : 8640000000000000;
                  }

                  docs.sort((a, b) => ms(b).compareTo(ms(a)));
                  if (_popular) {
                    int score(QueryDocumentSnapshot<Map<String, dynamic>> d) {
                      final r = (d.data()['reactions'] as Map<String, dynamic>?) ?? const {};
                      return r.values.fold<int>(0, (n, v) => n + ((v as List?)?.length ?? 0));
                    }

                    docs.sort((a, b) => score(b).compareTo(score(a)));
                  }
                  final uids = <String>[];
                  for (final d in docs) {
                    final u = d.data()['uid'];
                    if (u is String && !uids.contains(u) && d.data()['name'] != hiddenName) uids.add(u);
                  }
                  final people = docs.map((d) => d.data()['uid']).toSet().length;
                  final extras = _extras(docs);
                  if (docs.isEmpty && extras.isEmpty) {
                    // まだだれもいないときは、イベントのカードを画面のまん中に
                    return _center(Column(mainAxisSize: MainAxisSize.min, children: [
                      _hero(0, const []),
                      _toolRow(),
                      const SizedBox(height: 14),
                      Text('まだだれも参加していません。いちばん乗りをどうぞ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ]));
                  }
                  final photos = room.id == 'photo' ? _photoEntries(docs) : const <PhotoEntry>[];
                  final gallery = room.id == 'photo' && _photoTab;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    itemCount: gallery ? 1 : docs.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Column(children: [
                          _hero(people, uids),
                          _toolRow(),
                          ...extras,
                          if (room.id == 'photo')
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: true, label: Text('写真の一覧'), icon: Icon(Icons.grid_view_rounded)),
                                  ButtonSegment(value: false, label: Text('おしゃべり'), icon: Icon(Icons.forum_rounded)),
                                ],
                                selected: {_photoTab},
                                onSelectionChanged: (v) => setState(() => _photoTab = v.first),
                              ),
                            ),
                          if (gallery)
                            PhotoGrid(
                              photos: photos,
                              color: room.colors.last,
                              onOpen: _openPhoto,
                              onVote: (p) => _toggleReaction(p.id, 'paw', p.voted),
                            ),
                          if (!gallery && docs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text('まだだれも書いていません。いちばん乗りをどうぞ',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ),
                          const SizedBox(height: 6),
                        ]);
                      }
                      final d = docs[i - 1];
                      return _Appear(
                        id: 'post_${d.id}',
                        delayMs: i <= 6 ? 120 + i * 70 : 0,
                        child: _post(d.id, d.data(), rank: _popular && i <= 3 ? i : null),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        if (_isOpen) _composer() else _closedBar(),
      ]),
    );
  }

  Widget _center(Widget child) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 32),
            child: Center(child: child),
          ),
        ),
      );

  Widget _retry(String text) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _brown)),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() => _streamObj = _makeStream()),
          child: const Text('もう一度読みこむ'),
        ),
      ]);

  // イベントのカード（いちばん大きく見せる）
  Widget _hero(int people, List<String> uids) => _Appear(id: 'hero_${room.id}', child: _heroCard(people, uids));

  Widget _heroCard(int people, List<String> uids) {
    final c1 = room.colors.first, c2 = room.colors.last;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(children: [
        Positioned.fill(child: FestiveBackdrop(colors: room.colors, style: room.style, seed: room.id.hashCode + 7)),
        if (_isOpen) Positioned.fill(child: _Confetti(colors: room.colors)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c1.withValues(alpha: .25), c2.withValues(alpha: .55)],
            ),
          ),
          child: Column(children: [
            _Bob(child: Text(room.emoji, style: const TextStyle(fontSize: 56))),
            const SizedBox(height: 4),
            Text(room.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0x55000000), blurRadius: 6)],
                )),
            const SizedBox(height: 8),
            (_isOpen ? (Widget c) => _Pulse(child: c) : (Widget c) => c)(Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isOpen ? const Color(0xFFE84A5F) : Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            )),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(children: [
                Text(room.span == null ? 'この部屋のテーマ' : '今回のお題',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c2)),
                const SizedBox(height: 4),
                Text(room.prompt ?? room.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _brown, height: 1.35)),
                const SizedBox(height: 14),
                _faces(people, uids),
                const SizedBox(height: 14),
                if (_isOpen) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c2,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: room.allowPhoto ? (_uploading ? null : _pickImage) : () => _focus.requestFocus(),
                      icon: Icon(room.allowPhoto ? Icons.photo_camera_rounded : Icons.edit_rounded),
                      label: Text(room.allowPhoto ? '写真で参加する' : 'ひとことで参加する',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c2,
                        side: BorderSide(color: c2, width: 2),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                      ),
                      onPressed: _sending ? null : _showStamps,
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      label: const Text('スタンプ1つで参加する', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]
                else
                  Text(_closedText, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // 参加している子の写真をならべる
  Widget _faces(int people, List<String> uids) {
    if (people == 0) {
      return Text('見るだけでも大丈夫です', style: TextStyle(fontSize: 13, color: Colors.grey[600]));
    }
    final show = uids.take(6).toList();
    return Column(children: [
      SizedBox(
        height: 40,
        width: 28.0 * show.length + 14,
        child: Stack(children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: 28.0 * i,
              child: _Appear(
                id: 'face_${room.id}_${show[i]}',
                delayMs: 250 + i * 90,
                pop: true,
                child: FutureBuilder<_Author?>(
                future: _author(show[i]),
                builder: (context, s) {
                  final img = s.data == null || s.data!.pets.isEmpty ? null : _okImg(s.data!.pets.first['imageUrl']);
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: room.colors.first.withValues(alpha: .2),
                      border: Border.all(color: Colors.white, width: 2.5),
                      image: img == null ? null : DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                    ),
                    child: img == null ? const Center(child: Text('🐾', style: TextStyle(fontSize: 16))) : null,
                  );
                },
              ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Text('$people人が参加しています',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _brown)),
    ]);
  }

  String _time(dynamic ts) {
    if (ts is! Timestamp) return 'いま';
    final t = ts.toDate();
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'いま';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    return '${t.month}/${t.day}';
  }

  String? _pawBurst; // 2回タップで🐾を押したとき、少しだけ大きく出す

  Widget _post(String id, Map<String, dynamic> d, {int? rank}) {
    final me = _me;
    final uid = (d['uid'] as String?) ?? '';
    final mine = uid == me;
    final hidden = d['name'] == hiddenName;
    final text = (d['text'] as String?) ?? '';
    final img = _okImg(d['imageUrl']);
    final onlyStamp = img == null && text.runes.length <= 2 && quickStamps.contains(text);
    final reactions = (d['reactions'] as Map<String, dynamic>?) ?? const {};
    final pawed = ((reactions['paw'] as List?) ?? const []).contains(me);
    final chips = <Widget>[];
    for (final r in hirobaReactions) {
      final list = (reactions[r.$1] as List?) ?? const [];
      if (list.isEmpty && r.$1 != 'paw') continue;
      final on = list.contains(me);
      chips.add(_ReactionChip(
        label: list.isEmpty ? '${r.$2} ${r.$3}' : '${r.$2} ${list.length}',
        on: on,
        color: room.colors.first,
        onTap: () => _toggleReaction(id, r.$1, on),
      ));
    }
    chips.add(_ReactionChip(label: '＋', on: false, color: room.colors.first, onTap: () => _pickReaction(id, reactions)));

    final header = FutureBuilder<_Author?>(
      future: hidden || uid.isEmpty ? Future.value(null) : _author(uid),
      builder: (context, s) {
        final a = s.data;
        final pet = a == null || a.pets.isEmpty ? null : a.pets.first;
        final petImg = pet == null ? null : _okImg(pet['imageUrl']);
        final owner = hidden ? hiddenName : (mine ? 'あなた' : ((d['name'] as String?) ?? a?.name ?? '名無しさん'));
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: a == null || hidden ? null : () => _showAuthor(uid, a),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: room.colors.first.withValues(alpha: .18),
                  border: Border.all(color: mine ? room.colors.last : Colors.white, width: 2.5),
                  image: petImg == null ? null : DecorationImage(image: NetworkImage(petImg), fit: BoxFit.cover),
                ),
                child: petImg == null ? const Center(child: Text('🐾', style: TextStyle(fontSize: 18))) : null,
              ),
              if (a?.icon != null && !hidden)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(radius: 8.5, backgroundImage: NetworkImage(a!.icon!)),
                  ),
                ),
            ]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pet == null || hidden ? owner : (pet['name'] as String?) ?? owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _brown)),
                if (pet != null && !hidden)
                  Text('${(pet['type'] as String?) ?? ''}・飼い主 $owner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ]),
            ),
            if (rank != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFC83D), borderRadius: BorderRadius.circular(10)),
                child: Text('$rank位', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _brown)),
              ),
            Text(_time(d['createdAt']), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onLongPress: () => _postMenu(id, d),
        onDoubleTap: () {
          if (!pawed) _toggleReaction(id, 'paw', false);
          setState(() => _pawBurst = id);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted && _pawBurst == id) setState(() => _pawBurst = null);
          });
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mine ? room.colors.first.withValues(alpha: .6) : Colors.transparent, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            header,
            const SizedBox(height: 10),
            Stack(alignment: Alignment.center, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (img != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Image.network(img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(height: 80, child: Center(child: Text('写真を読みこめませんでした')))),
                    ),
                  ),
                if (img != null && text.isNotEmpty) const SizedBox(height: 8),
                if (onlyStamp)
                  Center(child: Text(text, style: const TextStyle(fontSize: 56)))
                else if (text.isNotEmpty)
                  Text(text, style: const TextStyle(fontSize: 15, color: _brown, height: 1.5)),
              ]),
              if (_pawBurst == id) const _PawBurst(),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: chips),
          ]),
        ),
      ),
    );
  }

  Widget _closedBar() {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.schedule, color: _brown),
            const SizedBox(width: 10),
            Expanded(child: Text(_closedText, style: const TextStyle(color: _brown))),
          ]),
        ),
      ),
    );
  }

  Widget _composer() {
    final starters = [...room.starters, ...commonStarters];
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: starters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: room.colors.first.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  label: Text(starters[i], style: const TextStyle(fontSize: 12, color: _brown)),
                  onPressed: () {
                    _ctrl.text = starters[i];
                    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
                    _focus.requestFocus();
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageUrl!, width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('この写真を送ります（ひとことは、なくてもOK）', style: TextStyle(fontSize: 12))),
                  IconButton(
                    tooltip: '写真をやめる',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _imageUrl = null),
                  ),
                ]),
              ),
            Row(children: [
              if (room.allowPhoto)
                IconButton(
                  tooltip: '写真をえらぶ',
                  icon: _uploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.add_photo_alternate_outlined, color: room.colors.last),
                  onPressed: _sending || _uploading ? null : _pickImage,
                ),
              IconButton(
                tooltip: 'スタンプだけ送る',
                icon: Icon(Icons.emoji_emotions_outlined, color: room.colors.last),
                onPressed: _sending ? null : _showStamps,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLength: 140,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    hintText: room.allowPhoto ? 'ひとこと（写真だけでもOK）' : 'ひとことどうぞ（140文字まで）',
                    filled: true,
                    fillColor: const Color(0xFFF5F0EB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                tooltip: '送る',
                icon: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.send_rounded, color: room.colors.last),
                onPressed: _sending ? null : () => _send(_ctrl.text),
              ),
            ]),
            InkWell(
              onTap: () => setState(() => _hideName = !_hideName),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _hideName,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => _hideName = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    // コード点検 11/16：アプリを改造すれば、だれが書いたかは分かってしまう。正直に書く
                    _hideName
                        ? '画面では「$hiddenName」と出ます（運営には分かります）'
                        : '名前を出さずに書く',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String label;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  const _ReactionChip({required this.label, required this.on, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? color : Colors.grey.shade300),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: _brown)),
      ),
    );
  }
}

class _Author {
  final String name;
  final String? icon;
  final String motto;
  final List<Map<String, dynamic>> pets;
  const _Author({required this.name, required this.icon, required this.motto, required this.pets});
}

String? _okImg(dynamic u) => u is String && u.startsWith('https://') && u.length <= 600 ? u : null;

// ---------- イベントの部屋の動き（11/25 社長「イベントにもっとアニメーションを」） ----------
// 「動きを少なくする」設定の人には動かさない

// ゆっくり上下にゆれる（イベントの絵）
class _Bob extends StatefulWidget {
  const _Bob({required this.child});
  final Widget child;
  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: Transform.rotate(angle: (t - .5) * .12, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ふわっと大きくなったり小さくなったり（開催中の札）
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

// 下からふわっと出てくる（カード・投稿・参加している子）。同じものは1回だけ
class _Appear extends StatefulWidget {
  const _Appear({required this.id, required this.child, this.delayMs = 0, this.pop = false});
  final String id;
  final Widget child;
  final int delayMs;
  final bool pop; // ぽんっと出る（顔の丸）
  static final Set<String> shown = {};
  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.pop ? 420 : 520));
  bool _skip = false;

  @override
  void initState() {
    super.initState();
    _skip = _Appear.shown.contains(widget.id);
    _Appear.shown.add(widget.id);
    if (_skip) {
      _c.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_skip || reduceMotion(context)) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: widget.pop ? Curves.elasticOut : Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: widget.pop
            ? Transform.scale(scale: .3 + .7 * a.value, child: child)
            : Transform.translate(offset: Offset(0, 24 * (1 - a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

// イベントのカードの上に、紙ふぶきがゆっくり落ちる（開催中のときだけ）
class _Confetti extends StatefulWidget {
  const _Confetti({required this.colors});
  final List<Color> colors;
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value, widget.colors)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.colors);
  final double t;
  final List<Color> colors;
  static const _n = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [...colors, const Color(0xFFFFD84D), const Color(0xFFFF8FB1), Colors.white];
    for (var i = 0; i < _n; i++) {
      final seed = (i * 7919) % 1000 / 1000;
      final speed = .6 + seed * .8;
      final y = ((t * speed + i / _n) % 1.0) * (size.height + 40) - 20;
      final x = (seed * size.width + 18 * math.sin((t * 2 * math.pi * speed) + i)) % size.width;
      final paint = Paint()..color = palette[i % palette.length].withValues(alpha: .85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 2 * math.pi * (i.isEven ? 1 : -1) * speed);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 3.2, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(1.5)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// 2回タップで押した🐾が、ぽんっと大きくなって消える
class _PawBurst extends StatelessWidget {
  const _PawBurst();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        builder: (_, v, child) => Opacity(
          opacity: v < .6 ? 1 : (1 - (v - .6) / .4).clamp(0.0, 1.0),
          child: Transform.scale(scale: .4 + Curves.elasticOut.transform(math.min(v * 1.4, 1)) * .9, child: child),
        ),
        child: const Text('🐾', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}
