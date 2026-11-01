import 'package:flutter/material.dart';
import '../widgets/animaru_loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .get();

    // ブロックした相手は、利用者・団体・動物病院のどれか。順に探して、名前を出す
    final db = FirebaseFirestore.instance;
    Future<Map<String, dynamic>> find(String id) async {
      try {
        final u = await db.collection('users').doc(id).get();
        if (u.exists) {
          return {
            'uid': id,
            'name': u.data()?['name'] ?? '',
            'profileImageUrl': u.data()?['profileImageUrl'] ?? '',
            'kind': '',
          };
        }
        final o = await db.collection('organizations').doc(id).get();
        if (o.exists) {
          return {
            'uid': id,
            'name': o.data()?['name'] ?? '',
            'profileImageUrl': o.data()?['imageUrl'] ?? '',
            'kind': '団体',
          };
        }
        final h = await db.collection('hospitals').doc(id).get();
        if (h.exists) {
          return {
            'uid': id,
            'name': h.data()?['name'] ?? '',
            'profileImageUrl': h.data()?['imageUrl'] ?? '',
            'kind': '動物病院',
          };
        }
      } catch (_) {}
      // 退会したなどで見つからなくても、解除はできるように残す
      return {'uid': id, 'name': '（見つからないアカウント）', 'profileImageUrl': '', 'kind': ''};
    }

    final users = await Future.wait(snapshot.docs.map((d) => find(d.id)));

    if (mounted) {
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _unblock(String uid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('ブロックを解除しますか？'),
        content: const Text('解除するとこのユーザーが再び表示されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('解除する'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .doc(uid)
        .delete();

    setState(() {
      _blockedUsers.removeWhere((u) => u['uid'] == uid);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ブロックを解除しました'),
          backgroundColor: Color(0xFF2D6A4F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ブロックリスト',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: _isLoading
          ? const AnimaruLoading()
          : _blockedUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🚫', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('ブロックしているユーザーはいません',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _blockedUsers.length,
        itemBuilder: (_, i) {
          final user = _blockedUsers[i];
          return ListTile(
            leading: (user['profileImageUrl'] as String? ?? '').isNotEmpty
                ? ClipOval(
              child: Image.network(
                user['profileImageUrl'],
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8845A)
                      .withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Center(
                  child: Text('🐾',
                      style: TextStyle(fontSize: 24))),
            ),
            title: Text(user['name'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            subtitle: (user['kind'] as String? ?? '').isEmpty
                ? null
                : Text(user['kind'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: TextButton(
              onPressed: () => _unblock(user['uid']),
              child: const Text('解除',
                  style: TextStyle(color: Color(0xFFE8845A))),
            ),
          );
        },
      ),
    );
  }
}
