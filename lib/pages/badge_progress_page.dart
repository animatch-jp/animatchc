import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pet_themes.dart';

class BadgeProgressPage extends StatefulWidget {
  const BadgeProgressPage({super.key});

  @override
  State<BadgeProgressPage> createState() => _BadgeProgressPageState();
}

class _BadgeProgressPageState extends State<BadgeProgressPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _postedThemes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPostedThemes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPostedThemes() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('petBrags')
        .where('uid', isEqualTo: myUid)
        .get();

    setState(() {
      _postedThemes = snapshot.docs
          .map((d) => (d.data())['theme'] as String? ?? '')
          .toSet();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        title: const Text('🏅 お題コンプリート状況',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE8845A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE8845A),
          tabs: const [
            Tab(text: 'うちの子系(30)'),
            Tab(text: '誰でも系(20)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)))
          : TabBarView(
        controller: _tabController,
        children: [
          _ThemeProgressList(
            themes: petBragThemes,
            postedThemes: _postedThemes,
            badgeLabel: 'うちの子お題マスターまで',
          ),
          _ThemeProgressList(
            themes: discoveryThemes,
            postedThemes: _postedThemes,
            badgeLabel: '発見マスターまで',
          ),
        ],
      ),
    );
  }
}

class _ThemeProgressList extends StatelessWidget {
  final List<String> themes;
  final Set<String> postedThemes;
  final String badgeLabel;

  const _ThemeProgressList({
    required this.themes,
    required this.postedThemes,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = themes.where((t) => postedThemes.contains(t)).length;
    final total = themes.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(badgeLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Text('$doneCount / $total 個 達成',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: themes.map((theme) {
              final done = postedThemes.contains(theme);
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFF2D6A4F)
                            : Colors.grey[200],
                      ),
                      child: done
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(theme,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            done ? FontWeight.w600 : FontWeight.normal,
                            color: done
                                ? const Color(0xFF3D2B1F)
                                : Colors.grey[400])),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
