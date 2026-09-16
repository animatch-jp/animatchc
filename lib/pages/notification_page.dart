import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'event_page.dart';
import 'root_page.dart';
import 'chat_page.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
List<Map<String, dynamic>> _notifs = [];
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadNotifications();
}

Future<void> _loadNotifications() async {
try {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

final snapshot = await FirebaseFirestore.instance
.collection('notifications')
.doc(myUid)
.collection('items')
.orderBy('createdAt', descending: true)
.limit(50)
.get();
// 50件以上の古い通知を削除
if (snapshot.docs.length > 50) {
final oldNotifs = snapshot.docs.sublist(50);
final batch = FirebaseFirestore.instance.batch();
for (final doc in oldNotifs) {
batch.delete(doc.reference);
}
await batch.commit();
}


if (mounted) {
setState(() {
_notifs = snapshot.docs
.map((d) => {'id': d.id, ...d.data()})
.toList();
_isLoading = false;
});
}
} catch (e) {
if (mounted) setState(() => _isLoading = false);
}
}

Future<void> _markAllAsRead() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

final batch = FirebaseFirestore.instance.batch();
for (final notif in _notifs) {
if (notif['read'] == false) {
final ref = FirebaseFirestore.instance
.collection('notifications')
.doc(myUid)
.collection('items')
.doc(notif['id']);
batch.update(ref, {'read': true});
}
}
await batch.commit();

setState(() {
_notifs = _notifs.map((n) => {...n, 'read': true}).toList();
});
}

Future<void> _markAsRead(int index) async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;
if (_notifs[index]['read'] == true) return;

await FirebaseFirestore.instance
.collection('notifications')
.doc(myUid)
.collection('items')
.doc(_notifs[index]['id'])
.update({'read': true});

setState(() {
_notifs[index] = {..._notifs[index], 'read': true};
});
}

String _timeAgo(dynamic timestamp) {
if (timestamp == null) return '';
final now = DateTime.now();
final time = (timestamp as dynamic).toDate() as DateTime;
final diff = now.difference(time);

if (diff.inMinutes < 1) return 'たった今';
if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
if (diff.inHours < 24) return '${diff.inHours}時間前';
if (diff.inDays < 7) return '${diff.inDays}日前';
return '${time.month}/${time.day}';
}

Color _typeColor(String type) {
switch (type) {
case 'like': return const Color(0xFFE8845A);
case 'chat': return Colors.blue;
case 'event': return Colors.purple;
case 'support': return const Color(0xFF2D6A4F);
case 'urgent': return Colors.red;
case 'orgApproved': return const Color(0xFF2D6A4F);
case 'orgRejected': return Colors.red;
case 'orgUpdateReflected': return const Color(0xFF2D6A4F);
case 'hospitalApproved': return const Color(0xFF4DA8DA);
case 'hospitalRejected': return Colors.red;
case 'hospitalUpdateReflected': return const Color(0xFF4DA8DA);
default: return Colors.grey;
}
}
@override
Widget build(BuildContext context) {
  final unread = _notifs.where((n) => n['read'] == false).length;

  return Scaffold(
    backgroundColor: const Color(0xFFFFF8F5),
    appBar: AppBar(
      title: Text(unread > 0 ? '通知 ($unread)' : '通知',
          style: const TextStyle(
              fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
      backgroundColor: const Color(0xFFFFF8F5),
      elevation: 0,
      actions: [
        TextButton(
          onPressed: _markAllAsRead,
          child: const Text('全て既読',
              style: TextStyle(
                  color: Color(0xFFE8845A),
                  fontWeight: FontWeight.bold)),
        ),
      ],
    ),
    body: _isLoading
        ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8845A)))
        : _notifs.isEmpty
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('まだ通知がありません',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          SizedBox(height: 8),
          Text('いいねやお知らせが届くとここに表示されます',
              style:
              TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifs.length,
      itemBuilder: (_, i) {
        final notif = _notifs[i];
        final isRead = notif['read'] as bool? ?? true;
        final type = notif['type'] as String? ?? 'like';
        final color = _typeColor(type);

        return GestureDetector(
          onTap: () async {
            await _markAsRead(i);
            if (type == 'eventRemoved' && mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RootPage()),
                    (route) => false,
              );
              return;
            }

            final eventId = notif['eventId'] as String?;
            if ((type == 'event' || type == 'eventCancel' || type == 'eventUpdate' || type == 'groupChat') && eventId != null && mounted) {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventPage(initialEventId: eventId),
                ),
              );
              return;
            }
            final fromUid = notif['fromUid'] as String?;
            if (type == 'chat' && fromUid != null && mounted) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUid)
                  .get();
              final userName = userDoc.data()?['name'] as String? ?? '';
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      userName: userName,
                      userEmoji: '🐾',
                      uid: fromUid,
                    ),
                  ),
                );
              }
              return;
            }
            if (fromUid != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(uid: fromUid),
                ),
              );
            }
          },



          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.white
                  : color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: isRead
                  ? null
                  : Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                      child: Text(
                          notif['emoji'] as String? ?? '🔔',
                          style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                notif['title'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color:
                                    const Color(0xFF3D2B1F))),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notif['desc'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(_timeAgo(notif['createdAt']),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}
