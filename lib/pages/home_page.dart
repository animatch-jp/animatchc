import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pet_brag_page.dart';
import 'ranking_page.dart';
import 'question_board_page.dart';
import 'animal_map_page.dart';
import '../services/start_guide.dart';
import 'pet_detail_page.dart';
import 'pet_records.dart';

class HomePage extends StatefulWidget {
  final ScrollController? scrollController;
  const HomePage({super.key, this.scrollController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '';
  bool _hasProfileImage = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userName = doc.data()!['name'] ?? '';
            final imageUrl = doc.data()!['profileImageUrl'] as String? ?? '';
            _hasProfileImage = imageUrl.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('🔥 名前取得エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty
                                  ? 'こんにちは、${_userName}さん！🐾'
                                  : 'こんにちは！🐾',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            const Text('AniMatch',
                                style: TextStyle(fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3D2B1F))),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RankingPage())),


                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8)]),
                            child: const Text('🏆',
                                style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hasProfileImage)
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfilePage())),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8845A)),
                        ),
                        child: const Row(
                          children: [
                            Text('⚠️', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'プロフィール画像を設定しよう🐾',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE8845A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Color(0xFFE8845A), size: 13),
                          ],
                        ),
                      ),
                    ),
                  const _StartGuideCard(),
                  const _CareReminderCard(),
                  const _PetTaskReminder(),
                  const _MemoryCard(),
                  const _QuestionBoardPreview(),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
            SliverToBoxAdapter(
              child: HomeFeedSection(),
            ),

          ],
        ),
      ),
    );
  }
}
class _QuestionBoardPreview extends StatelessWidget {
  const _QuestionBoardPreview();

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = (timestamp as Timestamp).toDate();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionBoardPage())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFE8845A), Color(0xFFF4A261)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('質問掲示板',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                // 未解決の数だけを数える（全部の質問を読まない。1000件まで1回分の読みこみ）
                FutureBuilder<AggregateQuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('questions')
                      .where('solved', isEqualTo: false)
                      .count()
                      .get(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.count ?? 0;
                    if (count == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                      child: Text('未解決 $count件', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('ちょっとした困りごと、みんなに聞いてみよう',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('questions')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Text('最初の質問をしてみませんか？🐾',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(data['title'] ?? '',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                          const SizedBox(width: 6),
                          Text(_timeAgo(data['createdAt']), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
class _PetTaskReminder extends StatefulWidget {
  const _PetTaskReminder();

  @override
  State<_PetTaskReminder> createState() => _PetTaskReminderState();
}

class _PetTaskReminderState extends State<_PetTaskReminder> {
  Future<List<Map<String, dynamic>>>? _future;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _loadTodayTasks(List<QueryDocumentSnapshot> pets) async {
    final today = _todayKey;
    final List<Map<String, dynamic>> tasks = [];

    for (final pet in pets) {
      final petData = pet.data() as Map<String, dynamic>;
      final petName = petData['name'] ?? '';

      final tasksSnap = await pet.reference.collection('tasks').get();
      for (final task in tasksSnap.docs) {
        final logDoc = await task.reference.collection('logs').doc(today).get();
        final taskData = task.data();
        tasks.add({
          'petId': pet.id,
          'petName': petName,
          'taskId': task.id,
          'taskName': taskData['name'] ?? '',
          'done': logDoc.exists,
        });
      }
    }

    return tasks;
  }

  Future<void> _toggleTaskDone(String myUid, String petId, String taskId, bool currentlyDone) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('pets')
        .doc(petId)
        .collection('tasks')
        .doc(taskId)
        .collection('logs')
        .doc(_todayKey);

    if (currentlyDone) {
      await ref.delete();
    } else {
      await ref.set({'doneAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('pets')
          .snapshots(),
      builder: (context, petSnap) {
        if (!petSnap.hasData || petSnap.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final pets = petSnap.data!.docs;

        _future ??= _loadTodayTasks(pets);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, taskSnap) {
            if (!taskSnap.hasData || taskSnap.data!.isEmpty) {
              return const SizedBox();
            }
            final tasks = taskSnap.data!;
            final undoneCount = tasks.where((t) => t['done'] != true).length;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        undoneCount > 0
                            ? '今日のお世話、まだ$undoneCount件あります'
                            : '今日のお世話、全部完了しました🎉',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...tasks.map((t) {
                    final done = t['done'] == true;
                    return GestureDetector(
                      onTap: () async {
                        await _toggleTaskDone(myUid, t['petId'], t['taskId'], done);
                        setState(() {
                          _future = _loadTodayTasks(pets);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: const Color(0xFF2D6A4F),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${t['petName']}の${t['taskName']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF2D6A4F),
                                  decoration: done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


// 思い出の日：1週間前・1か月前・1年前（2年前・3年前も）の「今日」に投稿したペット自慢を出す
class _MemoryCard extends StatefulWidget {
  const _MemoryCard();

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  List<Map<String, dynamic>> _items = [];

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 1か月前・1年前の日が無いとき（3/31の1か月前など）は、その月の最後の日にする
  static DateTime _monthsAgo(DateTime now, int months) {
    var y = now.year;
    var m = now.month - months;
    while (m <= 0) {
      m += 12;
      y -= 1;
    }
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, now.day > last ? last : now.day);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final labels = <String, String>{
      _key(now.subtract(const Duration(days: 7))): '1週間前の今日',
      _key(_monthsAgo(now, 1)): '1か月前の今日',
      _key(_monthsAgo(now, 12)): '1年前の今日',
      _key(_monthsAgo(now, 24)): '2年前の今日',
      _key(_monthsAgo(now, 36)): '3年前の今日',
    };
    try {
      final snap = await FirebaseFirestore.instance
          .collection('petBrags')
          .where('uid', isEqualTo: uid)
          .where('dateKey', whereIn: labels.keys.toList())
          .limit(10)
          .get();
      final items = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final img = (data['imageUrl'] ?? '').toString();
        if (img.isEmpty) continue;
        items.add({
          ...data,
          '_label': labels[data['dateKey']] ?? '思い出',
        });
      }
      // 古い思い出から先に出す（1年前 → 1か月前 → 1週間前）
      items.sort((a, b) => (a['dateKey'] ?? '').toString().compareTo((b['dateKey'] ?? '').toString()));
      if (mounted) setState(() => _items = items);
    } catch (e) {
      debugPrint('思い出の日の読みこみエラー: $e');
    }
  }

  void _open(Map<String, dynamic> it) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(it['imageUrl'] as String,
                width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120, child: Center(child: Text('🐾', style: TextStyle(fontSize: 40))))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('${it['_label']}の${it['petName'] ?? 'うちの子'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            ),
            if ((it['comment'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(it['comment'].toString(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('とじる')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF1E6), Color(0xFFFFE4EC)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📸 思い出の日',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 2),
          Text('前の今日に投稿した、うちの子です',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final it = _items[i];
                return GestureDetector(
                  onTap: () => _open(it),
                  child: SizedBox(
                    width: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(it['imageUrl'] as String,
                              width: 104, height: 96, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 104, height: 96, color: Colors.white,
                                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 28))))),
                        ),
                        const SizedBox(height: 6),
                        Text(it['_label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB4642E))),
                      ],
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
}


// はじめての人への案内：「ペットを登録 → 最初の1枚 → 団体のページを見る」
// 3つともできたら、または「とじる」を押したら、もう出さない
class _StartGuideCard extends StatefulWidget {
  const _StartGuideCard();

  @override
  State<_StartGuideCard> createState() => _StartGuideCardState();
}

class _StartGuideCardState extends State<_StartGuideCard> {
  bool _loaded = false;
  bool _hide = true;
  bool _hasPet = false;
  bool _hasPost = false;
  bool _orgSeen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final st = await StartGuide.load();
      if (st['dismissed'] == true) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      final db = FirebaseFirestore.instance;
      final pets = await db.collection('users').doc(uid).collection('pets').limit(1).get();
      final posts = await db.collection('petBrags').where('uid', isEqualTo: uid).limit(1).get();
      if (!mounted) return;
      setState(() {
        _hasPet = pets.docs.isNotEmpty;
        _hasPost = posts.docs.isNotEmpty;
        _orgSeen = st['orgSeen'] == true;
        _hide = _hasPet && _hasPost && _orgSeen;
        _loaded = true;
      });
    } catch (e) {
      debugPrint('はじめての案内の読みこみエラー: $e');
    }
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load(); // もどってきたら、できたかどうかを読み直す
  }

  Widget _row(int n, bool done, String title, String sub, Widget page) {
    return InkWell(
      onTap: done ? null : () => _go(page),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF52B788) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: done ? const Color(0xFF52B788) : const Color(0xFFE8845A)),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text('$n',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE8845A))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: done ? Colors.grey : const Color(0xFF3D2B1F),
                          decoration: done ? TextDecoration.lineThrough : null)),
                  if (!done)
                    Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            if (!done)
              const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFE8845A)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _hide) return const SizedBox.shrink();
    final doneCount = [_hasPet, _hasPost, _orgSeen].where((b) => b).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD8C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🐾 はじめてのこと（$doneCount/3）',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
              ),
              TextButton(
                onPressed: () {
                  StartGuide.dismiss();
                  setState(() => _hide = true);
                },
                child: Text('とじる', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            ],
          ),
          _row(1, _hasPet, 'うちの子を登録する', 'マイページから、名前と写真を登録できます', const ProfilePage()),
          _row(2, _hasPost, '最初の1枚を投稿する', 'ペット自慢に、お気に入りの写真を1枚', const PetBragPage()),
          _row(3, _orgSeen, '近くの保護団体を見てみる', 'どうぶつマップの「団体」から、活動を知れます', const AnimalMapPage(initialCategory: 'org')),
        ],
      ),
    );
  }
}


// 記録帳の「次の予定日」が近いものを、ホームでお知らせする（すぎたもの7日まで・これから14日まで）
class _CareReminderCard extends StatefulWidget {
  const _CareReminderCard();

  @override
  State<_CareReminderCard> createState() => _CareReminderCardState();
}

class _CareReminderCardState extends State<_CareReminderCard> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 7));
    final to = today.add(const Duration(days: 14));
    try {
      final pets = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pets')
          .limit(10)
          .get();
      final items = <Map<String, dynamic>>[];
      for (final pet in pets.docs) {
        final recs = await pet.reference
            .collection('records')
            .where('nextDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('nextDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
            .orderBy('nextDate')
            .limit(3)
            .get();
        for (final r in recs.docs) {
          final d = r.data();
          final next = PetRecords.toDate(d['nextDate']);
          if (next == null) continue;
          items.add({
            'pet': pet,
            'kind': d['kind'],
            'note': d['note'] ?? '',
            'days': DateTime(next.year, next.month, next.day).difference(today).inDays,
          });
        }
      }
      items.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
      if (mounted) setState(() => _items = items.take(4).toList());
    } catch (e) {
      debugPrint('記録帳のお知らせの読みこみエラー: $e');
    }
  }

  String _when(int days) {
    if (days == 0) return '今日';
    if (days == 1) return '明日';
    if (days > 0) return 'あと$days日';
    return '${-days}日すぎています';
  }

  Future<void> _open(QueryDocumentSnapshot<Map<String, dynamic>> pet) async {
    final d = pet.data();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailPage(
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          petId: pet.id,
          petName: (d['name'] ?? '').toString(),
          petType: (d['type'] ?? '').toString(),
          petAge: (d['age'] ?? '').toString(),
          petBio: (d['bio'] ?? '').toString(),
          petTags: List<String>.from(d['tags'] ?? const []),
          petImageUrl: d['imageUrl'] as String?,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7DEC6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔔 もうすぐの予定',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2D6A4F))),
          const SizedBox(height: 6),
          ..._items.map((it) {
            final pet = it['pet'] as QueryDocumentSnapshot<Map<String, dynamic>>;
            final days = it['days'] as int;
            final kind = (it['kind'] ?? 'other').toString();
            final note = (it['note'] ?? '').toString();
            return InkWell(
              onTap: () => _open(pet),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(PetRecords.emoji[kind] ?? '📝', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pet.data()['name'] ?? ''}：${note.isEmpty ? (PetRecords.kinds[kind] ?? '') : note}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3D2B1F)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_when(days),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: days < 0 ? Colors.red : const Color(0xFF2D6A4F))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
