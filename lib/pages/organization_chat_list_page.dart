import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class OrganizationChatListPage extends StatefulWidget {
  const OrganizationChatListPage({super.key});

  @override
  State<OrganizationChatListPage> createState() =>
      _OrganizationChatListPageState();
}

class _OrganizationChatListPageState extends State<OrganizationChatListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _ticker;

  List<Map<String, dynamic>> _entries = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Map<String, dynamic>> _lastMsgCache = {};
  bool _isLoading = true;
  bool _hasError = false;
  int _gen = 0;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _listen();
    // 「24時間以上経過」の表示を、1分ごとに更新する
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _listen() {
    final myUid = _myUid;
    if (myUid == null) {
      setState(() => _isLoading = false);
      return;
    }
    _sub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    });
  }

  Future<void> _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    final gen = ++_gen;
    final myUid = _myUid;
    if (myUid == null) return;

    final list = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      try {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUid =
        participants.firstWhere((u) => u != myUid, orElse: () => '');
        if (otherUid.isEmpty) continue;

        // 相手（ユーザー）の情報
        if (!_userCache.containsKey(otherUid)) {
          final u = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUid)
              .get();
          _userCache[otherUid] = u.data() ?? {};
        }
        final user = _userCache[otherUid]!;

        // 最後のメッセージ
        String lastMessage = (data['lastMessage'] as String?) ?? '';
        String? lastSenderId = data['lastSenderId'] as String?;
        DateTime? lastAt;
        final rawAt = data['lastMessageAt'];
        if (rawAt is Timestamp) lastAt = rawAt.toDate();

        if (data['lastMessage'] == null) {
          // 古いチャット：メッセージから最後の1件を読む
          var cached = _lastMsgCache[doc.id];
          if (cached == null) {
            final last = await FirebaseFirestore.instance
                .collection('chats')
                .doc(doc.id)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();
            cached = {};
            if (last.docs.isNotEmpty) {
              final m = last.docs.first.data();
              cached['text'] = m['text'] ?? '';
              cached['senderId'] = m['senderId'];
              final t = m['createdAt'];
              if (t is Timestamp) cached['at'] = t.toDate();
            }
            _lastMsgCache[doc.id] = cached;
          }
          lastMessage = (cached['text'] as String?) ?? '';
          lastSenderId = cached['senderId'] as String?;
          lastAt = cached['at'] as DateTime?;
        } else if (lastAt == null) {
          lastAt = DateTime.now(); // 送信直後で、時刻がまだ確定していない
        }

        int unread = 0;
        final unreadMap = data['unread'];
        if (unreadMap is Map) {
          final v = unreadMap[myUid];
          if (v is num) unread = v.toInt();
        }

        list.add({
          'chatId': doc.id,
          'uid': otherUid,
          'name': (user['name'] ?? '退会したユーザー').toString(),
          'profileImageUrl': (user['profileImageUrl'] ?? '').toString(),
          'lastMessage': lastMessage,
          'lastSenderId': lastSenderId,
          'lastAt': lastAt,
          'status': data['status'],
          'purpose': data['purpose'],
          'unread': unread,
        });
      } catch (_) {
        continue;
      }
    }

    if (!mounted || gen != _gen) return;
    setState(() {
      _entries = list;
      _isLoading = false;
      _hasError = false;
    });
  }

  // 'waiting' = 未返信 / 'replied' = 対応中 / 'done' = 対応完了
  String _statusOf(Map<String, dynamic> e) {
    if (e['status'] == 'done') return 'done';
    final lastSender = e['lastSenderId'] as String?;
    if (lastSender != null && lastSender == _myUid) return 'replied';
    return 'waiting';
  }

  bool _isOverdue(Map<String, dynamic> e) {
    if (_statusOf(e) != 'waiting') return false;
    final at = e['lastAt'] as DateTime?;
    if (at == null) return false;
    return DateTime.now().difference(at).inHours >= 24;
  }

  String _overdueLabel(Map<String, dynamic> e) {
    final at = e['lastAt'] as DateTime?;
    if (at == null) return '';
    final days = DateTime.now().difference(at).inDays;
    return days >= 2 ? '⏰ $days日経過' : '⏰ 24時間以上経過';
  }

  String _timeLabel(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) {
      return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (day == today.subtract(const Duration(days: 1))) return '昨日';
    return '${t.month}/${t.day}';
  }

  List<Map<String, dynamic>> _listFor(String status) {
    final items = _entries.where((e) => _statusOf(e) == status).toList();
    items.sort((a, b) {
      final ao = _isOverdue(a);
      final bo = _isOverdue(b);
      if (ao != bo) return ao ? -1 : 1;
      final at = a['lastAt'] as DateTime?;
      final bt = b['lastAt'] as DateTime?;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return items;
  }

  Widget _avatar(Map<String, dynamic> chat) {
    final url = chat['profileImageUrl'] as String;
    final unread = chat['unread'] as int;
    final image = url.isNotEmpty
        ? ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(url,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiAvatar()),
    )
        : _emojiAvatar();
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, bottom: 0, child: image),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emojiAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
          color: const Color(0xFFE8845A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 24))),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _card(Map<String, dynamic> chat) {
    final overdue = _isOverdue(chat);
    final unread = chat['unread'] as int;
    final purposeKey = chat['purpose'] as String?;
    final purposeLabel =
    purposeKey == null ? null : kInquiryPurposeLabels[purposeKey];
    final lastMessage = chat['lastMessage'] as String;
    final iSentLast = chat['lastSenderId'] == _myUid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              userName: chat['name'] as String,
              userEmoji: '🐾',
              uid: chat['uid'] as String,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: overdue ? Border.all(color: Colors.red[300]!, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(chat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(chat['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: unread > 0
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: const Color(0xFF3D2B1F))),
                      ),
                      Text(_timeLabel(chat['lastAt'] as DateTime?),
                          style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    iSentLast ? 'あなた：$lastMessage' : lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight:
                        unread > 0 ? FontWeight.bold : FontWeight.normal,
                        color: unread > 0
                            ? const Color(0xFF3D2B1F)
                            : Colors.grey[600]),
                  ),
                  if (purposeLabel != null || overdue) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (purposeLabel != null)
                          _pill(purposeLabel, const Color(0xFFE8845A)),
                        if (overdue) _pill(_overdueLabel(chat), Colors.red),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(String status, String emptyEmoji, String emptyText) {
    final items = _listFor(status);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(emptyText,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(items[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
        Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }

    final waiting = _listFor('waiting').length;
    final replied = _listFor('replied').length;
    final done = _listFor('done').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('問い合わせ一覧 💬',
            style:
            TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFE8845A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE8845A),
          tabs: [
            Tab(text: '未返信（$waiting）'),
            Tab(text: '対応中（$replied）'),
            Tab(text: '完了（$done）'),
          ],
        ),
      ),
      body: _hasError
          ? const Center(
          child: Text('読み込めませんでした',
              style: TextStyle(color: Colors.grey)))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _tabBody('waiting', '🎉', '未返信の問い合わせはありません'),
          _tabBody('replied', '💬', '対応中の問い合わせはありません'),
          _tabBody('done', '✅', '完了した問い合わせはありません'),
        ],
      ),
    );
  }
}