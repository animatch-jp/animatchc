import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'notification_prefs.dart';
import 'report_page.dart';
import '../services/cloudinary_service.dart';
import '../services/blocked_users.dart';
import '../widgets/animaru.dart';

// グループチャットの1メッセージの文字数の上限
const int _messageMaxLength = 1000;

const _orange = Color(0xFFE8845A);
const _brown = Color(0xFF3D2B1F);

// スタンプ（押すとそのまま送れる、動物のひとこと）
const _stamps = [
  ('🐶', 'よろしく！'),
  ('🐱', 'ありがとう'),
  ('🐰', '楽しみ！'),
  ('🐹', '了解です'),
  ('🦜', 'おつかれさま'),
  ('🐾', '行きます！'),
  ('🐢', '少し遅れます'),
  ('📍', '着きました'),
  ('😍', 'かわいい！'),
  ('📸', '写真ありがとう'),
  ('👋', 'またね'),
  ('🌙', 'おやすみ'),
];

// メッセージへのリアクション（キーは Firestore に入れる名前）
const _reactions = [
  ('paw', '🐾'),
  ('love', '😍'),
  ('laugh', '😂'),
  ('good', '👍'),
  ('thanks', '🙏'),
];

class EventChatPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventChatPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _myName;
  String? _myImageUrl;
  String? _organizerUid;
  bool _showStamps = false;
  bool _uploading = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _seenSub;

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('messages');

  @override
  void initState() {
    super.initState();
    // 新しい順に読み、リストを逆向きに表示する。
    // こうすると、開いたときに一番新しいメッセージが下に来る。
    _messageStream =
        _messagesRef.orderBy('createdAt', descending: true).snapshots();
    _loadMyInfo();
    _watchLatestMessage();
    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get()
        .then((d) {
      if (mounted) setState(() => _organizerUid = d.data()?['organizerUid'] as String?);
    }).catchError((_) {});
  }

  // 一番新しいメッセージが変わるたびに「ここまで読んだ」を更新する。
  // 開いている間に届いた分も既読になる。
  void _watchLatestMessage() {
    _seenSub = _messagesRef
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((_) {
      _updateLastSeen();
      _markNotificationRead();
    }, onError: (_) {});
  }

  Future<void> _updateLastSeen() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('groupChatLastSeen')
          .doc(widget.eventId)
          .set({'lastSeen': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  // このイベントのグループチャット通知(ベルの未読)を既読にする
  Future<void> _markNotificationRead() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(myUid)
          .collection('items')
          .doc('groupChat_${widget.eventId}')
          .update({'read': true});
    } catch (_) {
      // 通知がまだ無いときは、何もしなくてよい
    }
  }

  @override
  void dispose() {
    _seenSub?.cancel();
    _updateLastSeen();
    _markNotificationRead();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyInfo() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    if (mounted) {
      setState(() {
        _myName = doc.data()?['name'] ?? '';
        _myImageUrl = doc.data()?['profileImageUrl'] ?? '';
      });
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.isEmpty || text.length > _messageMaxLength) return;
    _msgCtrl.clear();
    await _send({'text': text});
  }

  void _sendStamp(String emoji, String label) async {
    setState(() => _showStamps = false);
    await _send({'type': 'stamp', 'emoji': emoji, 'text': '$emoji $label'});
  }

  Future<void> _sendPhoto() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    if (!mounted) return;
    setState(() => _uploading = false);
    if (url == null) return;
    await _send({'type': 'image', 'imageUrl': url, 'text': '📷 写真'});
  }

  Future<void> _send(Map<String, dynamic> body) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      await _messagesRef.add({
        ...body,
        'senderUid': myUid,
        'senderName': _myName ?? '',
        'senderImageUrl': _myImageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('送れませんでした。電波を確かめて、もう一度送ってください')));
      }
      return;
    }

    final participants = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('participants')
        .get();

    final eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    final organizerUid = eventDoc.data()?['organizerUid'] as String?;

    final notifyUids = <String>{};
    for (final p in participants.docs) {
      notifyUids.add(p.id);
    }
    if (organizerUid != null) notifyUids.add(organizerUid);
    notifyUids.remove(myUid);

    // 通知は「1イベントにつき1件」にまとめる。
    // メッセージのたびに増やすと、ベルのバッジが数えきれなくなるため、
    // 同じ通知を上書きして、未読に戻す。
    // グループチャットのメッセージは「コメント・メッセージ」の設定に従う。
    for (final uid in notifyUids) {
      if (!await shouldSendNotification(uid, 'コメント・メッセージ')) continue;
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc('groupChat_${widget.eventId}')
          .set({
        'type': 'groupChat',
        'emoji': '👥',
        'title': 'グループチャットにメッセージが届きました！',
        'desc': '${_myName ?? ''} さんがメッセージを送りました',
        'fromUid': myUid,
        'eventId': widget.eventId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 送ったら、一番下（逆向きのリストでは、位置0）に戻る
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // リアクションをつける・外す（もう一度押すと外れる）
  Future<void> _toggleReaction(String messageId, String key, bool mine) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await _messagesRef.doc(messageId).update({
        FieldPath(['reactions', key]):
            mine ? FieldValue.arrayRemove([myUid]) : FieldValue.arrayUnion([myUid]),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リアクションをつけられませんでした')));
      }
    }
  }

  // 主催者だけ：大事なメッセージを、上にピン留めする
  Future<void> _pin(String text, String senderName) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update({
        'pinned': {'text': text, 'senderName': senderName, 'at': FieldValue.serverTimestamp()},
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ピン留めできませんでした')));
      }
    }
  }

  void _showMessageMenu(
    BuildContext context, {
    required String messageId,
    required String senderUid,
    required String senderName,
    required String text,
    required Map<String, dynamic> reactions,
  }) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = senderUid == myUid;
    final isOrganizer = myUid != null && myUid == _organizerUid;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _reactions.map((r) {
                  final list = (reactions[r.$1] as List?) ?? const [];
                  final mine = list.contains(myUid);
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _toggleReaction(messageId, r.$1, mine);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFFFE9DF) : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: mine ? _orange : Colors.transparent),
                      ),
                      child: Text(r.$2, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (isOrganizer)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined, color: _orange),
                title: const Text('上にピン留めする（主催者だけ）'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pin(text, senderName);
                },
              ),
            if (!isMe)
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: Colors.red),
          title: const Text('このメッセージを通報'),
          onTap: () {
            Navigator.pop(sheetContext);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportPage(
                  userName: senderName.isNotEmpty ? senderName : 'このユーザー',
                  targetUid: senderUid,
                  contentLabel: 'イベントのグループチャット',
                  contentRef: 'events/${widget.eventId}/messages/$messageId',
                  contentText: text,
                ),
              ),
            );
          },
        ),
          ],
        ),
      ),
    );
  }

  // スタンプ：吹き出しなしで、大きく、ぽんっと出る
  Widget _stampView(Map<String, dynamic> data) {
    final text = data['text'] as String? ?? '';
    final emoji = data['emoji'] as String? ?? '🐾';
    final label = text.startsWith(emoji) ? text.substring(emoji.length).trim() : text;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF6D5C6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: _brown)),
          ],
        ),
      ),
    );
  }

  // 写真：押すと大きく見られる
  Widget _imageView(String url) {
    final w = MediaQuery.of(context).size.width * 0.6;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: w,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(
                  width: w,
                  height: w * 0.75,
                  color: const Color(0xFFFFEFE6),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: _orange, strokeWidth: 2)),
          errorBuilder: (_, __, ___) => Container(
              width: w,
              height: 80,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Text('写真を読みこめませんでした', style: TextStyle(fontSize: 12))),
        ),
      ),
    );
  }

  // 吹き出しの下に出る、リアクションの数（押すと自分の分をつける・外す）
  Widget _reactionChips(String messageId, Map<String, dynamic> reactions, bool isMe) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final chips = <Widget>[];
    for (final r in _reactions) {
      final list = (reactions[r.$1] as List?) ?? const [];
      if (list.isEmpty) continue;
      final mine = list.contains(myUid);
      chips.add(GestureDetector(
        onTap: () => _toggleReaction(messageId, r.$1, mine),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFFFE9DF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mine ? _orange : const Color(0xFFEDE3DD)),
          ),
          child: Text('${r.$2} ${list.length}',
              style: const TextStyle(fontSize: 12, color: _brown)),
        ),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 4, runSpacing: 4, children: chips),
    );
  }

  Widget _stampPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.15,
        children: _stamps.map((st) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _sendStamp(st.$1, st.$2),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(st.$1, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 2),
                  Text(st.$2,
                      style: const TextStyle(fontSize: 10, color: _brown),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final time = (timestamp as dynamic).toDate() as DateTime;
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF3D2B1F)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.eventTitle,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const Text('グループチャット',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: Column(
        children: [
          _EventInfoBar(eventId: widget.eventId),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFE8845A)));
                }
                final messages = snapshot.data!.docs
                    .where((m) => !BlockedUsers.instance.isBlocked(m.data()['senderUid']))
                    .toList();
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Animaru(size: 100, wave: true, showName: true),
                        SizedBox(height: 16),
                        Text('まだメッセージがありません',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        SizedBox(height: 8),
                        Text('最初のメッセージを送ってみよう！',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final data = messages[i].data();
                    final isMe = data['senderUid'] == myUid;
                    final isSystem = data['isSystem'] == true;
                    final timeStr = _timeAgo(data['createdAt']);
                    final messageId = messages[i].id;

                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              data['text'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      );
                    }

                    final type = data['type'] as String? ?? 'text';
                    final reactions =
                        (data['reactions'] as Map<String, dynamic>?) ?? const {};
                    return Padding(
                      key: ValueKey(messageId),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            GestureDetector(
                              onTap: () {
                                if (data['senderUid'] != 'system' &&
                                    data['senderUid'] != myUid) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                          uid: data['senderUid']),
                                    ),
                                  );
                                }
                              },
                              child: ClipOval(
                                child: data['senderImageUrl'] != null &&
                                    (data['senderImageUrl'] as String)
                                        .isNotEmpty
                                    ? Image.network(data['senderImageUrl'],
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover)
                                    : Container(
                                    width: 32,
                                    height: 32,
                                    color: const Color(0xFFFFE0D0),
                                    child: Center(
                                      child: Text(
                                        (data['senderName'] ?? '🐾')
                                            .toString()
                                            .isNotEmpty
                                            ? data['senderName'][0]
                                            : '🐾',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFE8845A),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                      data['senderName'] as String? ?? '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                                ),
                              GestureDetector(
                                // 長押し：リアクション・ピン留め（主催者）・通報（ほかの人のメッセージ）
                                onLongPress: () => _showMessageMenu(
                                          context,
                                          messageId: messageId,
                                          senderUid:
                                              data['senderUid'] as String? ?? '',
                                          senderName:
                                              data['senderName'] as String? ?? '',
                                          text: data['text'] as String? ?? '',
                                          reactions: reactions,
                                        ),
                                child: type == 'stamp'
                                    ? _stampView(data)
                                    : type == 'image' && (data['imageUrl'] as String? ?? '').isNotEmpty
                                        ? _imageView(data['imageUrl'] as String)
                                        : Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(context).size.width *
                                        0.65),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFFE8845A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft:
                                    Radius.circular(isMe ? 18 : 4),
                                    bottomRight:
                                    Radius.circular(isMe ? 4 : 18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                        Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Text(data['text'] as String? ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: isMe
                                            ? Colors.white
                                            : const Color(0xFF3D2B1F),
                                        height: 1.4)),
                              ),
                              ),
                              _reactionChips(messageId, reactions, isMe),
                              const SizedBox(height: 4),
                              Text(timeStr,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _showStamps ? _stampPanel() : const SizedBox(width: double.infinity),
                ),
                Row(
              children: [
                IconButton(
                  tooltip: 'スタンプ',
                  onPressed: () => setState(() => _showStamps = !_showStamps),
                  icon: AnimatedRotation(
                    turns: _showStamps ? 0.1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.pets_rounded,
                        color: _showStamps ? _orange : Colors.grey[500]),
                  ),
                ),
                IconButton(
                  tooltip: '写真を送る',
                  onPressed: _uploading ? null : _sendPhoto,
                  icon: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _orange))
                      : Icon(Icons.photo_camera_outlined, color: Colors.grey[500]),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLength: _messageMaxLength,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_msgCtrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFE8845A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// チャットの上に出す、イベントの情報（日にち・場所・参加人数）と、話し方のお願い
class _EventInfoBar extends StatelessWidget {
  final String eventId;
  const _EventInfoBar({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(eventId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: eventRef.snapshots(),
      builder: (context, snap) {
        final e = snap.data?.data() ?? const <String, dynamic>{};
        final date = e['date'] as String? ?? '';
        final location = e['location'] as String? ?? '';
        final pinned = e['pinned'] as Map<String, dynamic>?;
        final isOrganizer = FirebaseAuth.instance.currentUser?.uid != null &&
            FirebaseAuth.instance.currentUser?.uid == e['organizerUid'];
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3E1D7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (date.isNotEmpty) _info(Icons.event_rounded, date),
                  if (location.isNotEmpty) _info(Icons.place_rounded, location),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: eventRef.collection('participants').snapshots(),
                    builder: (context, ps) => _info(
                        Icons.groups_rounded,
                        ps.hasData ? '${ps.data!.size}人が参加' : '参加者を読みこみ中'),
                  ),
                ],
              ),
              if (pinned != null && (pinned['text'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFE0A030)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(pinned['text'] as String,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF3D2B1F), height: 1.4)),
                      ),
                      if (isOrganizer)
                        GestureDetector(
                          onTap: () => eventRef
                              .update({'pinned': FieldValue.delete()})
                              .catchError((_) {}),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text('長押しでリアクション。困ったメッセージは、長押しで通報できます。',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFE8845A)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF3D2B1F)),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
