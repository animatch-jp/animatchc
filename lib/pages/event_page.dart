import '../services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'event_chat_page.dart';
import 'notification_prefs.dart';

const _categories = ['全て', '散歩仲間募集', 'その他'];
const _maxPostsPerDay = 2; // 1日に投稿できる回数
const _maxActiveEvents = 3; // 公開中に持てる件数
const _orange = Color(0xFFE8845A);
const _green = Color(0xFF2D6A4F);
const _brown = Color(0xFF3D2B1F);
const _cream = Color(0xFFFFF8F5);

// ───────────── 共通で使う小さな部品・関数 ─────────────

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// 終了日は「その日の終わりまで」公開する
DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

String _dateLabel(DateTime d) => '${d.year}年${d.month}月${d.day}日';

String _todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

bool _isExpired(Map<String, dynamic> e) {
  final end = e['endDate'];
  if (end is! Timestamp) return false;
  return end.toDate().isBefore(DateTime.now());
}

final _maxParticipantsFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.tryParse(newValue.text);
    if (number == null || number > 50) return oldValue;
    return newValue;
  }),
];

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.grey[300]!),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: _orange),
  ),
  filled: true,
  fillColor: Colors.white,
);

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: _brown)),
);

Widget _badge(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration:
  BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
  child: Text(text,
      style: const TextStyle(
          fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
);

Widget _pill(String text, bool selected, Color color, VoidCallback onTap,
    {double vPad = 8, double fontSize = 13}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
      decoration: BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : Colors.grey[300]!),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: fontSize,
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
    ),
  );
}

Widget _categoryChips(String selected, ValueChanged<String> onSelect) {
  return Row(
    children: ['散歩仲間募集', 'その他']
        .map((cat) => _pill(cat, selected == cat, _orange, () => onSelect(cat)))
        .toList(),
  );
}

Widget _pickerBox({
  required IconData icon,
  required Color iconColor,
  required String text,
  required bool isEmpty,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: isEmpty ? Colors.grey : _brown, fontSize: 15)),
          ),
        ],
      ),
    ),
  );
}

Widget _infoBox(String text, Color color, {IconData icon = Icons.info_outline_rounded}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    ),
  );
}

Widget _formErrorBox(String? message) {
  if (message == null) return const SizedBox.shrink();
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Text(message,
        style: const TextStyle(fontSize: 13, color: Colors.red)),
  );
}

Widget _primaryButton(String text, VoidCallback? onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _sheetFrame(BuildContext context,
    {required String title, required Widget body}) {
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: _brown)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: body,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickedDateTime {
  final DateTime date;
  final String text;
  _PickedDateTime(this.date, this.text);
}

// 日付 → 時刻の順に選ぶ（時刻は選ばなくてもOK）
Future<_PickedDateTime?> _pickEventDateTime(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (picked == null || !context.mounted) return null;
  final time =
  await showTimePicker(context: context, initialTime: TimeOfDay.now());
  final base = _dateLabel(picked);
  final text = time == null
      ? base
      : '$base ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  return _PickedDateTime(picked, text);
}

// 終了日を選ぶ。すでに過ぎた日付が入っていても落ちないようにする
Future<DateTime?> _pickEndDate(BuildContext context,
    {DateTime? current, DateTime? minDate}) {
  final now = DateTime.now();
  final first = (minDate != null && minDate.isAfter(now)) ? minDate : now;
  var initial = current ?? first;
  if (_dateOnly(initial).isBefore(_dateOnly(first))) initial = first;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: now.add(const Duration(days: 365)),
  );
}

