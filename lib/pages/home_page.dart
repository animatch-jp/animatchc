import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lost_pet_page.dart';
import 'adoption_page.dart';
import 'volunteer_page.dart';
import 'pet_brag_page.dart';
import 'question_board_page.dart';

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
                              MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    backgroundColor: const Color(0xFFFFF8F5),
                                    appBar: AppBar(
                                      backgroundColor: const Color(0xFFFFF8F5),
                                      elevation: 0,
                                      title: const Text('ランキング 🏆',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF3D2B1F))),
                                    ),
                                    body: const PetBragPage(initialTabIndex: 2),
                                  ))),


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
                  const _PetTaskReminder(),
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('questions')
                      .where('solved', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
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
