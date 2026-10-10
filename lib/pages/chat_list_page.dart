import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_chat_page.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;

  List<Map<String, dynamic>> _orgChats = [];
  List<Map<String, dynamic>> _joinedEvents = [];

  // null = 団体ではない相手
  final Map<String, Map<String, dynamic>?> _orgCache = {};
  final Map<String, Map<String, dynamic>> _lastMsgCache = {};

  bool _orgLoaded = false;
  bool _eventsLoaded = false;
  bool _hasError = false;
  int _gen = 0;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _listenOrgChats();
    _loadEvents();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ---------- 団体とのチャット（自動更新） ----------

  void _listenOrgChats() {
    final myUid = _myUid;
    if (myUid == null) {
      setState(() => _orgLoaded = true);
      return;
    }
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .listen(_onChatSnapshot, onError: (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _orgLoaded = true;
      });
    });
  }

  Future<void> _onChatSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
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

        if (!_orgCache.containsKey(otherUid)) {
          final orgDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(otherUid)
              .get();
          _orgCache[otherUid] = orgDoc.exists ? (orgDoc.data() ?? {}) : null;
        }
        final org = _orgCache[otherUid];
        if (org == null) continue; // 団体でなければスキップ

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
          'uid': otherUid,
          'name': (org['name'] ?? '').toString(),
          'area': (org['area'] ?? '').toString(),
          'profileImageUrl': (org['profileImageUrl'] ?? '').toString(),
          'lastMessage': lastMessage,
          'lastSenderId': lastSenderId,
          'lastAt': lastAt,
          'purpose': data['purpose'],
          'unread': unread,
        });
      } catch (_) {
        continue;
      }
    }

    list.sort((a, b) {
      final at = a['lastAt'] as DateTime?;
      final bt = b['lastAt'] as DateTime?;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    if (!mounted || gen != _gen) return;
    setState(() {
      _orgChats = list;
      _orgLoaded = true;
      _hasError = false;
    });
  }

  // ---------- 参加中のイベント（グループ） ----------

  Future<void> _loadEvents() async {
    try {
      final myUid = _myUid;
      if (myUid == null) {
        if (mounted) setState(() => _eventsLoaded = true);
        return;
      }

      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();

      final joinedEvents = <Map<String, dynamic>>[];
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        bool shouldAdd = false;

        if (data['organizerUid'] == myUid) {
          shouldAdd = true;
        } else {
          final participantDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(doc.id)
              .collection('participants')
              .doc(myUid)
              .get();
          if (participantDoc.exists) shouldAdd = true;
        }

        if (!shouldAdd) continue;

        String lastMessage = '';
        String lastTime = '';
        DateTime? lastTimestamp;
        final lastMsgDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(doc.id)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        if (lastMsgDoc.docs.isNotEmpty) {
          final msgData = lastMsgDoc.docs.first.data();
          lastMessage = msgData['text'] as String? ?? '';
          final time = msgData['createdAt'] != null
              ? (msgData['createdAt'] as Timestamp).toDate()
              : DateTime.now();
          lastTime = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
          lastTimestamp = time;
        }

        int unreadCount = 0;
        final lastSeenDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('groupChatLastSeen')
            .doc(doc.id)
            .get();

        if (lastSeenDoc.exists) {
          final lastSeen = lastSeenDoc.data()?['lastSeen'] as Timestamp?;
          if (lastSeen != null) {
            final unreadMsgs = await FirebaseFirestore.instance
                .collection('events')
                .doc(doc.id)
                .collection('messages')
                .where('createdAt', isGreaterThan: lastSeen)
                .get();
            unreadCount = unreadMsgs.docs.length;
          }
        } else {
          final allMsgs = await FirebaseFirestore.instance
              .collection('events')
              .doc(doc.id)
              .collection('messages')
              .get();
          unreadCount = allMsgs.docs.length;
        }

        joinedEvents.add({
          'id': doc.id,
          'lastMessage': lastMessage,
          'lastTime': lastTime,
          'lastTimestamp': lastTimestamp,
          'unreadCount': unreadCount,
          ...data
        });
      }

      joinedEvents.sort((a, b) {
        final at = a['lastTimestamp'] as DateTime?;
        final bt = b['lastTimestamp'] as DateTime?;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      if (mounted) {
        setState(() {
          _joinedEvents = joinedEvents;
          _eventsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _eventsLoaded = true);
    }
  }

  // ---------- 表示 ----------

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

  Widget _countBadge(int n, {double size = 20}) {
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(n > 99 ? '99+' : '$n',
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tabLabel(String text, int unread) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (unread > 0) ...[
          const SizedBox(width: 6),
          _countBadge(unread, size: 18),
        ],
      ],
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

  Widget _orgAvatar(Map<String, dynamic> chat) {
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
          if (unread > 0) Positioned(right: -2, top: -2, child: _countBadge(unread)),
        ],
      ),
    );
  }

  Widget _emojiAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Text('🏢', style: TextStyle(fontSize: 26))),
    );
  }

  Widget _orgCard(Map<String, dynamic> chat) {
    final unread = chat['unread'] as int;
    final area = chat['area'] as String;
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
              userEmoji: '🏢',
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
            _orgAvatar(chat),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _pill('🏢 団体', const Color(0xFF2D6A4F)),
                      if (area.isNotEmpty)
                        _pill('📍 $area', Colors.grey[700]!),
                      if (purposeLabel != null)
                        _pill(purposeLabel, const Color(0xFFE8845A)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgTab() {
    if (_hasError) {
      return const Center(
          child:
          Text('読み込めませんでした', style: TextStyle(color: Colors.grey)));
    }
    if (_orgChats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏢', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('団体とのやり取りはありません',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: _orgChats.length,
      itemBuilder: (_, i) => _orgCard(_orgChats[i]),
    );
  }

  Widget _buildEventTab() {
    if (_joinedEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👥', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('参加中のイベントがありません',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text('イベントに参加してみよう！',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _joinedEvents.length,
      itemBuilder: (_, i) {
        final event = _joinedEvents[i];
        return ListTile(
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(event['emoji'] as String? ?? '🐾',
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          title: Text(event['title'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(event['lastMessage'] as String? ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(event['lastTime'] as String? ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              const SizedBox(height: 4),
              if ((event['unreadCount'] as int? ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0xFFE8845A), shape: BoxShape.circle),
                  child: Text('${event['unreadCount']}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                )
              else
                const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFF2D6A4F), size: 18),
            ],
          ),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EventChatPage(
                        eventId: event['id'],
                        eventTitle: event['title'] as String? ?? '')));
            _loadEvents();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_orgLoaded || !_eventsLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF5F3),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }

    final orgUnread =
    _orgChats.fold<int>(0, (sum, c) => sum + (c['unread'] as int));
    final eventUnread = _joinedEvents.fold<int>(
        0, (sum, e) => sum + (e['unreadCount'] as int? ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('チャット 💬',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFE8845A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE8845A),
          tabs: [
            Tab(child: _tabLabel('団体（${_orgChats.length}）', orgUnread)),
            Tab(
                child: _tabLabel(
                    'グループ（${_joinedEvents.length}）', eventUnread)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOrgTab(),
          _buildEventTab(),
        ],
      ),
    );
  }
}