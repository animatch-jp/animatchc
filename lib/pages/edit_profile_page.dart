import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import '../services/age_utils.dart';
import '../services/name_rules.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _mottoCtrl;
  String? _selectedPrefecture;
  List<String> _selectedAnimals = [];
  String? _selectedGender;
  String? _selectedRelation;
  List<String> _selectedInterests = [];
  List<String> _selectedSpots = [];
  bool _isLoading = false;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  DateTime? _birthDate;
  bool _birthLocked = false; // すでに登録済みなら、変更できない
  bool _birthLoaded = false;

  final List<Map<String, String>> _interests = [
    {'name': '動物系YouTube鑑賞', 'emoji': '📺'},
    {'name': '動物園・水族館巡り', 'emoji': '🦁'},
    {'name': '猫カフェ巡り', 'emoji': '☕'},
    {'name': 'ペット用品集め', 'emoji': '🧸'},
    {'name': '動物の写真を撮る', 'emoji': '📷'},
    {'name': '動物の本を読む', 'emoji': '📚'},
  ];

  final List<Map<String, String>> _spots = [
    {'name': '動物園', 'emoji': '🦁'},
    {'name': '水族館', 'emoji': '🐠'},
    {'name': '猫カフェ', 'emoji': '🐱'},
    {'name': 'ドッグラン', 'emoji': '🐕'},
    {'name': '散歩コース', 'emoji': '🚶'},
    {'name': 'ペットショップ', 'emoji': '🛍️'},
  ];


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

  final List<Map<String, String>> _relations = [
    {'name': '飼ってる', 'emoji': '🏠'},
    {'name': '見るのが好き', 'emoji': '👀'},
    {'name': 'ガチ勢', 'emoji': '🔥'},
    {'name': 'これから飼いたい', 'emoji': '🌱'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userData['name'] ?? '');
    _bioCtrl = TextEditingController(text: widget.userData['bio'] ?? '');
    _mottoCtrl = TextEditingController(text: widget.userData['motto'] ?? '');
    _selectedPrefecture = widget.userData['prefecture'];
    final _animalStr = widget.userData['animal'] as String? ?? '';
    _selectedAnimals = _animalStr.isEmpty ? [] : _animalStr.split('、');
    _selectedGender = widget.userData['gender'];
    _selectedRelation = widget.userData['relation'];
    _selectedInterests = List<String>.from(widget.userData['interests'] ?? []);
    _selectedSpots = List<String>.from(widget.userData['spots'] ?? []);
    _profileImageUrl = widget.userData['profileImageUrl'];
    _loadBirthDate();
  }

  Future<void> _loadBirthDate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('private')
            .doc('birth')
            .get();
        final birth = AgeUtils.parse(doc.data()?['birthDate'] as String?);
        if (birth != null && mounted) {
          setState(() {
            _birthDate = birth;
            _birthLocked = true;
          });
        }
      } catch (e) {
        print('🔥 生年月日の読み込みエラー: $e');
      }
    }
    if (mounted) setState(() => _birthLoaded = true);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: '生年月日を選択',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Widget _buildBirthSection() {
    if (!_birthLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('読み込み中…', style: TextStyle(color: Colors.grey)),
      );
    }
    final note = TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5);
    if (_birthLocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 10),
                Text(AgeUtils.display(_birthDate!),
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF3D2B1F))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('生年月日は変更できません。間違いがある場合は、お問い合わせからご連絡ください。',
              style: note),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    color: Color(0xFFE8A598), size: 18),
                const SizedBox(width: 10),
                Text(
                  _birthDate == null
                      ? '生年月日を選択'
                      : AgeUtils.display(_birthDate!),
                  style: TextStyle(
                      fontSize: 15,
                      color: _birthDate == null
                          ? Colors.grey[600]
                          : const Color(0xFF3D2B1F)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            '現在の登録年齢：${widget.userData['age'] ?? '-'}歳\n'
                '生年月日を登録すると、年齢が自動で更新されるようになります。'
                '生年月日は、あなた以外には表示されません。一度登録すると変更できません。',
            style: note),
      ],
    );
  }


  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _mottoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('名前を入力してください'),
            backgroundColor: Colors.red),
      );
      return;
    }
    // 名前を変えたときだけ、使える名前か確かめる
    if (_nameCtrl.text.trim() != (widget.userData['name'] ?? '').toString().trim()) {
      final nameError = await NameRules.check(_nameCtrl.text,
          myUid: FirebaseAuth.instance.currentUser?.uid);
      if (!mounted) return;
      if (nameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nameError), backgroundColor: Colors.red),
        );
        return;
      }
    }
