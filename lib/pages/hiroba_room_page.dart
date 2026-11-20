// イベントの部屋（アプリの中のイベント・どうぶつ別の部屋）：ひとこと・写真・スタンプで参加する場所
// ・入っても、だれにも知らされない（見るだけでもよい）
// ・名前を押してもプロフィールは開かない（ここから 1対1 のメッセージは送れない）
// ・長押しで「通報」「この人をブロック」。自分の投稿は「消す」
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/blocked_users.dart';
import '../services/cloudinary_service.dart';
import '../services/content_filter.dart';
import '../widgets/festive_backdrop.dart';
import '../widgets/motion.dart';
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
    _loadName();
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

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream => room.span == null
      ? _col.orderBy('createdAt', descending: true).limit(80).snapshots()
      : _col.where('span', isEqualTo: room.span).limit(300).snapshots();

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
        _promptBanner(),
        if (room.showPopular)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('新しい順')),
                ButtonSegment(value: true, label: Text('スタンプの多い順')),
              ],
              selected: {_popular},
              onSelectionChanged: (v) => setState(() => _popular = v.first),
            ),
          ),
        Expanded(child: _postList()),
        if (_isOpen) _composer() else _closedBar(),
      ]),
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

  Widget _promptBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: room.colors.first.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(room.prompt ?? room.desc,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _brown)),
        const SizedBox(height: 3),
        Text(
          room.allowPhoto
              ? '見るだけでも大丈夫。🐾 スタンプ1つ、写真1枚からどうぞ'
              : '見るだけでも大丈夫。🐾 スタンプ1つからどうぞ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ]),
    );
  }

  Widget _postList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('読みこめませんでした。少ししてから開き直してください'));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ValueListenableBuilder<Set<String>>(
          valueListenable: BlockedUsers.instance.ids,
          builder: (context, blocked, _) {
            final docs = snap.data!.docs.where((d) => !blocked.contains(d.data()['uid'])).toList();
            if (room.span != null) {
              // お題・お祭りの部屋は、新しい順に並べかえる（送ったばかりのものは、いちばん新しい）
              int ms(QueryDocumentSnapshot<Map<String, dynamic>> d) {
                final t = d.data()['createdAt'];
                return t is Timestamp ? t.millisecondsSinceEpoch : 8640000000000000;
              }

              docs.sort((a, b) => ms(b).compareTo(ms(a)));
            }
            if (_popular) {
              int score(QueryDocumentSnapshot<Map<String, dynamic>> d) {
                final r = (d.data()['reactions'] as Map<String, dynamic>?) ?? const {};
                return r.values.fold<int>(0, (n, v) => n + ((v as List?)?.length ?? 0));
              }

              docs.sort((a, b) => score(b).compareTo(score(a)));
            }
            if (docs.isEmpty) return _empty();
            return ListView.builder(
              reverse: !_popular,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: docs.length,
              itemBuilder: (_, i) => _post(docs[i].id, docs[i].data()),
            );
          },
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(room.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          const Text('まだだれも書いていません',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brown)),
          const SizedBox(height: 6),
          Text('いちばん乗りのひとことをどうぞ。\nスタンプだけでも大丈夫です',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], height: 1.5)),
        ]),
      ),
    );
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

  Widget _post(String id, Map<String, dynamic> d) {
    final me = _me;
    final mine = d['uid'] == me;
    final text = (d['text'] as String?) ?? '';
    final img = d['imageUrl'] as String?;
    final onlyStamp = img == null && text.runes.length <= 2 && quickStamps.contains(text);
    final reactions = (d['reactions'] as Map<String, dynamic>?) ?? const {};
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
    chips.add(_ReactionChip(
      label: '＋',
      on: false,
      color: room.colors.first,
      onTap: () => _pickReaction(id, reactions),
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${mine ? 'あなた' : (d['name'] ?? '名無しさん')}　${_time(d['createdAt'])}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onLongPress: () => _postMenu(id, d),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: onlyStamp
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: onlyStamp
                  ? null
                  : BoxDecoration(
                      color: mine ? room.colors.first.withValues(alpha: 0.16) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (img != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(img,
                          height: 240,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              height: 80, child: Center(child: Text('写真を読みこめませんでした')))),
                    ),
                  if (img != null && text.isNotEmpty) const SizedBox(height: 6),
                  if (text.isNotEmpty)
                    Text(text,
                        style: TextStyle(fontSize: onlyStamp ? 40 : 15, color: _brown, height: 1.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: chips),
        ],
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
