import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';

class FootprintPage extends StatefulWidget {
  const FootprintPage({super.key});

  @override
  State<FootprintPage> createState() => _FootprintPageState();
}

class _FootprintPageState extends State<FootprintPage> {
  List<Map<String, dynamic>> _footprints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFootprints();
  }

  Future<void> _loadFootprints() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('footprints')
          .doc(myUid)
          .collection('visitors')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final List<Map<String, dynamic>> footprints = [];
      for (final doc in snapshot.docs) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .get();
        if (userDoc.exists) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          footprints.add({
            'uid': doc.id,
            'createdAt': createdAt,
            'timeStr': _timeAgo(createdAt),
            ...userDoc.data()!,
          });
        }
      }

      if (mounted) {
        setState(() {
          _footprints = footprints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${time.month}/${time.day}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('足あと 👣',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)))
          : Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_footprints.length}人が見ました',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _footprints.isEmpty
              ? const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👣',
                      style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('まだ足あとがありません',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  SizedBox(height: 8),
                  Text('プロフィールを充実させよう！',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          )
              : Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _footprints.length,
              itemBuilder: (_, i) {
                final fp = _footprints[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => UserProfilePage(
                              uid: fp['uid']))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color:
                            Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: fp['profileImageUrl'] != null &&
                              (fp['profileImageUrl']
                              as String)
                                  .isNotEmpty
                              ? Image.network(
                              fp['profileImageUrl'],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover)
                              : Container(
                              width: 48,
                              height: 48,
                              color:
                              const Color(0xFFFFE0D0),
                              child: Center(
                                  child: Text(
                                    (fp['name'] ?? '🐾')
                                        .toString()
                                        .isNotEmpty
                                        ? fp['name'][0]
                                        : '🐾',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        color:
                                        Color(0xFFE8845A),
                                        fontWeight:
                                        FontWeight.bold),
                                  ))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(fp['name'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                      Color(0xFF3D2B1F))),
                              Text(
                                  '${fp['animal'] ?? ''} ・ ${fp['prefecture'] ?? ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Text(fp['timeStr'] ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400])),
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