// ───────────── 画面本体 ─────────────

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
  int _todayPostCount = 0; // 今日の投稿回数（削除しても減らない）
  int _activePostCount = 0; // 自分の公開中イベントの件数
  int? _myAge;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _checkRulesAgreement();
    _loadMyPostCounts();
    if (widget.initialEventId != null) {
      _openInitialEvent();
    }
  }

  void _showSnack(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
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

  Future<int> _countActiveEvents(String uid, {String? excludeId}) async {
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .where('organizerUid', isEqualTo: uid)
        .get();
    final now = DateTime.now();
    return snap.docs.where((d) {
      if (d.id == excludeId) return false;
      final end = d.data()['endDate'];
      if (end is! Timestamp) return true;
      return end.toDate().isAfter(now);
    }).length;
  }

  Future<void> _loadMyPostCounts() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();
      final data = userDoc.data();
      final todayCount = data?['eventPostDate'] == _todayKey()
          ? (data?['eventPostCount'] as int? ?? 0)
          : 0;
      final activeCount = await _countActiveEvents(myUid);
      if (mounted) {
        setState(() {
          _todayPostCount = todayCount;
          _activePostCount = activeCount;
        });
      }
    } catch (e) {
      debugPrint('loadMyPostCounts エラー: $e');
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
    if (mounted) setState(() => _myAge = doc.data()?['age'] as int?);
    if (!agreed && mounted) {
      _showRulesDialog();
    }
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🐾 イベント機能を使う前に',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ドタキャンすると他の参加者に迷惑がかかります'),
            SizedBox(height: 8),
            Text('✅ 2回キャンセルすると、24時間イベントに参加できません'),
            SizedBox(height: 8),
            Text('✅ 3回キャンセルすると、イベントに参加できなくなります'),
            SizedBox(height: 8),
            Text('✅ キャンセルが多いとプロフィールに⚠️マークが表示されます'),
            SizedBox(height: 8),
            Text('✅ キャンセル時は必ず理由を選んでください'),
            SizedBox(height: 8),
            Text('✅ 18歳未満はイベントに参加・投稿できません'),
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
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
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

  // ───────────── データの読み込み ─────────────

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
        // 自分が企画したイベントは、終了していても表示する（終了日を延ばせるように）
        if (myUid != null && event['organizerUid'] == myUid) return true;
        final endDate = event['endDate'];
        if (endDate == null) return true;
        return (endDate as Timestamp).toDate().isAfter(now);
      }).toList();

      final joined = <String>{};
      if (myUid != null) {
        final checks = await Future.wait(events.map((e) => FirebaseFirestore
            .instance
            .collection('events')
            .doc(e['id'] as String)
            .collection('participants')
            .doc(myUid)
            .get()));
        for (var i = 0; i < events.length; i++) {
          if (checks[i].exists) joined.add(events[i]['id'] as String);
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

  // ───────────── 参加・キャンセル ─────────────

  Future<void> _joinEvent(String eventId) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    if (_joinedEventIds.contains(eventId)) {
      _showSnack('すでに参加済みです🐾', color: Colors.grey);
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(myUid).get();
      final cancelCount = userDoc.data()?['cancelCount'] as int? ?? 0;
      if (cancelCount >= 3) {
        _showSnack('キャンセルが多いためイベントに参加できません。運営にお問い合わせください。');
        return;
      }
      // 2回キャンセルしたあとの、24時間の停止
      final suspendedUntil = userDoc.data()?['eventSuspendedUntil'];
      if (suspendedUntil is Timestamp &&
          suspendedUntil.toDate().isAfter(DateTime.now())) {
        final until = suspendedUntil.toDate();
        final mm = until.minute.toString().padLeft(2, '0');
        _showSnack(
            'キャンセルが続いたため、${until.month}月${until.day}日 ${until.hour}:${mm}までイベントに参加できません');
        return;
      }
      // 「あと1回で…」の注意
      final String? warning = cancelCount == 1
          ? 'あと1回キャンセルすると、24時間イベントに参加できなくなります。\n本当に参加しますか？'
          : cancelCount == 2
          ? 'あと1回キャンセルすると、イベントに参加できなくなります。\n本当に参加しますか？'
          : null;
      if (warning != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('⚠️ 注意'),
            content: Text(warning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('やめる', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _orange, foregroundColor: Colors.white),
                child: const Text('参加する'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }

      final eventRef = db.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();
      final eventData = eventDoc.data();
      if (eventData == null) {
        _showSnack('イベントが見つかりません');
        return;
      }
      if (_isExpired(eventData)) {
        _showSnack('このイベントは終了しています');
        return;
      }
      final banned = List<String>.from(eventData['bannedUsers'] ?? []);
      if (banned.contains(myUid)) {
        _showSnack('このイベントには参加できません');
        return;
      }
      final maxParticipants = eventData['maxParticipants'] as int?;
      final currentCount = eventData['participantCount'] as int? ?? 0;
      if (maxParticipants != null && currentCount >= maxParticipants) {
        _showSnack('参加者が上限に達しました');
        return;
      }

      await eventRef
          .collection('participants')
          .doc(myUid)
          .set({'joinedAt': FieldValue.serverTimestamp()});
      await eventRef.update({'participantCount': FieldValue.increment(1)});

      final myName = userDoc.data()?['name'] ?? '';
      final organizerUid = eventData['organizerUid'] as String?;

      if (organizerUid != null &&
          organizerUid != myUid &&
          await shouldSendNotification(organizerUid, 'イベント関連')) {
        await db
            .collection('notifications')
            .doc(organizerUid)
            .collection('items')
            .add({
          'type': 'event',
          'emoji': '📅',
          'title': 'イベントに参加者が来ました！',
          'desc': '$myNameさんが参加しました',
          'eventId': eventId,
          'fromUid': myUid,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await eventRef.collection('messages').add({
        'text': '$myNameさんが参加しました🐾',
        'senderUid': 'system',
        'senderName': 'システム',
        'senderImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isSystem': true,
      });

      if (mounted) {
        setState(() {
          _joinedEventIds.add(eventId);
          final index = _events.indexWhere((e) => e['id'] == eventId);
          if (index != -1) {
            _events[index]['participantCount'] =
                (_events[index]['participantCount'] ?? 0) + 1;
          }
        });
      }
      _showSnack('参加しました！🐾', color: _orange);
    } catch (e) {
      debugPrint('🔥 joinEvent エラー: $e');
      _showSnack('エラー: $e');
    }
  }

  Future<void> _cancelEvent(String eventId, {String? reason}) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final eventRef = db.collection('events').doc(eventId);

      await eventRef.collection('participants').doc(myUid).delete();
      await eventRef.update({'participantCount': FieldValue.increment(-1)});

      final eventDoc = await eventRef.get();
      final organizerUid = eventDoc.data()?['organizerUid'] as String?;
      final myDoc = await db.collection('users').doc(myUid).get();
      final myName = myDoc.data()?['name'] ?? '';

      if (organizerUid != null &&
          organizerUid != myUid &&
          await shouldSendNotification(organizerUid, 'イベント関連')) {
        await db
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

      // 2回目のキャンセルで、24時間イベントに参加できなくする
      final newCancelCount = (myDoc.data()?['cancelCount'] as int? ?? 0) + 1;
      await db.collection('users').doc(myUid).update({
        'cancelCount': FieldValue.increment(1),
        if (newCancelCount == 2)
          'eventSuspendedUntil': Timestamp.fromDate(
              DateTime.now().add(const Duration(hours: 24))),
      });

      if (reason != null) {
        await eventRef.collection('cancellations').add({
          'uid': myUid,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _joinedEventIds.remove(eventId);
          final index = _events.indexWhere((e) => e['id'] == eventId);
          if (index != -1) {
            final current = _events[index]['participantCount'] as int? ?? 0;
            _events[index]['participantCount'] = current > 0 ? current - 1 : 0;
          }
        });
      }
      if (newCancelCount == 2) {
        _showSnack('参加をキャンセルしました。24時間、イベントに参加できません',
            color: Colors.grey);
      } else if (newCancelCount >= 3) {
        _showSnack('参加をキャンセルしました。今後はイベントに参加できません。運営にお問い合わせください',
            color: Colors.grey);
      } else {
        _showSnack('参加をキャンセルしました', color: Colors.grey);
      }
    } catch (e) {
      _showSnack('エラーが発生しました');
    }
  }

  // ───────────── 投稿・更新・削除 ─────────────

  // 成功したら null、失敗したら画面に出すメッセージを返す
  Future<String?> _postEvent({
    required String title,
    required String description,
    required String category,
    required String date,
    required String location,
    required int? maxParticipants,
    required DateTime endDate,
    required String? imageUrl,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return 'ログインし直してください';
    if (maxParticipants != null && maxParticipants < 1) {
      return '参加人数の上限は1人以上にしてください';
    }

    try {
      final userRef =
      FirebaseFirestore.instance.collection('users').doc(myUid);
      final myData = (await userRef.get()).data();

      final age = myData?['age'] as int? ?? 0;
      if (age < 18) return '18歳未満はイベントを投稿できません';

      // 1日の回数は、ユーザー情報に数えておく（イベントを消しても減らない）
      final todayKey = _todayKey();
      final todayCount = myData?['eventPostDate'] == todayKey
          ? (myData?['eventPostCount'] as int? ?? 0)
          : 0;
      if (todayCount >= _maxPostsPerDay) {
        return '1日$_maxPostsPerDay回までしか投稿できません。明日また投稿してください。';
      }

      final activeCount = await _countActiveEvents(myUid);
      if (activeCount >= _maxActiveEvents) {
        return '公開中のイベントは$_maxActiveEvents件までです。終了日を過ぎるか、削除してから投稿してください。';
      }

      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': description,
        'category': category,
        'date': date,
        'location': location,
        'emoji': '🐾',
        'isOfficial': false,
        'organizerName': myData?['name'] ?? '',
        'organizerUid': myUid,
        'participantCount': 0,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        'endDate': Timestamp.fromDate(_endOfDay(endDate)),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userRef.update({
        'eventPostDate': todayKey,
        'eventPostCount': todayCount + 1,
      });

      _loadEvents();
      _loadMyPostCounts();
      return null;
    } catch (e) {
      debugPrint('postEvent エラー: $e');
      return '投稿できませんでした: $e';
    }
  }

  Future<String?> _updateEvent({
    required Map<String, dynamic> event,
    required String title,
    required String description,
    required String location,
    required String date,
    required String category,
    required DateTime? endDate,
    required int? maxParticipants,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return 'ログインし直してください';

    final currentCount = event['participantCount'] as int? ?? 0;
    if (maxParticipants != null) {
      if (maxParticipants < 1) return '参加人数の上限は1人以上にしてください';
      if (maxParticipants < currentCount) {
        return '参加人数の上限は、今の参加者数（$currentCount人）より少なくできません';
      }
    }

    try {
      final newEnd = endDate == null ? null : _endOfDay(endDate);

      // 終了していたイベントを再公開するときは、公開中の件数の上限を確認する
      if (_isExpired(event) && newEnd != null && newEnd.isAfter(DateTime.now())) {
        final others =
        await _countActiveEvents(myUid, excludeId: event['id'] as String);
        if (others >= _maxActiveEvents) {
          return '公開中のイベントが$_maxActiveEvents件あるため、再公開できません。ほかのイベントが終わるか、削除してからにしてください。';
        }
      }

      final eventRef =
      FirebaseFirestore.instance.collection('events').doc(event['id']);
      await eventRef.update({
        'title': title,
        'description': description,
        'location': location,
        'date': date,
        'category': category,
        if (newEnd != null) 'endDate': Timestamp.fromDate(newEnd),
        'maxParticipants': maxParticipants,
      });

      // 参加者全員に変更を知らせる
      final participants = await eventRef.collection('participants').get();
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
          'desc': '「$title」の内容が変更されました。確認してください。',
          'eventId': event['id'],
          'fromUid': event['organizerUid'],
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _loadEvents();
      _loadMyPostCounts();
      return null;
    } catch (e) {
      debugPrint('updateEvent エラー: $e');
      return '更新できませんでした: $e';
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    try {
      final eventRef =
      FirebaseFirestore.instance.collection('events').doc(event['id']);
      final title = event['title'] as String? ?? '';
      final participants = await eventRef.collection('participants').get();
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
          'desc': '「$title」は企画者により削除されました',
          'fromUid': event['organizerUid'],
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await eventRef.delete();
      _loadEvents();
      _loadMyPostCounts();
      _showSnack('削除しました', color: Colors.grey);
    } catch (e) {
      _showSnack('削除できませんでした: $e');
    }
  }

  // 削除する前に、何が起きるかを伝えて、確認する
  Future<void> _confirmDeleteEvent(Map<String, dynamic> event) async {
    final title = event['title'] as String? ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('イベントを削除しますか？'),
        content: Text(
            '「$title」を削除します。\n参加者には、削除されたことが通知されます。\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('戻る', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirm == true) _deleteEvent(event);
  }

  void _showOrganizerMenu(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('このイベントをどうしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showEditEvent(context, event);
            },
            child: const Text('編集', style: TextStyle(color: _orange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _confirmDeleteEvent(event);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  // ───────────── 一覧 ─────────────

  List<Map<String, dynamic>> get _filtered {
    final list = _selectedCategory == '全て'
        ? List<Map<String, dynamic>>.from(_events)
        : _events.where((e) => e['category'] == _selectedCategory).toList();

    if (_sortBy == '人気') {
      list.sort((a, b) => ((b['participantCount'] ?? 0) as int)
          .compareTo((a['participantCount'] ?? 0) as int));
    } else {
      list.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    }
    // 自分が主催しているもの・参加中のものを一番上に、
    // 終了したもの（主催者にだけ見える）は一番下に並べる
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    bool pinned(Map<String, dynamic> e) =>
        _joinedEventIds.contains(e['id']) ||
            (myUid != null && e['organizerUid'] == myUid);
    final active = list.where((e) => !_isExpired(e)).toList();
    return [
      ...active.where(pinned),
      ...active.where((e) => !pinned(e)),
      ...list.where((e) => _isExpired(e)),
    ];
  }

  // 投稿できないときの理由（投稿できるなら null）
  String? _postBlockedReason() {
    if (_myAge != null && _myAge! < 18) {
      return '18歳未満はイベントを投稿できません';
    }
    if (_todayPostCount >= _maxPostsPerDay) {
      return '1日$_maxPostsPerDay回までしか投稿できません。明日また投稿してください。';
    }
    if (_activePostCount >= _maxActiveEvents) {
      return '公開中のイベントは$_maxActiveEvents件までです。終了日を過ぎるか、削除してから投稿してください。';
    }
    return null;
  }

  void _onTapPost() {
    final reason = _postBlockedReason();
    if (reason != null) {
      _showSnack(reason);
      return;
    }
    _showPostEvent(context);
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isEmergency = event['category'] == '緊急支援';
    final isWalk = event['category'] == '散歩仲間募集';
    final isJoined = _joinedEventIds.contains(event['id']);
    final isMine = event['organizerUid'] == myUid;
    final expired = _isExpired(event);
    final imageUrl = event['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => _showEventDetail(context, event),
      onLongPress: isMine ? () => _showOrganizerMenu(event) : null,
      child: Opacity(
        opacity: expired ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isEmergency
                ? Border.all(color: Colors.red[300]!)
                : isWalk
                ? Border.all(color: _green.withOpacity(0.3))
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
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl,
                        width: 90, height: 90, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.1),
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (event['isOfficial'] == true) _badge('公式', _green),
                          if (isMine) _badge('自分の投稿', _orange),
                          if (isJoined) _badge('参加済み', _green),
                          if (expired) _badge('終了', Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event['title'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _brown),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(event['organizerName'] as String? ?? '',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event['date'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event['location'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const Icon(Icons.people_rounded,
                              size: 12, color: _orange),
                          const SizedBox(width: 4),
                          Text('${event['participantCount'] ?? 0}人',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _orange,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _postBlockedReason() != null;
    final events = _filtered;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('イベント掲示板 📋',
            style: TextStyle(fontWeight: FontWeight.w900, color: _brown)),
        backgroundColor: _cream,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showRulesDialog,
            icon: const Icon(Icons.info_outline_rounded,
                color: _green, size: 26),
          ),
          IconButton(
            onPressed: _onTapPost,
            icon: Icon(Icons.add_circle_rounded,
                color: blocked ? Colors.grey : _orange, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: _categories
                  .map((cat) => _pill(cat, _selectedCategory == cat, _orange,
                      () => setState(() => _selectedCategory = cat)))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: ['新着', '人気']
                  .map((sort) => _pill(sort, _sortBy == sort, _green,
                      () => setState(() => _sortBy = sort),
                  vPad: 6, fontSize: 12))
                  .toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: _orange))
                : events.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('イベントがありません',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _brown)),
                  const SizedBox(height: 8),
                  Text('右上の＋から投稿してみよう！',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: events.length,
              itemBuilder: (_, i) => _buildEventCard(events[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── 詳細 ─────────────

  Widget _buildParticipants(
      BuildContext sheetContext, Map<String, dynamic> event) {
    final isOrganizer =
        event['organizerUid'] == FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('events')
          .doc(event['id'])
          .collection('participants')
          .get(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: _orange);
        }
        final participants = snapshot.data!.docs;
        if (participants.isEmpty) {
          return Text('まだ参加者がいません',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]));
        }
        return Column(
          children: participants
              .map((p) =>
              _buildParticipantRow(sheetContext, event, p.id, isOrganizer))
              .toList(),
        );
      },
    );
  }

  Widget _buildParticipantRow(BuildContext sheetContext,
      Map<String, dynamic> event, String participantUid, bool isOrganizer) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(participantUid)
          .get(),
      builder: (ctx, userSnap) {
        if (!userSnap.hasData) return const SizedBox();
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final name = userData?['name'] as String? ?? '';
        final imageUrl = userData?['profileImageUrl'] as String?;
        final hasImage = imageUrl != null && imageUrl.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UserProfilePage(uid: participantUid)),
                  );
                },
                child: Row(
                  children: [
                    ClipOval(
                      child: hasImage
                          ? Image.network(imageUrl,
                          width: 36, height: 36, fit: BoxFit.cover)
                          : Container(
                        width: 36,
                        height: 36,
                        color: const Color(0xFFFFE0D0),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0] : '🐾',
                            style: const TextStyle(
                                fontSize: 16,
                                color: _orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(name,
                        style:
                        const TextStyle(fontSize: 14, color: _brown)),
                  ],
                ),
              ),
              const Spacer(),
              if (isOrganizer && participantUid != myUid)
                TextButton(
                  onPressed: () => _banParticipant(
                      sheetContext, event, participantUid, name),
                  child:
                  const Text('追放', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _banParticipant(BuildContext sheetContext,
      Map<String, dynamic> event, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('追放しますか？'),
        content: Text('$nameさんをグループから追放します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

    try {
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event['id'] as String);
      await eventRef.collection('participants').doc(uid).delete();
      await eventRef.update({
        'participantCount': FieldValue.increment(-1),
        'bannedUsers': FieldValue.arrayUnion([uid]),
      });

      if (await shouldSendNotification(uid, 'イベント関連')) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .add({
          'type': 'eventRemoved',
          'senderUid': FirebaseAuth.instance.currentUser?.uid,
          'emoji': '🚫',
          'title': 'イベントから追放されました',
          'desc': '${event['title']}から追放されました',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (sheetContext.mounted) Navigator.pop(sheetContext);
      _loadEvents();
      _showSnack('追放しました');
    } catch (e) {
      _showSnack('追放できませんでした: $e');
    }
  }

  Future<void> _reportEvent(
      BuildContext sheetContext, Map<String, dynamic> event) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    String? selectedReason;
    final commentCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('通報する'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('理由を選んでください', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                ...['スパム', '不適切なコンテンツ', '詐欺・金銭トラブル', '危険な内容', 'その他']
                    .map((reason) => RadioListTile<String>(
                  title: Text(reason,
                      style: const TextStyle(fontSize: 13)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _orange,
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
                        borderSide: const BorderSide(color: _orange)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child:
              const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
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
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'event',
        'eventId': event['id'],
        'reporterId': myUid,
        'reason': selectedReason,
        'comment': commentCtrl.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      _showSnack('通報しました。ご報告ありがとうございます。', color: Colors.grey);
    } catch (e) {
      _showSnack('通報できませんでした: $e');
    }
  }

  // 参加する／キャンセルするボタンの動き
  Future<void> _onTapJoinButton(BuildContext sheetContext,
      Map<String, dynamic> event, bool isJoined) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    final age = myDoc.data()?['age'] as int? ?? 0;
    if (age < 18) {
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      _showSnack('18歳未満はイベントに参加できません');
      return;
    }
    if (!sheetContext.mounted) return;

    if (isJoined) {
      final reason = await showDialog<String>(
        context: sheetContext,
        builder: (_) {
          String? selected;
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: const Text('キャンセル理由を選んでください'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('キャンセルすると他の参加者に迷惑がかかる場合があります。',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ...['急病・体調不良', '仕事・学校の都合', '家族の都合', 'その他'].map(
                        (r) => RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selected,
                      onChanged: (v) => setDialogState(() => selected = v),
                      activeColor: _orange,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child:
                  const Text('戻る', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(dialogContext, selected),
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
      if (reason != null) {
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        _cancelEvent(event['id'] as String, reason: reason);
      }
    } else {
      Navigator.pop(sheetContext);
      _joinEvent(event['id'] as String);
    }
  }

  void _showEventDetail(BuildContext parentContext, Map<String, dynamic> event) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isJoined = _joinedEventIds.contains(event['id']);
    final isOrganizer = event['organizerUid'] == myUid;
    final isExpired = _isExpired(event);
    final isBanned =
    List<String>.from(event['bannedUsers'] ?? []).contains(myUid);
    final imageUrl = event['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final endDate = event['endDate'] is Timestamp
        ? (event['endDate'] as Timestamp).toDate()
        : null;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
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
                    if (hasImage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover),
                        ),
                      ),
                    Row(
                      children: [
                        if (!hasImage) ...[
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
                                      color: _brown)),
                              Text(event['organizerName'] as String? ?? '',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600])),
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
                    _EventRow(
                        Icons.people_rounded,
                        event['maxParticipants'] != null
                            ? '${event['participantCount'] ?? 0}/${event['maxParticipants']}人'
                            : '${event['participantCount'] ?? 0}人が参加'),
                    const SizedBox(height: 8),
                    if (endDate != null)
                      _EventRow(Icons.event_busy_rounded,
                          '終了日：${_dateLabel(endDate)}${isExpired ? '（終了しました）' : ''}'),
                    const SizedBox(height: 16),
                    const Text('参加者',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _brown)),
                    const SizedBox(height: 8),
                    _buildParticipants(sheetContext, event),
                    const Divider(height: 32),
                    const Text('詳細',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _brown)),
                    const SizedBox(height: 8),
                    Text(event['description'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600], height: 1.7)),
                    const SizedBox(height: 24),

                    // 主催者だけに見える「編集する」
                    if (isOrganizer) ...[
                      if (isExpired)
                        _infoBox(
                            'このイベントは公開が終了しています。「編集する」で終了日を今日以降にすると、もう一度公開されます。',
                            Colors.orange),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showEditEvent(parentContext, event);
                          },
                          icon: const Icon(Icons.edit_rounded, color: _orange),
                          label: const Text('編集する（終了日も変更できます）',
                              style: TextStyle(color: _orange)),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: _orange),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _confirmDeleteEvent(event);
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          label: const Text('イベントを削除する（参加者に通知されます）',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isJoined && !isOrganizer && !isExpired && !isBanned)
                      _infoBox('参加するとグループチャットに参加できます🐾', _green),

                    if (isJoined || isOrganizer) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              parentContext,
                              MaterialPageRoute(
                                builder: (_) => EventChatPage(
                                  eventId: event['id'],
                                  eventTitle: event['title'] as String? ?? '',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded,
                              color: Colors.white),
                          label: const Text('グループチャット',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isOrganizer)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isExpired || isBanned)
                              ? null
                              : () => _onTapJoinButton(
                              sheetContext, event, isJoined),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: (isExpired || isBanned || isJoined)
                                  ? Colors.grey
                                  : _orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                          child: Text(
                              isExpired
                                  ? '終了したイベントです'
                                  : isBanned
                                  ? 'このイベントには参加できません'
                                  : isJoined
                                  ? 'キャンセルする'
                                  : '参加する🐾',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final organizerUid = event['organizerUid'] as String?;
                          if (organizerUid == null) return;
                          if (organizerUid == myUid) {
                            _showSnack('自分のイベントです', color: Colors.grey);
                            return;
                          }
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            parentContext,
                            MaterialPageRoute(
                                builder: (_) =>
                                    UserProfilePage(uid: organizerUid)),
                          );
                        },
                        icon: const Icon(Icons.person_rounded, color: _orange),
                        label: const Text('企画者のプロフィールを見る',
                            style: TextStyle(color: _orange)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: _orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _reportEvent(sheetContext, event),
                        icon: const Icon(Icons.flag_rounded,
                            color: Colors.red, size: 16),
                        label: const Text('このイベントを通報する',
                            style: TextStyle(color: Colors.red, fontSize: 13)),
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
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
                          SizedBox(height: 4),
                          Text('・住所・電話番号などの個人情報は教えないようにしよう',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
                          SizedBox(height: 4),
                          Text('・不安を感じたらすぐに運営に報告しよう',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
                          SizedBox(height: 4),
                          Text('・18歳未満の方はイベントに参加・投稿できません',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
                          SizedBox(height: 4),
                          Text('・金銭のやり取りは絶対にしないようにしよう',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange)),
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

  // ───────────── 編集 ─────────────

  void _showEditEvent(BuildContext parentContext, Map<String, dynamic> event) {
    final messenger = ScaffoldMessenger.of(parentContext);
    final titleCtrl =
    TextEditingController(text: event['title'] as String? ?? '');
    final descCtrl =
    TextEditingController(text: event['description'] as String? ?? '');
    final locationCtrl =
    TextEditingController(text: event['location'] as String? ?? '');
    final maxParticipantsCtrl = TextEditingController(
        text: event['maxParticipants']?.toString() ?? '');
    String dateText = event['date'] as String? ?? '';
    String selectedCategory = event['category'] as String? ?? '散歩仲間募集';
    DateTime? selectedEndDate = event['endDate'] is Timestamp
        ? (event['endDate'] as Timestamp).toDate()
        : null;
    final expired = _isExpired(event);
    bool isSaving = false;
    String? formError;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => _sheetFrame(
          context,
          title: 'イベントを編集',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expired)
                _infoBox(
                    'このイベントは公開が終了しています。終了日を今日以降にして更新すると、もう一度公開されます。',
                    Colors.orange),
              _label('カテゴリ'),
              _categoryChips(selectedCategory,
                      (cat) => setModalState(() => selectedCategory = cat)),
              const SizedBox(height: 16),
              _label('タイトル'),
              TextField(
                controller: titleCtrl,
                maxLength: 30,
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 16),
              _label('日時'),
              _pickerBox(
                icon: Icons.calendar_today_rounded,
                iconColor: _orange,
                text: dateText.isEmpty ? '日付を選択してください' : dateText,
                isEmpty: dateText.isEmpty,
                onTap: () async {
                  final picked = await _pickEventDateTime(context);
                  if (picked != null) {
                    setModalState(() => dateText = picked.text);
                  }
                },
              ),
              const SizedBox(height: 16),
              _label('終了日（この日の終わりまで公開）'),
              _pickerBox(
                icon: Icons.event_busy_rounded,
                iconColor: _green,
                text: selectedEndDate == null
                    ? '終了日を選択してください'
                    : _dateLabel(selectedEndDate!),
                isEmpty: selectedEndDate == null,
                onTap: () async {
                  final picked =
                  await _pickEndDate(context, current: selectedEndDate);
                  if (picked != null) {
                    setModalState(() => selectedEndDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              _label('場所'),
              TextField(
                controller: locationCtrl,
                maxLength: 50,
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 16),
              _label('参加人数の上限（任意）'),
              TextField(
                controller: maxParticipantsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: _maxParticipantsFormatters,
                decoration: _fieldDecoration(hint: '例：10（設定しない場合は空欄）'),
              ),
              const SizedBox(height: 16),
              _label('詳細'),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                maxLength: 300,
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 24),
              _formErrorBox(formError),
              _primaryButton(
                isSaving ? '更新しています…' : '更新する',
                isSaving
                    ? null
                    : () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    setModalState(() => formError = 'タイトルを入力してください');
                    return;
                  }
                  setModalState(() {
                    formError = null;
                    isSaving = true;
                  });
                  final error = await _updateEvent(
                    event: event,
                    title: title,
                    description: descCtrl.text,
                    location: locationCtrl.text,
                    date: dateText,
                    category: selectedCategory,
                    endDate: selectedEndDate,
                    maxParticipants: maxParticipantsCtrl.text.isEmpty
                        ? null
                        : int.tryParse(maxParticipantsCtrl.text),
                  );
                  if (error == null) {
                    messenger.showSnackBar(const SnackBar(
                      content: Text('更新しました🐾'),
                      backgroundColor: _orange,
                    ));
                    if (context.mounted) Navigator.pop(context);
                  } else if (context.mounted) {
                    setModalState(() {
                      formError = error;
                      isSaving = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── 投稿 ─────────────

  void _showPostEvent(BuildContext parentContext) {
    final messenger = ScaffoldMessenger.of(parentContext);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final maxParticipantsCtrl = TextEditingController();
    String dateText = '';
    DateTime? selectedDate;
    DateTime? selectedEndDate;
    String selectedCategory = '散歩仲間募集';
    String? selectedImageUrl;
    bool isUploadingImage = false;
    bool isPosting = false;
    String? formError;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => _sheetFrame(
          context,
          title: 'イベントを投稿',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoBox(
                  '🐾 動物好きのイベントを投稿しよう！\n個人情報・金銭のやり取りは書かないようにしましょう。\n1日$_maxPostsPerDay回まで、公開中は$_maxActiveEvents件まで投稿できます。',
                  _orange),
              _label('カテゴリ'),
              _categoryChips(selectedCategory,
                      (cat) => setModalState(() => selectedCategory = cat)),
              const SizedBox(height: 16),
              _label('画像（任意）'),
              GestureDetector(
                onTap: () async {
                  if (isUploadingImage) return;
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
                      child: CircularProgressIndicator(color: _orange))
                      : selectedImageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(selectedImageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover),
                  )
                      : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            color: _orange, size: 32),
                        SizedBox(height: 8),
                        Text('画像を選択',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('タイトル'),
              TextField(
                controller: titleCtrl,
                maxLength: 30,
                decoration: _fieldDecoration(hint: '例：代々木公園で散歩仲間募集！'),
              ),
              const SizedBox(height: 16),
              _label('日時'),
              _pickerBox(
                icon: Icons.calendar_today_rounded,
                iconColor: _orange,
                text: dateText.isEmpty ? '日付を選択してください' : dateText,
                isEmpty: dateText.isEmpty,
                onTap: () async {
                  final picked = await _pickEventDateTime(context);
                  if (picked != null) {
                    setModalState(() {
                      selectedDate = picked.date;
                      dateText = picked.text;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _label('終了日（必須・この日の終わりまで公開）'),
              _pickerBox(
                icon: Icons.event_busy_rounded,
                iconColor: _green,
                text: selectedEndDate == null
                    ? '終了日を選択してください'
                    : _dateLabel(selectedEndDate!),
                isEmpty: selectedEndDate == null,
                onTap: () async {
                  final picked = await _pickEndDate(context,
                      current: selectedEndDate, minDate: selectedDate);
                  if (picked != null) {
                    setModalState(() => selectedEndDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              _label('場所'),
              TextField(
                controller: locationCtrl,
                maxLength: 50,
                decoration: _fieldDecoration(hint: '例：東京都世田谷区'),
              ),
              const SizedBox(height: 16),
              _label('参加人数の上限（任意）'),
              TextField(
                controller: maxParticipantsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: _maxParticipantsFormatters,
                decoration: _fieldDecoration(hint: '例：10（設定しない場合は空欄）'),
              ),
              const SizedBox(height: 16),
              _label('詳細'),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                maxLength: 300,
                decoration: _fieldDecoration(hint: '参加条件や詳細を書いてください'),
              ),
              const SizedBox(height: 24),
              _formErrorBox(formError),
              _primaryButton(
                isPosting ? '投稿しています…' : '投稿する',
                isPosting
                    ? null
                    : () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    setModalState(() => formError = 'タイトルを入力してください');
                    return;
                  }
                  final endDate = selectedEndDate;
                  if (endDate == null) {
                    setModalState(() => formError = '終了日を設定してください');
                    return;
                  }
                  final startDate = selectedDate;
                  if (startDate != null &&
                      _dateOnly(endDate).isBefore(_dateOnly(startDate))) {
                    setModalState(
                            () => formError = '終了日は、イベントの日付より前にできません');
                    return;
                  }
                  setModalState(() {
                    formError = null;
                    isPosting = true;
                  });
                  final error = await _postEvent(
                    title: title,
                    description: descCtrl.text,
                    category: selectedCategory,
                    date: dateText,
                    location: locationCtrl.text,
                    maxParticipants: maxParticipantsCtrl.text.isEmpty
                        ? null
                        : int.tryParse(maxParticipantsCtrl.text),
                    endDate: endDate,
                    imageUrl: selectedImageUrl,
                  );
                  if (error == null) {
                    messenger.showSnackBar(const SnackBar(
                      content: Text('投稿しました！🐾'),
                      backgroundColor: _orange,
                    ));
                    if (context.mounted) Navigator.pop(context);
                  } else if (context.mounted) {
                    setModalState(() {
                      formError = error;
                      isPosting = false;
                    });
                  }
                },
              ),
            ],
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
        Icon(icon, size: 16, color: _orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
      ],
    );
  }
}