import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'notification_prefs.dart';



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

  @override
  void initState() {
    super.initState();
    _loadMyInfo();
  _updateLastSeen();
}

Future<void> _updateLastSeen() async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(myUid)
      .collection('groupChatLastSeen')
      .doc(widget.eventId)
      .set({'lastSeen': FieldValue.serverTimestamp()});
}

  @override
  void dispose() {
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
    if (text.trim().isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('messages')
        .add({
      'text': text,
      'senderUid': myUid,
      'senderName': _myName ?? '',
      'senderImageUrl': _myImageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _msgCtrl.clear();
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

    for (final uid in notifyUids) {
      if (!await shouldSendNotification(uid, 'イベント関連')) continue;
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .add({
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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
      Expanded(
      child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
          .doc(widget.eventId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFE8845A)));
        }
        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💬', style: TextStyle(fontSize: 48)),
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
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final data =
            messages[i].data() as Map<String, dynamic>;
            final isMe = data['senderUid'] == myUid;
            final isSystem = data['isSystem'] == true;
            final timeStr = _timeAgo(data['createdAt']);

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

            return Padding(
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
                            (data['senderImageUrl'] as String).isNotEmpty
                            ? Image.network(
                            data['senderImageUrl'],
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
                          padding:
                          const EdgeInsets.only(bottom: 4),
                          child: Text(
                              data['senderName'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600])),
                        ),
                      Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context)
                                .size
                                .width *
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
                                color: Colors.black
                                    .withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                            data['text'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF3D2B1F),
                                height: 1.4)),
                      ),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力...',
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
                              color: const Color(0xFFE8845A)
                                  .withOpacity(0.3),
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
            ),
          ],
      ),
    );
  }
}
