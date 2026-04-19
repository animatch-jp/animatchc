import 'profile_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'root_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全ての項目を入力してください'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが一致しません'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは6文字以上にしてください'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
        );

      }
    } on FirebaseAuthException catch (e) {
      String message = '登録に失敗しました';
      if (e.code == 'email-already-in-use') message = 'このメールアドレスは既に使用されています';
      if (e.code == 'invalid-email') message = 'メールアドレスの形式が正しくありません';
      if (e.code == 'weak-password') message = 'パスワードが弱すぎます';
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
      backgroundColor: const Color(0xFFFFFFF5F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8845A), Color(0xFFF4A261)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10, offset: const Offset(0, 4),
                      )],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('🐾', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('AniMatch',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('Find Your Wild Connection',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('新規登録',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('アカウントを作成してください',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFE8A598)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8A598)),
                      ),
                      filled: true, fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'パスワード（6文字以上）',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE8A598)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8A598)),
                      ),
                      filled: true, fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'パスワード確認',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE8A598)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8A598)),
                      ),
                      filled: true, fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('登録する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ログインに戻る',
                          style: TextStyle(color: Color(0xFFE8845A))),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
