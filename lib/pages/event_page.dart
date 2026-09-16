import '../services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'event_chat_page.dart';
import 'package:flutter/services.dart';
import 'notification_prefs.dart';



const _categories = ['全て', '散歩仲間募集', 'その他'];

class EventPage extends StatefulWidget {
  final String? initialEventId;
  const EventPage({super.key, this.initialEventId});


  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  String _selectedCategory = '全て';
  String _sortBy = '新着';
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  Set<String> _joinedEventIds = {};
  bool _hasAgreedToRules = false;
  int _todayPostCount = 0;


  @override
  void initState() {
    super.initState();
    _loadEvents();
    _checkRulesAgreement();
    _loadTodayPostCount();
    if (widget.initialEventId != null) {
      _openInitialEvent();
    }
  }

  Future<void> _openInitialEvent() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.initialEventId)
        .get();
    if (doc.exists && mounted) {
      final event = doc.data()!;
      event['id'] = doc.id;
      _showEventDetail(context, event);
    }
  }

  Future<void> _loadTodayPostCount() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final posts = await FirebaseFirestore.instance
        .collection('events')
        .where('organizerUid', isEqualTo: myUid)
        .get();
    final count = posts.docs.where((doc) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.isAfter(startOfDay);
    }).length;
    if (mounted) {
      setState(() => _todayPostCount = count);
    }
  }


  Future<void> _checkRulesAgreement() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    final agreed = doc.data()?['agreedToEventRules'] as bool? ?? false;
    if (!agreed && mounted) {
      _showRulesDialog();
    }
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🐾 イベント機能を使う前に',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ドタキャンすると他の参加者に迷惑がかかります'),
            SizedBox(height: 8),
            Text('✅ 2回キャンセルで24時間使用停止'),
            SizedBox(height: 8),
            Text('✅ キャンセルが多いとプロフィールに⚠️マークが表示されます'),
            SizedBox(height: 8),
            Text('✅ キャンセル時は必ず理由を選んでください'),
            SizedBox(height: 8),
            Text('✅ 18歳未満はイベントに参加できません'),
            SizedBox(height: 8),
            Text('✅ 金銭のやり取りは絶対にしないようにしましょう'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final myUid = FirebaseAuth.instance.currentUser?.uid;
                if (myUid != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(myUid)
                      .update({'agreedToEventRules': true});
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8845A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('上記を理解して同意します',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEvent(BuildContext context, Map<String, dynamic> event) {
final titleCtrl = TextEditingController(text: event['title'] ?? '');
final descCtrl = TextEditingController(text: event['description'] ?? '');
final locationCtrl = TextEditingController(text: event['location'] ?? '');
final dateCtrl = TextEditingController(text: event['date'] ?? '');
final maxParticipantsCtrl = TextEditingController(
    text: event['maxParticipants']?.toString() ?? '');

String selectedCategory = event['category'] ?? '散歩仲間募集';
DateTime? selectedEndDate = event['endDate'] != null
    ? (event['endDate'] as Timestamp).toDate()
    : null;



showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (_) => StatefulBuilder(
builder: (context, setModalState) => Padding(
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom),
child: Container(
height: MediaQuery.of(context).size.height * 0.85,
decoration: const BoxDecoration(
color: Color(0xFFFFF8F5),
borderRadius:
BorderRadius.vertical(top: Radius.circular(28))),
child: Column(
children: [
Container(
width: 40, height: 4,
margin: const EdgeInsets.only(top: 12),
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(2)),
),
const SizedBox(height: 16),
const Text('イベントを編集',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
const SizedBox(height: 16),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
  const Text('カテゴリ',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  Row(
    children: ['散歩仲間募集', 'その他'].map((cat) {
      final sel = selectedCategory == cat;
      return GestureDetector(
        onTap: () => setModalState(() => selectedCategory = cat),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? const Color(0xFFE8845A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel ? const Color(0xFFE8845A) : Colors.grey[300]!)),
          child: Text(cat,
              style: TextStyle(
                  fontSize: 13,
                  color: sel ? Colors.white : Colors.grey[700],
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 16),

  const Text('タイトル',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
const SizedBox(height: 8),
  TextField(
    controller: titleCtrl,
    maxLength: 30,
    inputFormatters: [
      LengthLimitingTextInputFormatter(30),
    ],
    decoration: InputDecoration(


    border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14)),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(
color: Color(0xFFE8845A))),
filled: true,
fillColor: Colors.white,
),
),
  const SizedBox(height: 16),
  const Text('日時',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setModalState(() {
            dateCtrl.text = '${picked.year}年${picked.month}月${picked.day}日 ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
          });
        } else {
          setModalState(() {
            dateCtrl.text = '${picked.year}年${picked.month}月${picked.day}日';
          });
        }
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: Color(0xFFE8845A)),
          const SizedBox(width: 12),
          Text(
            dateCtrl.text.isEmpty ? '日付を選択してください' : dateCtrl.text,
            style: TextStyle(
              color: dateCtrl.text.isEmpty ? Colors.grey : const Color(0xFF3D2B1F),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  ),
  const SizedBox(height: 16),
  const Text('終了日',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedEndDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        setModalState(() {
          selectedEndDate = picked;
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_rounded, color: Color(0xFF2D6A4F)),
          const SizedBox(width: 12),
          Text(
            selectedEndDate == null
                ? '終了日を選択してください'
                : '${selectedEndDate!.year}年${selectedEndDate!.month}月${selectedEndDate!.day}日',
            style: TextStyle(
              color: selectedEndDate == null ? Colors.grey : const Color(0xFF3D2B1F),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  ),

  const SizedBox(height: 16),
  const Text('場所',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  TextField(
    controller: locationCtrl,
    maxLength: 50,
    inputFormatters: [
      LengthLimitingTextInputFormatter(50),
    ],
    decoration: InputDecoration(

    border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFFE8845A))),
      filled: true,
      fillColor: Colors.white,
    ),
  ),
  const SizedBox(height: 16),
  const Text('参加人数の上限（任意）',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  TextField(
    controller: maxParticipantsCtrl,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        final number = int.tryParse(newValue.text);
        if (number == null || number > 50) return oldValue;
        return newValue;
      }),
    ],

    decoration: InputDecoration(
      hintText: '例：10（設定しない場合は空欄）',
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8845A))),
      filled: true,
      fillColor: Colors.white,
    ),
  ),

  const SizedBox(height: 16),
  const Text('詳細',
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  TextField(
    controller: descCtrl,
    maxLines: 4,
    maxLength: 300,
    inputFormatters: [
      LengthLimitingTextInputFormatter(300),
    ],
    decoration: InputDecoration(

    border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFFE8845A))),
      filled: true,
      fillColor: Colors.white,
    ),
  ),
  const SizedBox(height: 24),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        if (titleCtrl.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('タイトルを入力してください'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await FirebaseFirestore.instance
            .collection('events')
            .doc(event['id'])
            .update({
          'title': titleCtrl.text,
          'description': descCtrl.text,
          'location': locationCtrl.text,
          'date': dateCtrl.text,
          'category': selectedCategory,
          if (selectedEndDate != null) 'endDate': Timestamp.fromDate(selectedEndDate!),
          'maxParticipants': maxParticipantsCtrl.text.isEmpty
              ? null
              : int.tryParse(maxParticipantsCtrl.text),
        });
        // 参加者全員に変更通知
        final participants = await FirebaseFirestore.instance
            .collection('events')
            .doc(event['id'])
            .collection('participants')
            .get();

        for (final p in participants.docs) {
          if (p.id == event['organizerUid']) continue;
          if (!await shouldSendNotification(p.id, 'イベント関連')) continue;
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(p.id)
              .collection('items')
              .add({
            'type': 'eventUpdate',
            'emoji': '📝',
            'title': 'イベント内容が変更されました',
            'desc': '「${titleCtrl.text}」の内容が変更されました。確認してください。',
            'eventId': event['id'],
            'fromUid': event['organizerUid'],
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }



        if (context.mounted) {
          Navigator.pop(context);
          _loadEvents();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新しました🐾'),
              backgroundColor: Color(0xFFE8845A),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8845A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(
              vertical: 16)),
      child: const Text('更新する',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold)),
    ),
  ),
],
),
),
),
],
),
),
),
),
);
}


Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      final myUid = FirebaseAuth.instance.currentUser?.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      final events = snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((event) {
        final endDate = event['endDate'];
        if (endDate == null) return true;
        final end = (endDate as Timestamp).toDate();
        return end.isAfter(now);
      })
          .toList();

      final joined = <String>{};
      if (myUid != null) {
        for (final event in events) {
          final participantDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(event['id'])
              .collection('participants')
              .doc(myUid)
              .get();
          if (participantDoc.exists) {
            joined.add(event['id']);
          }
        }
      }

      if (mounted) {
        setState(() {
          _events = events;
          _joinedEventIds = joined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _joinEvent(String eventId) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    if (_joinedEventIds.contains(eventId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('すでに参加済みです🐾'),
            backgroundColor: Colors.grey),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();
      final cancelCount = userDoc.data()?['cancelCount'] as int? ?? 0;
      if (cancelCount >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('キャンセルが多いためイベントに参加できません。運営にお問い合わせください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (cancelCount == 2) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⚠️ 注意'),
            content: const Text('あと1回キャンセルすると24時間イベント機能が使えなくなります。\n本当に参加しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('やめる', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845A),
                    foregroundColor: Colors.white),
                child: const Text('参加する'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
// 追放チェック
      final eventDocForBan = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      final bannedUsers = List<String>.from(
          eventDocForBan.data()?['bannedUsers'] ?? []);
      if (bannedUsers.contains(myUid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このイベントには参加できません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }


      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      final maxParticipants = eventDoc.data()?['maxParticipants'] as int?;
      final currentCount = eventDoc.data()?['participantCount'] as int? ?? 0;
      if (maxParticipants != null && currentCount >= maxParticipants) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('参加者が上限に達しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(eventId);

      await eventRef
          .collection('participants')
          .doc(myUid)
          .set({'joinedAt': FieldValue.serverTimestamp()});

      await eventRef.update({
        'participantCount': FieldValue.increment(1),
      });

      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();
      final myName = myDoc.data()?['name'] ?? '';

      final organizerUid = _events
          .firstWhere((e) => e['id'] == eventId)['organizerUid'] as String?;

      if (organizerUid != null && organizerUid != myUid &&
          await shouldSendNotification(organizerUid, 'イベント関連')) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(organizerUid)
            .collection('items')
            .add({
          'type': 'event',
          'emoji': '📅',
          'title': 'イベントに参加者が来ました！',
          'desc': '${myName}さんが参加しました',
          'eventId': eventId,
          'fromUid': myUid,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add({
        'text': '${myName}さんが参加しました🐾',
        'senderUid': 'system',
        'senderName': 'システム',
        'senderImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isSystem': true,
      });

      setState(() {
        _joinedEventIds.add(eventId);
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          _events[index]['participantCount'] =
              (_events[index]['participantCount'] ?? 0) + 1;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('参加しました！🐾'),
            backgroundColor: Color(0xFFE8845A),
          ),
        );
      }
    } catch (e) {
      print('🔥 joinEvent エラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('エラー: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelEvent(String eventId, {String? reason}) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(myUid)
          .delete();

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({
        'participantCount': FieldValue.increment(-1),
      });
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      final organizerUid = eventDoc.data()?['organizerUid'] as String?;
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();
      final myName = myDoc.data()?['name'] ?? '';

      if (organizerUid != null && organizerUid != myUid &&
          await shouldSendNotification(organizerUid, 'イベント関連')) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(organizerUid)
            .collection('items')
            .add({
          'type': 'eventCancel',
          'emoji': '😢',
          'title': 'イベント参加がキャンセルされました',
          'desc': '$myNameさんが参加をキャンセルしました',
          'eventId': eventId,
          'fromUid': myUid,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .update({
        'cancelCount': FieldValue.increment(1),
      });
      if (reason != null) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('cancellations')
            .add({
          'uid': myUid,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }


      setState(() {
        _joinedEventIds.remove(eventId);
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          final current = _events[index]['participantCount'] as int? ?? 0;
          _events[index]['participantCount'] = current > 0 ? current - 1 : 0;
        }
      });


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('参加をキャンセルしました'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('エラーが発生しました'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _postEvent(String title, String description,
      String category, String date, String location, int? maxParticipants, DateTime? endDate, String? imageUrl) async {

    if (title.isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    // 1日2回まで投稿制限
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);


    final todayPosts = await FirebaseFirestore.instance
        .collection('events')
        .where('organizerUid', isEqualTo: myUid)
        .get();

    final todayCount = todayPosts.docs.where((doc) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.isAfter(startOfDay);
    }).length;

    if (todayCount >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1日2回までしか投稿できません。明日また投稿してください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }


    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    final myName = myDoc.data()?['name'] ?? '';

    await FirebaseFirestore.instance.collection('events').add({
      'title': title,
      'description': description,
      'category': category,
      'date': date,
      'location': location,
      'emoji': '🐾',
      'isOfficial': false,
      'organizerName': myName,
      'organizerUid': myUid,
      'participantCount': 0,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),



    });

    _loadEvents();
    _loadTodayPostCount();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _selectedCategory == '全て'
        ? List<Map<String, dynamic>>.from(_events)
        : _events.where((e) => e['category'] == _selectedCategory).toList();

    if (_sortBy == '人気') {
      list.sort((a, b) => ((b['participantCount'] ?? 0) as int)
          .compareTo((a['participantCount'] ?? 0) as int));
    } else {
      list.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('イベント掲示板 📋',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => _showRulesDialog(),
              icon: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF2D6A4F), size: 26),
            ),
            IconButton(
              onPressed: _todayPostCount >= 2 ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('1日2回までしか投稿できません。明日また投稿してください。'),
                    backgroundColor: Colors.red,
                  ),
                );
              } : () => _showPostEvent(context),
              icon: Icon(Icons.add_circle_rounded,
                  color: _todayPostCount >= 2 ? Colors.grey : const Color(0xFFE8845A),
                  size: 28),
            ),
          ],

        ),
        body: Column(
          children: [
          SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: _categories.map((cat) {
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8845A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFE8845A)
                              : Colors.grey[300]!)),
                  child: Text(cat,
                      style: TextStyle(
                          fontSize: 13,
                          color: sel ? Colors.white : Colors.grey[700],
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: ['新着', '人気'].map((sort) {
                  final sel = _sortBy == sort;
                  return GestureDetector(
                    onTap: () => setState(() => _sortBy = sort),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          color: sel ? const Color(0xFF2D6A4F) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? const Color(0xFF2D6A4F)
                                  : Colors.grey[300]!)),
                      child: Text(sort,
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.white : Colors.grey[700],
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(

            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE8845A)))
                : _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋',
                      style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('イベントがありません',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 8),
                  Text('右上の＋から投稿してみよう！',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final event = _filtered[i];
                  final isEmergency =
                      event['category'] == '緊急支援';
                  final isWalk =
                      event['category'] == '散歩仲間募集';
                  final isJoined =
                  _joinedEventIds.contains(event['id']);
                  return GestureDetector(
                    onTap: () =>
                        _showEventDetail(context, event),
                    onLongPress: () async {
                      final myUid = FirebaseAuth
                          .instance.currentUser?.uid;
                      if (event['organizerUid'] != myUid)
                        return;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('イベントを削除しますか？'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('キャンセル',
                                  style: TextStyle(
                                      color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditEvent(context, event);
                              },
                              child: const Text('編集',
                                  style: TextStyle(color: Color(0xFFE8845A))),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final participants = await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event['id'])
                                    .collection('participants')
                                    .get();
                                for (final p in participants.docs) {
                                  if (p.id == event['organizerUid']) continue;
                                  if (!await shouldSendNotification(p.id, 'イベント関連')) continue;
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .doc(p.id)
                                      .collection('items')
                                      .add({
                                    'type': 'eventDelete',
                                    'emoji': '🗑️',
                                    'title': 'イベントが削除されました',
                                    'desc': '「${event['title']}」は企画者により削除されました',
                                    'fromUid': event['organizerUid'],
                                    'read': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                }

                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event['id'])
                                    .delete();
                                _loadEvents();

                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('削除しました'),
                                      backgroundColor: Colors.grey,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              child: const Text('削除'),
                            ),
                          ],
                        ),
                      );
                    },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isEmergency
                              ? Border.all(color: Colors.red[300]!)
                              : isWalk
                              ? Border.all(
                              color: const Color(0xFF2D6A4F)
                                  .withOpacity(0.3))
                              : null,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event['imageUrl'] != null && (event['imageUrl'] as String).isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    event['imageUrl'] as String,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8845A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text('🐾', style: TextStyle(fontSize: 36)),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (event['isOfficial'] == true) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF2D6A4F),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Text('公式',
                                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (event['organizerUid'] == FirebaseAuth.instance.currentUser?.uid) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFE8845A),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Text('自分の投稿',
                                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (isJoined) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF2D6A4F),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Text('参加済み',
                                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(event['title'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3D2B1F)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(event['organizerName'] as String? ?? '',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(event['date'] as String? ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(event['location'] as String? ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const Icon(Icons.people_rounded, size: 12, color: Color(0xFFE8845A)),
                                        const SizedBox(width: 4),
                                        Text('${event['participantCount'] ?? 0}人',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFE8845A),
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                  },
            ),
            ),
          ],
        ),
    );
  }



  void _showEventDetail(BuildContext context, Map<String, dynamic> event) {
    final isJoined = _joinedEventIds.contains(event['id']);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
                color: Color(0xFFFFF8F5),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              children: [
              Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event['imageUrl'] != null && (event['imageUrl'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            event['imageUrl'] as String,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (event['imageUrl'] == null || (event['imageUrl'] as String).isEmpty) ...[
                          Text(event['emoji'] as String? ?? '🐾',
                              style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 12),
                        ],


                        Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3D2B1F))),
                      Text(event['organizerName'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600])),
                    ],
                  ),
                ),
                ],
              ),
              const Divider(height: 32),
              _EventRow(Icons.calendar_today_rounded,
                  event['date'] as String? ?? ''),
              const SizedBox(height: 8),
              _EventRow(Icons.location_on_rounded,
                  event['location'] as String? ?? ''),
              const SizedBox(height: 8),
                      _EventRow(Icons.people_rounded,
                          event['maxParticipants'] != null
                              ? '${event['participantCount'] ?? 0}/${event['maxParticipants']}人'
                              : '${event['participantCount'] ?? 0}人が参加'),
                      const SizedBox(height: 8),
                      if (event['endDate'] != null)
                        _EventRow(Icons.event_busy_rounded,
                            '終了日：${(event['endDate'] as Timestamp).toDate().year}年${(event['endDate'] as Timestamp).toDate().month}月${(event['endDate'] as Timestamp).toDate().day}日'),


                      const SizedBox(height: 16),
              const Text('参加者',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('events')
                    .doc(event['id'])
                    .collection('participants')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(
                        color: Color(0xFFE8845A));
                  }
                  final participants = snapshot.data!.docs;
                  if (participants.isEmpty) {
                    return Text('まだ参加者がいません',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]));
                  }
                  return Column(
                    children: participants
                        .map((p) => FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(p.id)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData)
                          return const SizedBox();
                        final userData = userSnap.data!
                            .data() as Map<String, dynamic>?;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(uid: p.id),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: userData?['profileImageUrl'] != null &&
                                          (userData!['profileImageUrl'] as String).isNotEmpty
                                          ? Image.network(
                                          userData['profileImageUrl'],
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover)
                                          : Container(
                                          width: 36,
                                          height: 36,
                                          color: const Color(0xFFFFE0D0),
                                          child: Center(
                                            child: Text(
                                              (userData?['name'] ?? '🐾')
                                                  .toString()
                                                  .isNotEmpty
                                                  ? userData!['name'][0]
                                                  : '🐾',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFFE8845A),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(userData?['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 14, color: Color(0xFF3D2B1F))),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (event['organizerUid'] ==
                                  FirebaseAuth.instance.currentUser?.uid &&
                                  p.id != FirebaseAuth.instance.currentUser?.uid)
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                        title: const Text('追放しますか？'),
                                        content: Text(
                                            '${userData?['name']}さんをグループから追放します。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('キャンセル',
                                                style: TextStyle(color: Colors.grey)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12))),
                                            child: const Text('追放する'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                    final eventId = event['id'] as String;
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(eventId)
                                        .collection('participants')
                                        .doc(p.id)
                                        .delete();
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(eventId)
                                        .update({
                                      'participantCount': FieldValue.increment(-1),
                                      'bannedUsers': FieldValue.arrayUnion([p.id]),
                                    });

                                    if (await shouldSendNotification(p.id, 'イベント関連')) {
                                      await FirebaseFirestore.instance
                                          .collection('notifications')
                                          .doc(p.id)
                                          .collection('items')
                                          .add({
                                        'type': 'eventRemoved',
                                        'emoji': '🚫',
                                        'title': 'イベントから追放されました',
                                        'desc': '${event['title']}から追放されました',
                                        'read': false,
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('追放しました'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('追放',
                                      style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        );

                      },
                    ))
                        .toList(),
                  );
                },
              ),
              const Divider(height: 32),
              const Text('詳細',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 8),
              Text(event['description'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.7)),
              const SizedBox(height: 24),
                      // 参加するボタンの上に追加
                      Builder(
                        builder: (context) {
                          final isOrganizer = event['organizerUid'] ==
                              FirebaseAuth.instance.currentUser?.uid;
                          final endDate = event['endDate'] as Timestamp?;
                          final isExpired = endDate != null &&
                              endDate.toDate().isBefore(DateTime.now());
                          final bannedUsers = List<String>.from(
                              event['bannedUsers'] ?? []);
                          final isBanned = bannedUsers.contains(
                              FirebaseAuth.instance.currentUser?.uid);

                          return Column(
                            children: [
                              if (!isJoined && !isOrganizer && !isExpired && !isBanned)

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, color: Color(0xFF2D6A4F), size: 16),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '参加するとグループチャットに参加できます🐾',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (isJoined || isOrganizer) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventChatPage(
                                            eventId: event['id'],
                                            eventTitle: event['title'] as String? ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                                    label: const Text('グループチャット',
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2D6A4F),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(vertical: 16)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isOrganizer || isExpired ? null : () async {
                                    final myUid = FirebaseAuth.instance.currentUser?.uid;
                                    if (myUid == null) return;
                                    final myDoc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(myUid)
                                        .get();
                                    final age = myDoc.data()?['age'] as int? ?? 0;
                                    if (age < 18) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('18歳未満はイベントに参加できません'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    if (isJoined) {
                                      final reason = await showDialog<String>(
                                        context: context,
                                        builder: (_) {
                                          String? selected;
                                          return StatefulBuilder(
                                            builder: (context, setState) => AlertDialog(
                                              title: const Text('キャンセル理由を選んでください'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('キャンセルすると他の参加者に迷惑がかかる場合があります。',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                  const SizedBox(height: 12),
                                                  ...['急病・体調不良', '仕事・学校の都合', '家族の都合', 'その他'].map((r) =>
                                                      RadioListTile<String>(
                                                        title: Text(r),
                                                        value: r,
                                                        groupValue: selected,
                                                        onChanged: (v) => setState(() => selected = v),
                                                        activeColor: const Color(0xFFE8845A),
                                                      ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, null),
                                                  child: const Text('戻る', style: TextStyle(color: Colors.grey)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white),
                                                  child: const Text('キャンセルする'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      final confirm = reason != null;

                                      if (confirm == true) {
                                        Navigator.pop(context);
                                        _cancelEvent(event['id'], reason: reason);
                                      }
                                    } else {
                                      Navigator.pop(context);
                                      _joinEvent(event['id']);
                                    }

                                  },

                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: isOrganizer || isExpired
                                          ? Colors.grey
                                          : isJoined
                                          ? Colors.grey
                                          : const Color(0xFFE8845A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: Text(
                                      isOrganizer ? '自分のイベントです' :
                                      isExpired ? '終了したイベントです' :
                                      isJoined ? 'キャンセルする' : '参加する🐾',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final myUid =
                                FirebaseAuth.instance.currentUser?.uid;
                            final organizerUid =
                            event['organizerUid'] as String?;
                            if (organizerUid == null) return;
                            if (organizerUid == myUid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('自分のイベントです'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfilePage(uid: organizerUid),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_rounded,
                              color: Color(0xFFE8845A)),
                          label: const Text('企画者のプロフィールを見る',
                              style: TextStyle(color: Color(0xFFE8845A))),
                          style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                  color: Color(0xFFE8845A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () async {
                            final myUid = FirebaseAuth.instance.currentUser?.uid;
                            if (myUid == null) return;
                            String? selectedReason;
                            final commentCtrl = TextEditingController();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => StatefulBuilder(
                                builder: (context, setDialogState) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Text('通報する'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('理由を選んでください',
                                          style: TextStyle(fontSize: 13)),
                                      const SizedBox(height: 8),
                                      ...['スパム', '不適切なコンテンツ', '詐欺・金銭トラブル', '危険な内容', 'その他']
                                          .map((reason) => RadioListTile<String>(
                                        title: Text(reason,
                                            style: const TextStyle(fontSize: 13)),
                                        value: reason,
                                        groupValue: selectedReason,
                                        activeColor: const Color(0xFFE8845A),
                                        onChanged: (v) =>
                                            setDialogState(() => selectedReason = v),
                                      )),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: commentCtrl,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'コメント（任意）',
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide:
                                              const BorderSide(color: Color(0xFFE8845A))),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル',
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: selectedReason == null
                                          ? null
                                          : () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12))),
                                      child: const Text('通報する'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm != true || selectedReason == null) return;
                            await FirebaseFirestore.instance
                                .collection('reports')
                                .add({
                              'type': 'event',
                              'eventId': event['id'],
                              'reporterId': myUid,
                              'reason': selectedReason,
                              'comment': commentCtrl.text,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('通報しました。ご報告ありがとうございます。'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          },

                          icon: const Icon(Icons.flag_rounded,
                              color: Colors.red, size: 16),
                          label: const Text('このイベントを通報する',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange[200]!)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security_rounded,
                                    color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Text('安全に参加するために',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text('・初めて会う場合は必ず人が多い公共の場所を選ぼう',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),
                            SizedBox(height: 4),
                            Text('・住所・電話番号などの個人情報は教えないようにしよう',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),
                            SizedBox(height: 4),
                            Text('・不安を感じたらすぐに運営に報告しよう',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),
                            SizedBox(height: 4),
                            Text('・18歳未満の方はイベントに参加できません',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),
                            SizedBox(height: 4),
                            Text('・金銭のやり取りは絶対にしないようにしよう',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),

                          ],
                        ),
                      ),
                    ],
                ),
              ),
            ),
              ],
            ),
        ),
    );
  }
  void _showPostEvent(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    DateTime? selectedDate;
    DateTime? selectedEndDate;
    String selectedCategory = '散歩仲間募集';
    String? selectedImageUrl;
    bool isUploadingImage = false;
    final locationCtrl = TextEditingController();
    final maxParticipantsCtrl = TextEditingController();


    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StatefulBuilder(
            builder: (context, setModalState) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFF8F5),
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28))),
                    child: Column(
                      children: [
                      Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('イベントを投稿',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3D2B1F))),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE8845A)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Color(0xFFE8845A), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  '🐾 動物好きのイベントを投稿しよう！\n個人情報・金銭のやり取りは書かないようにしましょう。\n1日2回まで投稿できます。',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFE8845A))),
                            ),
                          ],
                        ),
                      ),
                              const Text('カテゴリ',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              Row(
                                children: ['散歩仲間募集', 'その他'].map((cat) {
                                  final sel = selectedCategory == cat;
                                  return GestureDetector(
                                    onTap: () => setModalState(() => selectedCategory = cat),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                          color: sel ? const Color(0xFFE8845A) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: sel ? const Color(0xFFE8845A) : Colors.grey[300]!)),
                                      child: Text(cat,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: sel ? Colors.white : Colors.grey[700],
                                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const Text('画像（任意）',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  setModalState(() => isUploadingImage = true);
                                  final url = await CloudinaryService.pickAndUploadImage();
                                  setModalState(() {
                                    if (url != null) selectedImageUrl = url;
                                    isUploadingImage = false;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: isUploadingImage
                                      ? const Center(
                                      child: CircularProgressIndicator(color: Color(0xFFE8845A)))
                                      : selectedImageUrl != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(selectedImageUrl!,
                                        width: double.infinity, height: 150, fit: BoxFit.cover),
                                  )
                                      : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_rounded,
                                            color: Color(0xFFE8845A), size: 32),
                                        SizedBox(height: 8),
                                        Text('画像を選択', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const SizedBox(height: 16),
                              const SizedBox(height: 16),
                      const Text('タイトル',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                              TextField(
                                controller: titleCtrl,
                                maxLength: 30,
                                decoration: InputDecoration(
                                  hintText: '例：代々木公園で散歩仲間募集！',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE8845A))),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),
                      const Text('日時',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setModalState(() {
                                        selectedDate = picked;
                                        dateCtrl.text = '${picked.year}年${picked.month}月${picked.day}日 ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    } else {
                                      setModalState(() {
                                        selectedDate = picked;
                                        dateCtrl.text = '${picked.year}年${picked.month}月${picked.day}日';
                                      });
                                    }
                                  }
                                },

                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: Color(0xFFE8845A)),
                                      const SizedBox(width: 12),
                                      Text(
                                        dateCtrl.text.isEmpty ? '日付を選択してください' : dateCtrl.text,
                                        style: TextStyle(
                                          color: dateCtrl.text.isEmpty ? Colors.grey : const Color(0xFF3D2B1F),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('終了日（必須）',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),

                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: selectedDate ?? DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedEndDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_busy_rounded, color: Color(0xFF2D6A4F)),
                                      const SizedBox(width: 12),
                                      Text(
                                        selectedEndDate == null
                                            ? '終了日を選択してください'
                                            : '${selectedEndDate!.year}年${selectedEndDate!.month}月${selectedEndDate!.day}日',
                                        style: TextStyle(
                                          color: selectedEndDate == null ? Colors.grey : const Color(0xFF3D2B1F),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),


                              const SizedBox(height: 16),
                              const Text('場所',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: locationCtrl,
                                maxLength: 50,
                                decoration: InputDecoration(
                                  hintText: '例：東京都世田谷区',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE8845A))),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Text('参加人数の上限（任意）',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: maxParticipantsCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    if (newValue.text.isEmpty) return newValue;
                                    final number = int.tryParse(newValue.text);
                                    if (number == null || number > 50) return oldValue;
                                    return newValue;
                                  }),
                                ],

                                decoration: InputDecoration(
                                  hintText: '例：10（設定しない場合は空欄）',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE8845A))),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Text('詳細',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descCtrl,
                                maxLines: 4,
                                maxLength: 300,
                                decoration: InputDecoration(
                                  hintText: '参加条件や詳細を書いてください',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE8845A))),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (titleCtrl.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('タイトルを入力してください'),
                                        backgroundColor: Colors.red,
                                      ));
                                      return;
                                    }
                                    if (selectedEndDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('終了日を設定してください'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    await _postEvent(
                                      titleCtrl.text,
                                      descCtrl.text,
                                      selectedCategory,
                                      dateCtrl.text,
                                      locationCtrl.text,
                                      maxParticipantsCtrl.text.isEmpty
                                          ? null
                                          : int.tryParse(maxParticipantsCtrl.text),
                                      selectedEndDate,
                                      selectedImageUrl,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('投稿しました！🐾'),
                                        backgroundColor: Color(0xFFE8845A),
                                      ));
                                    }
                                  },

                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE8845A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16)),
                                  child: const Text('投稿する',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                      ],
                    ),
                ),
            ),
        ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EventRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE8845A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
      ],
    );
  }
}
