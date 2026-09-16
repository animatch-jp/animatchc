import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'organization_signup_page.dart';
import 'organization_home_page.dart';
import 'organization_pending_page.dart';


class OrganizationLoginPage extends StatefulWidget {
  const OrganizationLoginPage({super.key});

  @override
  State<OrganizationLoginPage> createState() => _OrganizationLoginPageState();
}

class _OrganizationLoginPageState extends State<OrganizationLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showPasswordReset() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('パスワードをリセット'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('登録したメールアドレスを入力してください',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8845A))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: emailCtrl.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('パスワードリセットメールを送信しました📧'),
                      backgroundColor: Color(0xFF2D6A4F),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.code == 'user-not-found'
                          ? 'このメールアドレスは登録されていません'
                          : 'エラーが発生しました'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {

    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メールアドレスとパスワードを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = userCredential.user?.uid;
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(uid)
          .get();

      if (!orgDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('団体アカウントが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final status = orgDoc.data()?['status'] ?? 'pending';

      if (status == 'pending') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrganizationPendingPage()),
          );
        }
        return;
      }


      if (status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('申請内容をご確認の上、お問い合わせください'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizationHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'ログインに失敗しました';
      if (e.code == 'user-not-found') message = 'アカウントが見つかりません';
      if (e.code == 'wrong-password') message = 'パスワードが間違っています';
      if (e.code == 'invalid-email') message = 'メールアドレスの形式が正しくありません';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('団体・保護主ログイン',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏢', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('団体・保護主アカウント',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('里親募集・迷子情報などを投稿できます',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 32),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: Color(0xFFE8A598)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'パスワード',
                prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0xFFE8A598)),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showPasswordReset,
                child: const Text('パスワードを忘れた方',
                    style: TextStyle(color: Color(0xFFE8A598))),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8845A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ログイン',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const OrganizationSignupPage())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8845A),
                  side: const BorderSide(color: Color(0xFFE8845A)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('新規登録申請はこちら',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
