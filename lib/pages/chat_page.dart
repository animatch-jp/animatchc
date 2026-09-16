import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_page.dart';
import 'user_profile_page.dart';
import 'organization_profile_page.dart';
import 'root_page.dart';
import 'notification_prefs.dart';


class ChatPage extends StatefulWidget {
  final String userName;
  final String userEmoji;
  final String? uid;

  const ChatPage({
    super.key,
    required this.userName,
    required this.userEmoji,
    this.uid,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
final _msgCtrl = TextEditingController();
final _scrollCtrl = ScrollController();
bool _isMuted = false;
String? _otherUserImageUrl;
bool _isBlocked = false;
bool _isBlockedBy = false;

String get _chatId {
final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
final otherUid = widget.uid ?? '';
final ids = [myUid, otherUid]..sort();
return ids.join('_');
}

@override
void initState() {
  super.initState();
  _loadOtherUserImage();
  _checkBlockStatus();
  _detectPartnerType();

Future<void> _markMessagesAsRead() async {
if (widget.uid == null) return;
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;
final unreadMessages = await FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.collection('messages')
.where('read', isEqualTo: false)
.get();
for (final doc in unreadMessages.docs) {
final data = doc.data();
if (data['senderId'] != myUid) {
await doc.reference.update({'read': true});
}
}
}
_markMessagesAsRead();
}

@override
void dispose() {
_msgCtrl.dispose();
_scrollCtrl.dispose();
super.dispose();
}

Future<void> _loadOtherUserImage() async {
if (widget.uid == null) return;
final doc = await FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.get();
if (doc.exists && mounted) {
setState(() {
_otherUserImageUrl = doc.data()?['profileImageUrl'];
});
}
}

Future<void> _checkBlockStatus() async {
if (widget.uid == null) return;
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

final blockedDoc = await FirebaseFirestore.instance
.collection('blocks')
.doc(myUid)
.collection('blocked')
.doc(widget.uid)
.get();

final blockedByDoc = await FirebaseFirestore.instance
.collection('blocks')
.doc(widget.uid)
.collection('blocked')
.doc(myUid)
.get();

if (mounted) {
setState(() {
_isBlocked = blockedDoc.exists;
_isBlockedBy = blockedByDoc.exists;
});
}
}

Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;
  if (_isBlocked || _isBlockedBy) return;
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;

  await FirebaseFirestore.instance
      .collection('chats')
      .doc(_chatId)
      .set({
    'participants': [myUid, widget.uid ?? ''],
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  FirebaseFirestore.instance
      .collection('chats')
      .doc(_chatId)
      .collection('messages')
      .add({
    'text': text,
    'senderId': myUid,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
    'type': 'text',
  });

_msgCtrl.clear();
  if (widget.uid != null) {
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    final myName = myDoc.data()?['name'] ?? '';

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .get();
    final lastNotifiedMap = chatDoc.data()?['lastNotifiedAt'] as Map<String, dynamic>? ?? {};
    final lastNotifiedTimestamp = lastNotifiedMap[myUid] as Timestamp?;

    bool shouldNotify = true;
    if (lastNotifiedTimestamp != null) {
      final diff = DateTime.now().difference(lastNotifiedTimestamp.toDate());
      if (diff.inMinutes < 5) shouldNotify = false;
    }

    if (shouldNotify) {
      // ブロックされているか確認
      final blockedByDoc = await FirebaseFirestore.instance
          .collection('blocks')
          .doc(widget.uid)
          .collection('blocked')
          .doc(myUid)
          .get();

      if (!blockedByDoc.exists && widget.uid != null &&
          await shouldSendNotification(widget.uid!, 'コメント・メッセージ')) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.uid)
            .collection('items')
            .add({
          'type': 'chat',
          'emoji': '💬',
          'title': 'メッセージが届きました！',
          'desc': '$myName さんからメッセージが届きました',
          'fromUid': myUid,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .set({'lastNotifiedAt.$myUid': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    }

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

void _sendLocation() {
if (_isBlocked || _isBlockedBy) return;
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;
FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.collection('messages')
.add({
'text': '📍 現在地を共有しました',
'senderId': myUid,
'createdAt': FieldValue.serverTimestamp(),
'read': false,
'type': 'location',
});
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('位置情報を共有しました📍'),
backgroundColor: Color(0xFF2D6A4F),
),
);
}

String? _partnerType;

Future<void> _detectPartnerType() async {
  if (widget.uid == null) return;
  final orgDoc = await FirebaseFirestore.instance
      .collection('organizations')
      .doc(widget.uid)
      .get();
  if (orgDoc.exists && mounted) {
    setState(() => _partnerType = 'org');
  }
}

void _showUserProfile() {
  if (widget.uid == null) return;
  if (_partnerType == 'org') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationProfilePage(orgId: widget.uid!),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(uid: widget.uid!),
      ),
    );
  }
}


Widget _buildUserAvatar({double size = 40}) {
if (_otherUserImageUrl != null && _otherUserImageUrl!.isNotEmpty) {
return ClipOval(
child: Image.network(
_otherUserImageUrl!,
width: size, height: size,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
width: size, height: size,
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
shape: BoxShape.circle),
child: Center(
child: Text(widget.userEmoji,
style: TextStyle(fontSize: size * 0.5))),
),
),
);
}
return Container(
width: size, height: size,
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
shape: BoxShape.circle),
child: Center(
child: Text(widget.userEmoji,
style: TextStyle(fontSize: size * 0.5))),
);
}
@override
Widget build(BuildContext context) {
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
title: GestureDetector(
onTap: _showUserProfile,
child: Row(
children: [
_buildUserAvatar(size: 40),
const SizedBox(width: 10),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(widget.userName,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
const Text('タップでプロフィールを見る',
style: TextStyle(fontSize: 10, color: Colors.grey)),
],
),
],
),
),
actions: [
PopupMenuButton(
icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14)),
itemBuilder: (_) => [
PopupMenuItem(
child: Row(children: [
Icon(_isMuted
? Icons.volume_up_rounded
: Icons.volume_off_rounded,
color: Colors.grey),
const SizedBox(width: 8),
Text(_isMuted ? 'ミュート解除' : 'ミュートする'),
]),
onTap: () {
Future.delayed(const Duration(milliseconds: 100), () {
setState(() => _isMuted = !_isMuted);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(_isMuted
? 'ミュートしました🔇'
: 'ミュートを解除しました🔊'),
backgroundColor: Colors.grey,
),
);
});
},
),
  PopupMenuItem(
    child: const Row(children: [
      Icon(Icons.block_rounded, color: Colors.orange),
      SizedBox(width: 8),
      Text('ブロックする'),
    ]),
    onTap: () {
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('ブロックしますか？'),
            content: Text(
                '${widget.userName}さんをブロックすると、チャットができなくなります。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('ブロックする'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        if (myUid == null || widget.uid == null) return;
        await FirebaseFirestore.instance
            .collection('blocks')
            .doc(myUid)
            .collection('blocked')
            .doc(widget.uid)
            .set({'createdAt': FieldValue.serverTimestamp()});
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RootPage(initialIndex: 3)),
                (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ブロックしました'),
              backgroundColor: Colors.orange,
            ),
          );
        }

      });
    },
  ),

