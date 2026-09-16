import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_home_page.dart';
import 'login_page.dart';

class HospitalPendingPage extends StatelessWidget {
  const HospitalPendingPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FC),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('hospitals').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA)));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final status = data?['status'] ?? 'pending';

            if (status == 'approved') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HospitalHomePage()),
                      (route) => false,
                );
              });
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA)));
            }

            if (status == 'rejected') {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('😢', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 20),
                      const Text('申請は承認されませんでした',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('内容についてご不明な点があれば、お問い合わせください。',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DA8DA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 20),
                    const Text('審査中です', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    const Text(
                      'ご申請ありがとうございます。\n内容を確認の上、審査を行います。\n承認されると、この画面が自動で切り替わります。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => _logout(context),
                      child: const Text('ログアウトする', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
