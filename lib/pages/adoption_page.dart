import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';
import 'organization_profile_page.dart';

void showAdoptionDetail(BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: data['imageUrl'] != null &&
                  (data['imageUrl'] as String).isNotEmpty
                  ? Image.network(data['imageUrl'] as String,
                  width: double.infinity, height: 300, fit: BoxFit.cover)
                  : Container(
                width: double.infinity,
                height: 300,
                color: Colors.orange[50],
                child: const Center(child: Text('🐾', style: TextStyle(fontSize: 60))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['petName'] ?? '',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 8),
                  Text('${data['type'] ?? ''} ・ ${data['age'] ?? ''} ・ ${data['gender'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const Divider(height: 32),
                  if ((data['personality'] ?? '').toString().isNotEmpty) ...[
                    const Text('性格・特徴',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(data['personality'], style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 16),
                  ],
                  if ((data['background'] ?? '').toString().isNotEmpty) ...[
                    const Text('保護に至った経緯',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(data['background'], style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 16),
                  ],
                  if ((data['conditions'] ?? '').toString().isNotEmpty) ...[
                    const Text('希望する里親の条件',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(data['conditions'], style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                  ],
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrganizationProfilePage(orgId: data['orgId'] ?? ''),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Text('🏢', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(data['orgName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            userName: data['orgName'] ?? '',
                            userEmoji: '🏢',
                            uid: data['orgId'],
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
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdoptionPage extends StatelessWidget {
  const AdoptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('里親募集',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adoptions')
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8845A)));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('まだ里親募集の投稿はありません',
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => showAdoptionDetail(context, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                        child: data['imageUrl'] != null &&
                            (data['imageUrl'] as String).isNotEmpty
                            ? Image.network(data['imageUrl'] as String,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover)
                            : Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.orange[50],
                          child: const Center(
                              child: Text('🐾', style: TextStyle(fontSize: 60))),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(data['petName'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF3D2B1F))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(data['type'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFF2D6A4F))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${data['age'] ?? ''} ・ ${data['gender'] ?? ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text('🏢 ${data['orgName'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFE8845A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
