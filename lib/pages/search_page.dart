import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pet_brag_page.dart';
import 'adoption_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _categoryChip(String value, String label) {
    final sel = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFFE8845A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: sel
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: sel ? Colors.white : Colors.grey[700],
                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('みんなの投稿を探す 🔍',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'ペットの名前や特徴で検索...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE8845A)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _categoryChip('all', 'すべて'),
                _categoryChip('brag', '🐾 ペット自慢'),
                _categoryChip('adoption', '🏠 里親募集'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (_category == 'all' || _category == 'brag') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('🐾 ペット自慢',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                  ),
                  _BragResults(query: _query),
                  const SizedBox(height: 12),
                ],
                if (_category == 'all' || _category == 'adoption') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('🏠 里親募集',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                  ),
                  _AdoptionResults(query: _query),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _BragResults extends StatelessWidget {
  final String query;
  const _BragResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('petBrags')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs.where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['petName'] ?? '').toString();
          final theme = (data['theme'] ?? '').toString();
          final comment = (data['comment'] ?? '').toString();
          return name.contains(query) || theme.contains(query) || comment.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('見つかりませんでした', style: TextStyle(color: Colors.grey[500])),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PetBragPage())),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (data['imageUrl'] ?? '').toString().isNotEmpty
                          ? Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                          width: 56, height: 56, color: Colors.orange[50],
                          child: const Center(child: Text('🐾'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['petName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                          Text(data['theme'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8845A)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdoptionResults extends StatelessWidget {
  final String query;
  const _AdoptionResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoptions')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs.where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['petName'] ?? '').toString();
          final type = (data['type'] ?? '').toString();
          final personality = (data['personality'] ?? '').toString();
          return name.contains(query) || type.contains(query) || personality.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('見つかりませんでした', style: TextStyle(color: Colors.grey[500])),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdoptionPage())),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (data['imageUrl'] ?? '').toString().isNotEmpty
                          ? Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                          width: 56, height: 56, color: Colors.green[50],
                          child: const Center(child: Text('🐾'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['petName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                          Text('${data['type'] ?? ''} · ${data['orgName'] ?? ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8845A)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
