import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _bioCtrl;
  String? _selectedPrefecture;
  String? _selectedAnimal;
  String? _selectedGender;
  String? _selectedShowing;
  String? _selectedRelation;
  List<String> _selectedActivities = [];
  String? _selectedPurpose;
  bool _isLoading = false;

  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  final List<Map<String, String>> _animals = [
    {'name': '犬', 'emoji': '🐕'},
    {'name': '猫', 'emoji': '🐱'},
    {'name': 'ハムスター', 'emoji': '🐹'},
    {'name': 'うさぎ', 'emoji': '🐰'},
    {'name': '爬虫類', 'emoji': '🦎'},
    {'name': '鳥', 'emoji': '🦜'},
    {'name': 'シマリス', 'emoji': '🐿️'},
    {'name': 'モルモット', 'emoji': '🐾'},
    {'name': 'その他', 'emoji': '🐾'},
  ];

  final List<Map<String, String>> _genders = [
    {'name': '男性', 'emoji': '👨'},
    {'name': '女性', 'emoji': '👩'},
    {'name': 'その他・回答しない', 'emoji': '🌈'},
  ];

  final List<Map<String, String>> _showings = [
    {'name': '男性', 'emoji': '👨'},
    {'name': '女性', 'emoji': '👩'},
    {'name': '全員', 'emoji': '👥'},
  ];

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
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userData['name'] ?? '');
    _ageCtrl = TextEditingController(text: '${widget.userData['age'] ?? ''}');
    _bioCtrl = TextEditingController(text: widget.userData['bio'] ?? '');
    _selectedPrefecture = widget.userData['prefecture'];
    _selectedAnimal = widget.userData['animal'];
    _selectedGender = widget.userData['gender'];
    _selectedShowing = widget.userData['showing'];
    _selectedRelation = widget.userData['relation'];
    _selectedActivities = List<String>.from(widget.userData['activities'] ?? []);
    _selectedPurpose = widget.userData['purpose'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください'), backgroundColor: Colors.red),
      );
      return;
    }
    final age = int.tryParse(_ageCtrl.text) ?? 0;
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AniMatchは18歳以上が対象です'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameCtrl.text.trim(),
          'age': age,
          'prefecture': _selectedPrefecture,
          'animal': _selectedAnimal,
          'gender': _selectedGender,
          'showing': _selectedShowing,
          'bio': _bioCtrl.text.trim(),
          'relation': _selectedRelation,
          'activities': _selectedActivities,
          'purpose': _selectedPurpose,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存しました！'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('🔥 保存エラー: $e');
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
        appBar: AppBar(
          title: const Text('プロフィール編集',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF3D2B1F)),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: const Text('保存',
                  style: TextStyle(color: Color(0xFFE8845A),
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(
            color: Color(0xFFE8845A)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 名前
              const Text('ニックネーム',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'ニックネームを入力',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE8845A))),
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // 年齢
          const Text('年齢',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '18以上の年齢を入力',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE8845A))),
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // 都道府県
          const Text('都道府県',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPrefecture,
                hint: const Text('都道府県を選択'),
                isExpanded: true,
                items: _prefectures.map((p) =>
                    DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedPrefecture = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 好きな動物
          const Text('好きな動物',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _animals.map((a) {
              final sel = _selectedAnimal == a['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedAnimal = a['name']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8845A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFE8845A)
                              : Colors.grey.shade300)),
                  child: Text('${a['emoji']} ${a['name']}',
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 性別
          const Text('性別',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _genders.map((g) {
              final sel = _selectedGender == g['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedGender = g['name']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8845A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFE8845A)
                              : Colors.grey.shade300)),
                  child: Text('${g['emoji']} ${g['name']}',
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 表示する相手
          const Text('表示する相手',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _showings.map((s) {
              final sel = _selectedShowing == s['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedShowing = s['name']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8845A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFE8845A)
                              : Colors.grey.shade300)),
                  child: Text('${s['emoji']} ${s['name']}',
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
                const SizedBox(height: 16),
                // 自己紹介
                const Text('自己紹介',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '動物への想いや自己紹介を書いてください',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE8845A))),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // 動物との関わり方
                const Text('動物との関わり方',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _relations.map((r) {
                    final sel = _selectedRelation == r['name'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRelation = r['name']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8845A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFFE8845A)
                                    : Colors.grey.shade300)),
                        child: Text('${r['emoji']} ${r['name']}',
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 一緒にやりたいこと
                const Text('一緒にやりたいこと',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _activities.map((a) {
                    final sel = _selectedActivities.contains(a['name']);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (sel) {
                          _selectedActivities.remove(a['name']);
                        } else {
                          _selectedActivities.add(a['name']!);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8845A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFFE8845A)
                                    : Colors.grey.shade300)),
                        child: Text('${a['emoji']} ${a['name']}',
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 利用目的
                const Text('利用目的',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _purposes.map((p) {
                    final sel = _selectedPurpose == p['name'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPurpose = p['name']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8845A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFFE8845A)
                                    : Colors.grey.shade300)),
                        child: Text('${p['emoji']} ${p['name']}',
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('保存する',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
          ),
        ),
    );
  }
}
