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

class _OrganizationChatListPageState extends State<OrganizationChatListPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .get();

    final chats = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      final otherUid = participants.firstWhere((u) => u != myUid, orElse: () => '');
      if (otherUid.isEmpty) continue;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get();
      if (!userDoc.exists) continue;

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

      chats.add({
        'uid': otherUid,
        'name': userDoc.data()?['name'] ?? '',
        'profileImageUrl': userDoc.data()?['profileImageUrl'] ?? '',
        'lastMessage': lastMessage,
        'lastTime': lastTime,
        'lastTimestamp': lastTimestamp,
      });
    }

    chats.sort((a, b) {
      final at = a['lastTimestamp'] as DateTime?;
      final bt = b['lastTimestamp'] as DateTime?;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    if (mounted) {

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('問い合わせ一覧 💬',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: _chats.isEmpty
          ? const Center(
          child: Text('まだ問い合わせはありません', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (_, i) {
          final chat = _chats[i];
          return ListTile(
            leading: chat['profileImageUrl'] != null &&
                (chat['profileImageUrl'] as String).isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(chat['profileImageUrl'],
                  width: 52, height: 52, fit: BoxFit.cover),
            )
                : Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🐾')),
            ),
            title: Text(chat['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chat['lastMessage'],
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(chat['lastTime'],
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    userName: chat['name'],
                    userEmoji: '🐾',
                    uid: chat['uid'],
                  ),
                ),
              );
              _loadChats();
            },
          );
        },
      ),
    );
  }
}
