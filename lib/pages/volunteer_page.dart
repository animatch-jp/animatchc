import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';
import 'organization_profile_page.dart';
import 'notification_prefs.dart';


class VolunteerPage extends StatelessWidget {
  const VolunteerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ボランティア募集',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('volunteers')
            .where('status', isEqualTo: 'open')
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
                child: Text('まだボランティア募集の投稿はありません',
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
                onTap: () => VolunteerPage.showDetail(context, docs[i].id, data),

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
                            height: 200,
                            fit: BoxFit.cover)
                            : Container(
                          width: double.infinity,
                          height: 200,
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          child: const Center(
                              child: Text('🤝', style: TextStyle(fontSize: 60))),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF3D2B1F))),
                            const SizedBox(height: 4),
                            Text(data['location'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text('🏢 ${data['orgName'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFE8845A))),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('volunteers')
                                  .doc(docs[i].id)
                                  .collection('interested')
                                  .snapshots(),
                              builder: (context, snap) {
                                final count = snap.data?.docs.length ?? 0;
                                if (count == 0) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('🙋 興味あります $count人',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                );
                              },
                            ),
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
  static void showDetail(BuildContext context, String volunteerId, Map<String, dynamic> data) {
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
                    width: double.infinity, height: 260, fit: BoxFit.cover)
                    : Container(
                  width: double.infinity,
                  height: 260,
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  child: const Center(child: Text('🤝', style: TextStyle(fontSize: 60))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    if ((data['location'] ?? '').toString().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['location'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    if ((data['schedule'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['schedule'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                    const Divider(height: 32),
                    if ((data['description'] ?? '').toString().isNotEmpty) ...[
                      const Text('活動内容',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(data['description'], style: const TextStyle(fontSize: 14, height: 1.5)),
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
                          backgroundColor: const Color(0xFFE8845A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    _VolunteerInterestSection(volunteerId: volunteerId, orgId: data['orgId'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _VolunteerInterestSection extends StatefulWidget {
  final String volunteerId;
  final String orgId;
  const _VolunteerInterestSection({required this.volunteerId, required this.orgId});

  @override
  State<_VolunteerInterestSection> createState() => _VolunteerInterestSectionState();
}

class _VolunteerInterestSectionState extends State<_VolunteerInterestSection> {
  bool _isSending = false;

  Future<void> _toggleInterest(bool alreadyInterested) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _isSending = true);

    final ref = FirebaseFirestore.instance
        .collection('volunteers')
        .doc(widget.volunteerId)
        .collection('interested')
        .doc(myUid);

    if (alreadyInterested) {
      await ref.delete();
    } else {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final myName = userDoc.data()?['name'] as String? ?? '名無しさん';
      await ref.set({
        'uid': myUid,
        'name': myName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (await shouldSendNotification(widget.orgId, 'コメント・メッセージ')) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.orgId)
            .collection('items')
            .add({
          'type': 'volunteerInterest',
          'emoji': '🙋',
          'title': 'ボランティアに興味を持った人がいます',
          'desc': '$myName さんが、ボランティア募集に興味ありを押しました',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }


    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = myUid != null && myUid == widget.orgId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteers')
          .doc(widget.volunteerId)
          .collection('interested')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;
        final amInterested = myUid != null && docs.any((d) => d.id == myUid);

        if (isOwner) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8845A).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🙋 興味ありますした人（$count人）',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  Text('まだいません', style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            userName: data['name'] ?? '',
                            userEmoji: '🐾',
                            uid: doc.id,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Expanded(child: Text(data['name'] ?? '', style: const TextStyle(fontSize: 13))),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFFE8845A)),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSending ? null : () => _toggleInterest(amInterested),
            icon: _isSending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8845A)))
                : Icon(amInterested ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFE8845A)),
            label: Text(amInterested ? '興味あります済み（$count人）' : '興味あります（$count人）'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE8845A),
              side: const BorderSide(color: Color(0xFFE8845A)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      },
    );
  }
}
