import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'root_page.dart';

class ProfileSetupPage2 extends StatefulWidget {
  final String name;
  final int age;
  final String prefecture;
  final String animal;
  final String? gender;
  final String? showing;

  const ProfileSetupPage2({
    super.key,
    required this.name,
    required this.age,
    required this.prefecture,
    required this.animal,
    this.gender,
    this.showing,
  });

  @override
  State<ProfileSetupPage2> createState() => _ProfileSetupPage2State();
}

class _ProfileSetupPage2State extends State<ProfileSetupPage2> {
  final _bioCtrl = TextEditingController();
  String? _selectedRelation;
  List<String> _selectedActivities = [];
  String? _selectedPurpose;
  bool _isLoading = false;

  final List<Map<String, String>> _relations = [
    {'name': '飼ってる', 'emoji': '🏠'},
    {'name': '見るのが好き', 'emoji': '👀'},
    {'name': 'ガチ勢', 'emoji': '🔥'},
    {'name': 'これから飼いたい', 'emoji': '🌱'},
  ];

  final List<Map<String, String>> _activities = [
    {'name': '散歩', 'emoji': '🐾'},
    {'name': 'カフェ', 'emoji': '☕'},
    {'name': 'キャンプ', 'emoji': '🏕️'},
    {'name': '写真撮影', 'emoji': '📷'},
    {'name': 'イベント', 'emoji': '🎉'},
    {'name': '料理', 'emoji': '🍳'},
    {'name': '映画', 'emoji': '🎬'},
    {'name': '旅行', 'emoji': '✈️'},
    {'name': '運動', 'emoji': '🏃'},
    {'name': '読書', 'emoji': '📚'},
  ];

  final List<Map<String, String>> _purposes = [
    {'name': '動物好き友達探し', 'emoji': '🐾'},
    {'name': '散歩仲間を探す', 'emoji': '🐕'},
    {'name': '里親を探す', 'emoji': '🏠'},
    {'name': '保護活動仲間', 'emoji': '💪'},
    {'name': '恋愛', 'emoji': '❤️'},
  ];

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_selectedRelation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動物との関わり方を選択してください'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用目的を選択してください'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': widget.name,
          'age': widget.age,
          'prefecture': widget.prefecture,
          'animal': widget.animal,
          'gender': widget.gender,
          'showing': widget.showing,
          'bio': _bioCtrl.text.trim(),
          'relation': _selectedRelation,
          'activities': _selectedActivities,
          'purpose': _selectedPurpose,
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootPage()),
        );
      }
    } catch (e) {
      print('🔥 Firestoreエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('プロフィール設定', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('STEP 2 / 2', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('あなたのことをもっと教えてください🐾', style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('自己紹介', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '動物への想いや自己紹介を書いてください',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8845A)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('動物との関わり方', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _relations.map((r) {
                      final isSelected = _selectedRelation == r['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRelation = r['name']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8845A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFFE8845A) : Colors.grey.shade300),
                          ),
                          child: Text(
                            '${r['emoji']} ${r['name']}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('一緒にやりたいこと', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activities.map((a) {
                      final isSelected = _selectedActivities.contains(a['name']);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedActivities.remove(a['name']);
                          } else {
                            _selectedActivities.add(a['name']!);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8845A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFFE8845A) : Colors.grey.shade300),
                          ),
                          child: Text(
                            '${a['emoji']} ${a['name']}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('利用目的', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _purposes.map((p) {
                      final isSelected = _selectedPurpose == p['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPurpose = p['name']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8845A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFFE8845A) : Colors.grey.shade300),
                          ),
                          child: Text(
                            '${p['emoji']} ${p['name']}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('はじめる🐾', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
