import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  int _step = 0;
  bool _confirmed = false;
  bool _isDeleting = false;
  final _pwCtrl = TextEditingController();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── 削除のための道具 ──────────────────────────

  // 渡されたドキュメントを、400件ずつまとめて消す
  Future<void> _deleteDocs(Iterable<DocumentReference> refs) async {
    final list = refs.toList();
    for (var i = 0; i < list.length; i += 400) {
      final batch = _db.batch();
      for (final r in list.skip(i).take(400)) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  // 検索条件に合うドキュメントを、全部消す
  Future<void> _deleteAll(Query q) async {
    final snap = await q.get();
    await _deleteDocs(snap.docs.map((d) => d.reference));
  }

  // 1か所で失敗しても、他の削除を止めない
  Future<void> _safe(String label, Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      debugPrint('退会処理: $label で失敗: $e');
    }
  }

  // 本人のデータを消す（ログインしている間にやる必要がある）
  Future<void> _purgeUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    await _safe('pets', () async {
      final pets = await userRef.collection('pets').get();
      for (final pet in pets.docs) {
        final tasks = await pet.reference.collection('tasks').get();
        for (final t in tasks.docs) {
          await _deleteAll(t.reference.collection('logs'));
        }
        await _deleteDocs(tasks.docs.map((d) => d.reference));
      }
      await _deleteDocs(pets.docs.map((d) => d.reference));
    });

    await _safe('searchHistory',
            () => _deleteAll(userRef.collection('searchHistory')));
    await _safe('groupChatLastSeen',
            () => _deleteAll(userRef.collection('groupChatLastSeen')));

    await _safe('likes',
            () => _deleteAll(_db.collection('likes').doc(uid).collection('liked')));
    await _safe(
        'favorites',
            () => _deleteAll(
            _db.collection('favorites').doc(uid).collection('favorited')));
    await _safe(
        'blocks',
            () => _deleteAll(
            _db.collection('blocks').doc(uid).collection('blocked')));
    await _safe('blocksDoc', () => _db.collection('blocks').doc(uid).delete());
    await _safe(
        'notifications',
            () => _deleteAll(
            _db.collection('notifications').doc(uid).collection('items')));

    // 自分の投稿（コメントも一緒に）
    await _safe('petBrags', () async {
      final posts =
      await _db.collection('petBrags').where('uid', isEqualTo: uid).get();
      for (final p in posts.docs) {
        await _deleteAll(p.reference.collection('comments'));
      }
      await _deleteDocs(posts.docs.map((d) => d.reference));
    });
    await _safe('lostPets',
            () => _deleteAll(_db.collection('lostPets').where('uid', isEqualTo: uid)));
    await _safe('questions',
            () => _deleteAll(_db.collection('questions').where('uid', isEqualTo: uid)));

    // チャット（メッセージも一緒に）
    await _safe('chats', () async {
      final chats = await _db
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();
      for (final c in chats.docs) {
        await _deleteAll(c.reference.collection('messages'));
      }
      await _deleteDocs(chats.docs.map((d) => d.reference));
    });

    // 団体・病院のアカウントだった場合
    await _safe('adoptions',
            () => _deleteAll(_db.collection('adoptions').where('orgId', isEqualTo: uid)));
    await _safe('volunteers',
            () => _deleteAll(_db.collection('volunteers').where('orgId', isEqualTo: uid)));
    await _safe('organizations',
            () => _db.collection('organizations').doc(uid).delete());
    await _safe('hospitals', () => _db.collection('hospitals').doc(uid).delete());

    // 最後に、プロフィール本体と非公開の情報（生年月日など）を、いっしょに消す
    final privateDocs = await userRef.collection('private').get();
    final last = _db.batch();
    for (final d in privateDocs.docs) {
      last.delete(d.reference);
    }
    last.delete(userRef);
    await last.commit();
  }

  Future<String?> _askPassword() async {
    _pwCtrl.clear();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('パスワードの確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本人確認のため、今ログインしているパスワードを入力してください。',
                style: TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 12),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'パスワード'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, _pwCtrl.text),
              child: const Text('削除する', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isDeleting) return;

    final hasPassword =
    user.providerData.any((p) => p.providerId == 'password');
    if (!hasPassword || user.email == null) {
      _snack('このアカウントは、アプリ内では削除できません。animatch.jp@gmail.com に連絡してください');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      // 主催しているイベントが残っていたら、先に消してもらう
      final events = await _db
          .collection('events')
          .where('organizerUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (events.docs.isNotEmpty) {
        _snack('あなたが主催したイベントが残っています。先に「イベント」の画面で削除してください');
        return;
      }

      // 本人確認（パスワード）
      final password = await _askPassword();
      if (password == null || password.isEmpty) return;
      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          _snack('パスワードが違います');
        } else if (e.code == 'too-many-requests') {
          _snack('何度も失敗したため、しばらくしてからやり直してください');
        } else {
          _snack('本人確認に失敗しました（${e.code}）');
        }
        return;
      }

      // データを消してから、ログイン情報を消す
      await _purgeUserData(user.uid);
      await user.delete();

      if (mounted) setState(() => _step = 2);
    } on FirebaseAuthException catch (e) {
      _snack('削除に失敗しました（${e.code}）。もう一度ためしてください');
    } catch (e) {
      _snack('エラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('アカウント削除',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        automaticallyImplyLeading: _step != 2 && !_isDeleting,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 0
            ? _buildStep1()
            : _step == 1
            ? _buildStep2()
            : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アカウントを削除しますか？',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[300]!)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ 削除前にご確認ください',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              SizedBox(height: 8),
              Text(
                  '・アカウント、プロフィール、ペットの情報、投稿、チャット履歴が削除されます\n'
                      '・削除後は元に戻せません\n'
                      '・主催したイベントが残っている場合は、先にイベントを削除してください',
                  style: TextStyle(
                      fontSize: 13, color: Colors.orange, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16)),
          child: Text(
              '次のものは、削除したあとも一部が残ることがあります。\n'
                  '・ほかの人の投稿につけたコメント、イベントの参加の記録\n'
                  '・保存してある写真ファイル\n'
                  '完全に消したいときは、animatch.jp@gmail.com に連絡してください。',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[700], height: 1.6)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('次へ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本当に削除しますか？',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red[300]!)),
          child: Column(
            children: [
              const Text('🥹', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('寂しいです...',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const SizedBox(height: 8),
              Text('動物たちのために\n一緒に頑張りましょう🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _confirmed = !_confirmed),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: _confirmed ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _confirmed ? Colors.red : Colors.grey[400]!)),
                child: _confirmed
                    ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('削除すると元に戻せないことを理解しました',
                    style:
                    TextStyle(fontSize: 14, color: Color(0xFF3D2B1F))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmed && !_isDeleting ? _deleteAccount : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isDeleting
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Text('削除する',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE8845A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('やっぱりやめる',
                style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE8845A),
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text('🐾', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 20),
        const Text('アカウントを削除しました',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('ご利用ありがとうございました🐾\nまたいつでもお待ちしています',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[600], height: 1.7)),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('トップページへ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}