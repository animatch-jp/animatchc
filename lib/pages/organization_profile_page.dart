import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class OrganizationProfilePage extends StatelessWidget {
  final String orgId;

  const OrganizationProfilePage({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('団体プロフィール 🏢',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8845A)));
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('団体情報が見つかりません'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isApproved = data['status'] == 'approved';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('✅ AniMatch認証済み団体',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 10),
                      Text(data['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      if ((data['area'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(data['area'] ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('活動内容・実績',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                Text(data['activityDescription'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.6)),
                const SizedBox(height: 20),
                const Text('連絡先',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                Text(data['contactInfo'] ?? '',
                    style: const TextStyle(fontSize: 14)),
                if ((data['websiteUrl'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('公式サイト・SNS',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 8),
                  Text(data['websiteUrl'] ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF2D6A4F))),
                ],
                if (myUid != orgId) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            userName: data['name'] ?? '',
                            userEmoji: '🏢',
                            uid: orgId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('この団体にチャットで問い合わせる'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