PopupMenuItem(
child: const Row(children: [
Icon(Icons.flag_rounded, color: Colors.red),
SizedBox(width: 8),
Text('通報する',
style: TextStyle(color: Colors.red)),
]),
onTap: () {
Future.delayed(const Duration(milliseconds: 100), () {
Navigator.push(context,
MaterialPageRoute(
builder: (_) => ReportPage(
userName: widget.userName,
targetUid: widget.uid ?? '')));
});
},
),
],
),
],
),
body: Column(
children: [
if (_isBlocked || _isBlockedBy)
Container(
padding: const EdgeInsets.all(12),
color: Colors.orange[50],
child: Row(
children: [
const Icon(Icons.block_rounded,
color: Colors.orange, size: 16),
const SizedBox(width: 8),
Text(
_isBlocked
? 'このユーザーをブロックしています'
: 'メッセージを送ることができません',
style: const TextStyle(
color: Colors.orange, fontSize: 13),
),
],
),
),
Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.collection('messages')
.orderBy('createdAt')
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(
color: Color(0xFFE8845A)),
);
}
final messages = snapshot.data!.docs;
final myUid =
FirebaseAuth.instance.currentUser?.uid;

for (final doc in messages) {
final data = doc.data() as Map<String, dynamic>;
if (data['senderId'] != myUid &&
data['read'] == false) {
doc.reference.update({'read': true});
}
}

