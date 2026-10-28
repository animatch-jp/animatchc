import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

// 運営が一時停止したアカウントに出す画面
class SuspendedPage extends StatelessWidget {
  const SuspendedPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_outline, size: 64, color: Color(0xFFE8845A)),
                const SizedBox(height: 16),
                const Text('このアカウントは一時停止中です',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                const SizedBox(height: 12),
                Text(
                  '利用規約に反する可能性がある内容が報告されたため、運営が確認しています。\nご不明な点は animatch.jp@gmail.com までご連絡ください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => _logout(context),
                  child: const Text('ログアウト'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
