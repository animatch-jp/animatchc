import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  List<Map<String, dynamic>> _matchedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedUsers();
  }

  Future<void> _loadMatchedUsers() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: myUid)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> users = [];
      for (final doc in snapshot.docs) {
        final List users_ = doc.data()['users'] as List;
        final otherUid = users_.firstWhere((uid) => uid != myUid);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUid)
            .get();
        if (userDoc.exists) {
          users.add({'uid': otherUid, ...userDoc.data()!});
        }
      }

      if (mounted) {
        setState(() {
          _matchedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('マッチ一覧',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)))
          : _matchedUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('まだマッチしていません',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            SizedBox(height: 8),
            Text('スワイプしてマッチしよう！',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matchedUsers.length,
        itemBuilder: (_, i) {
          final user = _matchedUsers[i];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        UserProfilePage(uid: user['uid']))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: user['profileImageUrl'] != null &&
                        (user['profileImageUrl'] as String)
                            .isNotEmpty
                        ? Image.network(
                        user['profileImageUrl'],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover)
                        : Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFFFE0D0),
                        child: Center(
                            child: Text(
                              (user['name'] ?? '🐾')
                                  .toString()
                                  .isNotEmpty
                                  ? user['name'][0]
                                  : '🐾',
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFFE8845A),
                                  fontWeight: FontWeight.bold),
                            ))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        Text(
                            '${user['age'] ?? ''}歳・${user['prefecture'] ?? ''}',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600])),
                        Text(user['animal'] ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE8845A))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
