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
late TabController _tabCtrl;
List<Map<String, dynamic>> _joinedEvents = [];
List<Map<String, dynamic>> _orgChats = [];
bool _isLoading = true;

@override
void initState() {
super.initState();
_tabCtrl = TabController(length: 2, vsync: this);
_loadData();
}

@override
void dispose() {
_tabCtrl.dispose();
super.dispose();
}

Future<void> _loadData() async {
try {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

// 団体とのチャット一覧を取得
final chatsSnapshot = await FirebaseFirestore.instance
.collection('chats')
.where('participants', arrayContains: myUid)
.get();

final orgChats = <Map<String, dynamic>>[];
for (final doc in chatsSnapshot.docs) {
final participants = List<String>.from(doc['participants'] ?? []);
final otherUid = participants.firstWhere((u) => u != myUid, orElse: () => '');
if (otherUid.isEmpty) continue;

final orgDoc = await FirebaseFirestore.instance
.collection('organizations')
.doc(otherUid)
.get();
if (!orgDoc.exists) continue; // 団体でなければスキップ

final lastMsgDoc = await FirebaseFirestore.instance
.collection('chats')
.doc(doc.id)
.collection('messages')
.orderBy('createdAt', descending: true)
.limit(1)
.get();

String lastMessage = '';
String lastTime = '';
DateTime? lastTimestamp;
if (lastMsgDoc.docs.isNotEmpty) {
  final data = lastMsgDoc.docs.first.data();
  lastMessage = data['text'] as String? ?? '';
  final time = data['createdAt'] != null
      ? (data['createdAt'] as Timestamp).toDate()
      : DateTime.now();
  lastTime = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  lastTimestamp = time;
}

orgChats.add({
  'uid': otherUid,
  'name': orgDoc.data()?['name'] ?? '',
  'lastMessage': lastMessage,
  'lastTime': lastTime,
  'lastTimestamp': lastTimestamp,
});

}

// 参加済みイベントを取得
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

if (shouldAdd) {
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
}

if (mounted) {
  orgChats.sort((a, b) {
    final at = a['lastTimestamp'] as DateTime?;
    final bt = b['lastTimestamp'] as DateTime?;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  joinedEvents.sort((a, b) {
    final at = a['lastTimestamp'] as DateTime?;
    final bt = b['lastTimestamp'] as DateTime?;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });


setState(() {
_orgChats = orgChats;
_joinedEvents = joinedEvents;
_isLoading = false;
});
}
} catch (e) {
if (mounted) setState(() => _isLoading = false);
}
}
Widget _buildAvatar() {
  return Container(
    width: 52, height: 52,
    decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12)),
    child: const Center(child: Text('🏢', style: TextStyle(fontSize: 24))),
  );
}

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF5F3),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
    );
  }

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
          Tab(text: '団体（${_orgChats.length}）'),
          Tab(text: 'グループ（${_joinedEvents.length}）'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabCtrl,
      children: [
        _orgChats.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏢', style: TextStyle(fontSize: 52)),
              SizedBox(height: 12),
              Text('団体とのやり取りはありません',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _orgChats.length,
          itemBuilder: (_, i) {
            final chat = _orgChats[i];
            return ListTile(
              leading: _buildAvatar(),
              title: Text(chat['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  chat['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              trailing: Text(chat['lastTime'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatPage(
                            userName: chat['name'],
                            userEmoji: '🏢',
                            uid: chat['uid'])));
                _loadData();
              },
            );
          },
        ),
        _joinedEvents.isEmpty
            ? const Center(
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
        )
            : ListView.builder(
          itemCount: _joinedEvents.length,
          itemBuilder: (_, i) {
            final event = _joinedEvents[i];
            return ListTile(
              leading: Container(
                width: 52, height: 52,
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
              subtitle: Text(
                  event['lastMessage'] as String? ?? '',
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
                _loadData();
              },
            );
          },
        ),
      ],
    ),
  );
}
}