return ListView.builder(
controller: _scrollCtrl,
padding: const EdgeInsets.all(16),
itemCount: messages.length,
itemBuilder: (_, i) {
final data =
messages[i].data() as Map<String, dynamic>;
final isMe = data['senderId'] == myUid;
final isRead = data['read'] as bool? ?? false;
final type = data['type'] as String? ?? 'text';
final time = data['createdAt'] != null
? (data['createdAt'] as Timestamp).toDate()
: DateTime.now();
final timeStr =
'${time.hour}:${time.minute.toString().padLeft(2, '0')}';
final showDate = i == 0;

return Column(
children: [
if (showDate)
Container(
margin: const EdgeInsets.only(bottom: 16),
padding: const EdgeInsets.symmetric(
horizontal: 12, vertical: 4),
decoration: BoxDecoration(
color: Colors.grey[200],
borderRadius:
BorderRadius.circular(12)),
  child: Text(
        () {
      final msgTime = data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDay = DateTime(msgTime.year, msgTime.month, msgTime.day);
      if (msgDay == today) return '今日';
      if (msgDay == yesterday) return '昨日';
      return '${msgTime.year}年${msgTime.month}月${msgTime.day}日';
    }(),
    style: const TextStyle(fontSize: 11, color: Colors.grey),
  ),

),
Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Row(
mainAxisAlignment: isMe
? MainAxisAlignment.end
: MainAxisAlignment.start,
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
if (!isMe) ...[
_buildUserAvatar(size: 32),
const SizedBox(width: 8),
],
Column(
crossAxisAlignment: isMe
? CrossAxisAlignment.end
: CrossAxisAlignment.start,
children: [
Container(
constraints: BoxConstraints(
maxWidth:
MediaQuery.of(context)
.size
.width *
0.65),
padding:
const EdgeInsets.symmetric(
horizontal: 14,
vertical: 10),
decoration: BoxDecoration(
color: type == 'location'
? const Color(0xFF2D6A4F)
: isMe
? const Color(0xFFE8845A)
: Colors.white,
borderRadius: BorderRadius.only(
topLeft:
const Radius.circular(18),
topRight:
const Radius.circular(18),
bottomLeft: Radius.circular(
isMe ? 18 : 4),
bottomRight: Radius.circular(
isMe ? 4 : 18),
),
boxShadow: [
BoxShadow(
color: Colors.black
.withOpacity(0.06),
blurRadius: 6,
offset:
const Offset(0, 2))
],
),
child: Text(
data['text'] as String? ?? '',
style: TextStyle(
fontSize: 14,
color: isMe ||
type == 'location'
? Colors.white
: const Color(
0xFF3D2B1F),
height: 1.4)),
),
const SizedBox(height: 4),
Row(
children: [
Text(timeStr,
style: TextStyle(
fontSize: 10,
color: Colors.grey[400])),
if (isMe) ...[
const SizedBox(width: 4),
Icon(
isRead
? Icons.done_all_rounded
: Icons.done_rounded,
size: 14,
color: isRead
? const Color(0xFFE8845A)
: Colors.grey[400]),
],
],
),
],
),
],
),
),
],
);
},
);
}),
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
            enabled: !_isBlocked && !_isBlockedBy,
            decoration: InputDecoration(
              hintText: _isBlocked
                  ? 'ブロック中のためメッセージを送れません'
                  : _isBlockedBy
                  ? 'メッセージを送ることができません'
                  : 'メッセージを入力...',
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
              color: _isBlocked || _isBlockedBy
                  ? Colors.grey
                  : const Color(0xFFE8845A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: (_isBlocked || _isBlockedBy
                        ? Colors.grey
                        : const Color(0xFFE8845A))
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
]));
}
}
