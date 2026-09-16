import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavUsers();
  }

  Future<void> _loadFavUsers() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(myUid)
          .collection('favorited')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> users = [];
      for (final doc in snapshot.docs) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .get();
        if (userDoc.exists) {
          users.add({'uid': doc.id, ...userDoc.data()!});
        }
      }

      if (mounted) {
        setState(() {
          _favUsers = users;
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
        title: const Text('お気に入り',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)))
          : _favUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⭐', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('まだお気に入りがいません',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            SizedBox(height: 8),
            Text('スワイプで⭐を押してみよう！',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favUsers.length,
        itemBuilder: (_, i) {
          final user = _favUsers[i];
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