// 生年月日を、今回はじめて登録するときだけ、年齢を計算する
    int? newAge;
    if (_birthDate != null && !_birthLocked) {
      newAge = AgeUtils.calculate(_birthDate!);
      if (newAge < 13) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('AniMatchは13歳以上の方が対象です'),
              backgroundColor: Colors.red),
        );
        return;
      }
      if (newAge > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('正しい生年月日を選択してください'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (_selectedAnimals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('好きな動物を選択してください'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final userRef = db.collection('users').doc(user.uid);
        final updates = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'prefecture': _selectedPrefecture,
          'animal': _selectedAnimals.join('、'),
          'gender': _selectedGender,
          'bio': _bioCtrl.text.trim(),
          'motto': _mottoCtrl.text.trim(),
          'relation': _selectedRelation,
          'interests': _selectedInterests,
          'spots': _selectedSpots,
          'profileImageUrl': _profileImageUrl ?? '',
        };
        final batch = db.batch();
        if (newAge != null) {
          updates['age'] = newAge;
          // 生年月日は、本人しか読めない場所に保存する
          batch.set(userRef.collection('private').doc('birth'), {
            'birthDate': AgeUtils.format(_birthDate!),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        batch.update(userRef, updates);
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('保存しました！'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('🔥 保存エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('エラー: $e'),
              backgroundColor: Colors.red),
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
            style: TextStyle(
                fontWeight: FontWeight.w900,
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
                style: TextStyle(
                    color: Color(0xFFE8845A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
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
            Center(
              child: GestureDetector(
                onTap: () async {
                  setState(() => _isUploadingImage = true);
                  final url =
                  await CloudinaryService.pickAndUploadImage();
                  setState(() {
                    if (url != null) _profileImageUrl = url;
                    _isUploadingImage = false;
                  });
                  if (url == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('画像のアップロードに失敗しました。もう一度お試しください'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },

                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8845A)
                              .withOpacity(0.1),
                          border: Border.all(
                              color: const Color(0xFFE8845A),
                              width: 2)),
                      child: _isUploadingImage
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE8845A)))
                          : _profileImageUrl != null &&
                          _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                          child: Image.network(
                            _profileImageUrl!,
                            width: 100, height: 100,
                            fit: BoxFit.cover,
                          ))
                          : const Center(
                          child: Text('🐾',
                              style:
                              TextStyle(fontSize: 40))),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8845A),
                            shape: BoxShape.circle),
                        child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const Text('生年月日',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            _buildBirthSection(),
            const SizedBox(height: 16),
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
            const Text('好きな動物（複数選択可）',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _animals.map((a) {
                final sel = _selectedAnimals.contains(a['name']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedAnimals.remove(a['name']);
                    } else {
                      _selectedAnimals.add(a['name']!);
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
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
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
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
            const Text('ひとこと・モットー（任意）',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _mottoCtrl,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: '例：猫カフェ巡りが趣味です',
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
            const Text('好きなこと（複数選択OK）',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _interests.map((it) {
                final sel = _selectedInterests.contains(it['name']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedInterests.remove(it['name']);
                    } else {
                      _selectedInterests.add(it['name']!);
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
                    child: Text('${it['emoji']} ${it['name']}',
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('よく行く場所（複数選択OK）',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _spots.map((s) {
                final sel = _selectedSpots.contains(s['name']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedSpots.remove(s['name']);
                    } else {
                      _selectedSpots.add(s['name']!);
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
                    child: Text('${s['emoji']} ${s['name']}',
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
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
                    style: TextStyle(
                        fontSize: 16,
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