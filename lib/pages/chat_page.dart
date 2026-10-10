import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_page.dart';
import 'user_profile_page.dart';
import 'organization_profile_page.dart';
import 'root_page.dart';
import 'notification_prefs.dart';

/// 団体への問い合わせの用件（団体の一覧画面でも使います）
const Map<String, String> kInquiryPurposeLabels = {
  'adoption': '🐾 里親に興味がある',
  'volunteer': '🤝 ボランティアしたい',
  'lost': '🔍 迷子の情報',
  'other': '💬 その他',
};

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
  bool _isSending = false;

  String? _partnerType;
  Map<String, dynamic>? _partnerOrgData;
  bool _isMeOrg = false;

  Map<String, dynamic>? _chat;
  bool _chatLoaded = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  String? _selectedPurpose;

  String get _chatId {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUid = widget.uid ?? '';
    final ids = [myUid, otherUid]..sort();
    return ids.join('_');
  }

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(_chatId);

  @override
  void initState() {
    super.initState();
    _loadOtherUserImage();
    _checkBlockStatus();
    _detectTypes();
    _listenChatDoc();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _listenChatDoc() {
    _chatSub = _chatRef.snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _chat = snap.data();
        _chatLoaded = true;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _chatLoaded = true);
    });
  }

  Future<void> _detectTypes() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final partnerUid = widget.uid;

    final myOrgDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(myUid)
        .get();

    DocumentSnapshot<Map<String, dynamic>>? partnerOrgDoc;
    if (partnerUid != null && partnerUid.isNotEmpty) {
      partnerOrgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(partnerUid)
          .get();
    }

    if (!mounted) return;
    setState(() {
      _isMeOrg = myOrgDoc.exists;
      if (partnerOrgDoc != null && partnerOrgDoc.exists) {
        _partnerType = 'org';
        _partnerOrgData = partnerOrgDoc.data();
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    final partnerUid = widget.uid;
    if (partnerUid == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final unreadMessages = await _chatRef
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();
    for (final doc in unreadMessages.docs) {
      if (doc.data()['senderId'] != myUid) {
        await doc.reference.update({'read': true});
      }
    }
    await _resetMyUnread();
  }

  Future<void> _resetMyUnread() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final snap = await _chatRef.get();
    if (!snap.exists) return;
    await _chatRef.set({
      'unread': {myUid: 0}
    }, SetOptions(merge: true));
  }

  Future<void> _loadOtherUserImage() async {
    final partnerUid = widget.uid;
    if (partnerUid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(partnerUid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _otherUserImageUrl = doc.data()?['profileImageUrl'];
      });
    }
  }

  Future<void> _checkBlockStatus() async {
    final partnerUid = widget.uid;
    if (partnerUid == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final blockedDoc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .doc(partnerUid)
        .get();

    final blockedByDoc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(partnerUid)
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
    final body = text.trim();
    if (body.isEmpty) return;
    if (_isBlocked || _isBlockedBy || _isSending) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final otherUid = widget.uid ?? '';

    setState(() => _isSending = true);
    try {
      final chatSnap = await _chatRef.get();
      final chatData = chatSnap.data();

      final unread = <String, dynamic>{myUid: 0};
      if (otherUid.isNotEmpty) {
        unread[otherUid] = FieldValue.increment(1);
      }

      final chatUpdate = <String, dynamic>{
        'participants': [myUid, otherUid],
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': body,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'status': 'open',
        'unread': unread,
      };
      if (!_isMeOrg &&
          _partnerType == 'org' &&
          chatData?['purpose'] == null) {
        chatUpdate['purpose'] = _selectedPurpose ?? 'other';
      }
      await _chatRef.set(chatUpdate, SetOptions(merge: true));

      await _chatRef.collection('messages').add({
        'text': body,
        'senderId': myUid,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      _msgCtrl.clear();

      if (otherUid.isNotEmpty) {
        await _notifyOther(myUid, otherUid, chatData);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを送れませんでした'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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

  Future<void> _notifyOther(
      String myUid, String otherUid, Map<String, dynamic>? chatData) async {
    final lastNotifiedMap =
        chatData?['lastNotifiedAt'] as Map<String, dynamic>? ?? {};
    final lastNotified = lastNotifiedMap[myUid];
    if (lastNotified is Timestamp) {
      final diff = DateTime.now().difference(lastNotified.toDate());
      if (diff.inMinutes < 5) return;
    }

    final blockedByDoc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(otherUid)
        .collection('blocked')
        .doc(myUid)
        .get();
    if (blockedByDoc.exists) return;
    if (!await shouldSendNotification(otherUid, 'コメント・メッセージ')) return;

    String myName = '';
    final myDoc =
    await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    myName = (myDoc.data()?['name'] ?? '').toString();
    if (myName.isEmpty) {
      final myOrgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(myUid)
          .get();
      myName = (myOrgDoc.data()?['name'] ?? '').toString();
    }

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(otherUid)
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

    await _chatRef.set({
      'lastNotifiedAt': {myUid: FieldValue.serverTimestamp()}
    }, SetOptions(merge: true));
  }

  void _sendLocation() {
    if (_isBlocked || _isBlockedBy) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    _chatRef.collection('messages').add({
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

  Future<void> _setStatus(String status) async {
    await _chatRef.set({'status': status}, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'done' ? '対応完了にしました✅' : '対応中に戻しました'),
          backgroundColor: const Color(0xFF2D6A4F),
        ),
      );
    }
  }

  void _showUserProfile() {
    final partnerUid = widget.uid;
    if (partnerUid == null) return;
    if (_partnerType == 'org') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrganizationProfilePage(orgId: partnerUid),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(uid: partnerUid),
        ),
      );
    }
  }

  Widget _buildUserAvatar({double size = 40}) {
    if (_otherUserImageUrl != null && _otherUserImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _otherUserImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
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
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: const Color(0xFFE8845A).withOpacity(0.1),
          shape: BoxShape.circle),
      child: Center(
          child: Text(widget.userEmoji,
              style: TextStyle(fontSize: size * 0.5))),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoBanner() {
    final chat = _chat;
    final purposeKey = chat?['purpose'] as String?;
    final purposeLabel =
    purposeKey == null ? null : kInquiryPurposeLabels[purposeKey];

    if (_isMeOrg) {
      if (chat == null) return const SizedBox.shrink();
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final isDone = chat['status'] == 'done';
      final lastSender = chat['lastSenderId'] as String?;
      String statusText;
      Color statusColor;
      if (isDone) {
        statusText = '✅ 対応完了';
        statusColor = const Color(0xFF2D6A4F);
      } else if (lastSender != null && lastSender == myUid) {
        statusText = '💬 対応中';
        statusColor = const Color(0xFF3498DB);
      } else {
        statusText = '🔔 未返信';
        statusColor = const Color(0xFFE8845A);
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('問い合わせ',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            if (purposeLabel != null)
              _pill(purposeLabel, const Color(0xFFE8845A)),
            _pill(statusText, statusColor),
          ],
        ),
      );
    }

    final org = _partnerOrgData;
    if (_partnerType == 'org' && org != null) {
      final name = (org['name'] ?? widget.userName).toString();
      final area = (org['area'] ?? '').toString();
      final activity = (org['activityDescription'] ?? '').toString();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                ),
                _pill('🏢 団体', const Color(0xFF2D6A4F)),
              ],
            ),
            if (area.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 $area',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
            if (activity.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(activity,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600], height: 1.4)),
            ],
            if (purposeLabel != null) ...[
              const SizedBox(height: 6),
              _pill(purposeLabel, const Color(0xFFE8845A)),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool get _showPurposeChooser =>
      _chatLoaded &&
          !_isMeOrg &&
          _partnerType == 'org' &&
          _chat?['purpose'] == null &&
          !_isBlocked &&
          !_isBlockedBy;

  Widget _buildPurposeChooser() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('どんなご用件ですか？（団体に最初に伝わります）',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kInquiryPurposeLabels.entries.map((e) {
              final sel = _selectedPurpose == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedPurpose = e.key),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  DateTime _msgTime(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return ts is Timestamp ? ts.toDate() : DateTime.now();
  }

  String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) return '今日';
    if (day == yesterday) return '昨日';
    return '${t.year}年${t.month}月${t.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _chat?['status'] == 'done';
    final blockedAny = _isBlocked || _isBlockedBy;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3D2B1F)),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              if (_isMeOrg && _chat != null)
                PopupMenuItem(
                  child: Row(children: [
                    Icon(
                        isDone
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        color: const Color(0xFF2D6A4F)),
                    const SizedBox(width: 8),
                    Text(isDone ? '対応中に戻す' : '対応完了にする'),
                  ]),
                  onTap: () => _setStatus(isDone ? 'open' : 'done'),
                ),
              PopupMenuItem(
                child: Row(children: [
                  Icon(
                      _isMuted
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
                        content: Text(
                            _isMuted ? 'ミュートしました🔇' : 'ミュートを解除しました🔊'),
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
                    final partnerUid = widget.uid;
                    if (myUid == null || partnerUid == null) return;
                    await FirebaseFirestore.instance
                        .collection('blocks')
                        .doc(myUid)
                        .collection('blocked')
                        .doc(partnerUid)
                        .set({'createdAt': FieldValue.serverTimestamp()});
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RootPage(initialIndex: 3)),
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
                  Text('通報する', style: TextStyle(color: Colors.red)),
                ]),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    Navigator.push(
                        context,
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
          _buildInfoBanner(),
          if (blockedAny)
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
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRef
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8845A)),
                  );
                }
                final messages = snapshot.data!.docs;
                final myUid = FirebaseAuth.instance.currentUser?.uid;

                var hasUnreadFromOthers = false;
                for (final doc in messages) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['senderId'] != myUid && data['read'] == false) {
                    hasUnreadFromOthers = true;
                    doc.reference.update({'read': true});
                  }
                }
                if (hasUnreadFromOthers) {
                  _resetMyUnread();
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final data = messages[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == myUid;
                    final isRead = data['read'] as bool? ?? false;
                    final type = data['type'] as String? ?? 'text';
                    final time = _msgTime(data);
                    final timeStr =
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

                    var showDate = i == 0;
                    if (i > 0) {
                      final prev =
                      messages[i - 1].data() as Map<String, dynamic>;
                      final prevTime = _msgTime(prev);
                      showDate = prevTime.year != time.year ||
                          prevTime.month != time.month ||
                          prevTime.day != time.day;
                    }

                    return Column(
                      children: [
                        if (showDate)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              _dayLabel(time),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                        MediaQuery.of(context).size.width *
                                            0.65),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: type == 'location'
                                          ? const Color(0xFF2D6A4F)
                                          : isMe
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
                                            color: isMe || type == 'location'
                                                ? Colors.white
                                                : const Color(0xFF3D2B1F),
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
              },
            ),
          ),
          if (_showPurposeChooser) _buildPurposeChooser(),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !blockedAny,
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
                      color: blockedAny ? Colors.grey : const Color(0xFFE8845A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: (blockedAny
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
        ],
      ),
    );
  }
}