import 'edit_profile_page.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'footprint_page.dart';
import 'delete_account_page.dart';
import 'notification_settings_page.dart';
import 'premium_page.dart';
import 'abuse_report_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import 'values_page.dart';
import 'notification_page.dart';
import 'verify_page.dart';
import 'privacy_page.dart';
import 'terms_page.dart';
import 'contact_page.dart';
import 'friends_page.dart';
import 'login_page.dart';

class PetData {
  String name;
  String type;
  int age;
  String bio;
  List<String> tags;
  String avatarPath;
  String? imagePath;

  PetData({
    required this.name,
    required this.type,
    required this.age,
    required this.bio,
    required this.tags,
    required this.avatarPath,
    this.imagePath,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _provider = globalProvider;

  Map<String, dynamic>? _userData;
  String _userName = '';
  int _userAge = 0;
  String _userPrefecture = '';
  String _userAnimal = '';
  String _userBio = '';
  String _userRelation = '';
  List<String> _userActivities = [];
  String _userPurpose = '';
  bool _isLoading = true;

  final List<PetData> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          _userData = data;
          setState(() {
            _userName = data['name'] ?? '';
            _userAge = data['age'] ?? 0;
            _userPrefecture = data['prefecture'] ?? '';
            _userAnimal = data['animal'] ?? '';
            _userBio = data['bio'] ?? '';
            _userRelation = data['relation'] ?? '';
            _userActivities = List<String>.from(data['activities'] ?? []);
            _userPurpose = data['purpose'] ?? '';
            _isLoading = false;
          });
          final petsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('pets')
              .get();
          setState(() {
            _pets.clear();
            for (final doc in petsSnapshot.docs) {
              final data = doc.data();
              _pets.add(PetData(
                name: data['name'] ?? '',
                type: data['type'] ?? '',
                age: data['age'] ?? 1,
                bio: data['bio'] ?? '',
                tags: List<String>.from(data['tags'] ?? []),
                avatarPath: '',
              ));
            }
          });

        }
      }
    } catch (e) {
      print('🔥 データ取得エラー: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _addPet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddPetSheet(onAdd: (pet) {
          setState(() => _pets.add(pet));
          Navigator.pop(context);
        }),
      ),
    );
  }

  void _editPet(int index) {
    final pet = _pets[index];
    final nameCtrl = TextEditingController(text: pet.name);
    final typeCtrl = TextEditingController(text: pet.type);
    final ageCtrl = TextEditingController(text: '${pet.age}');
    final bioCtrl = TextEditingController(text: pet.bio);
    List<String> selectedTags = List.from(pet.tags);
    String? selectedImagePath = pet.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ペット情報を編集',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _EditField(label: '名前', ctrl: nameCtrl),
                const SizedBox(height: 12),
                _EditField(label: '種類', ctrl: typeCtrl),
                const SizedBox(height: 12),
                _EditField(label: '年齢', ctrl: ageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),



                const SizedBox(height: 12),
                _EditField(label: '自己紹介', ctrl: bioCtrl, maxLines: 3),
                const SizedBox(height: 16),
                const Text('性格タグ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['元気', '人懐こい', 'おっとり', 'やんちゃ',
                    '甘えん坊', '独立心強い', '賢い', '遊び好き']
                      .map((tag) {
                    final sel = selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setModalState(() => sel
                          ? selectedTags.remove(tag)
                          : selectedTags.add(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(tag,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white : Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        pet.name = nameCtrl.text;
                        pet.type = typeCtrl.text;
                        pet.age = int.tryParse(ageCtrl.text) ?? pet.age;
                        pet.bio = bioCtrl.text;
                        pet.tags = selectedTags;
                        pet.imagePath = selectedImagePath;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('保存',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F5),
        body: Center(child: CircularProgressIndicator(
          color: Color(0xFFE8845A),
        )),
      );
    }

    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('プロフィール',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FootprintPage())),
              icon: const Text('👣', style: TextStyle(fontSize: 22)),
            ),
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationPage())),
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: Color(0xFFE8845A), size: 28),
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28))),
            child: Column(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8845A).withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0] : '🐾',
                        style: const TextStyle(fontSize: 44,
                            color: Color(0xFFE8845A),
                            fontWeight: FontWeight.bold),
                      )),
                ),
                const SizedBox(height: 12),
                Text(_userName,
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D2B1F))),
                Text('$_userAge歳・$_userPrefecture',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('$_userAnimal好き',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  _userData?['gender'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8845A), Color(0xFFFFCC80)]),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('ビギナー🐾',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VerifyPage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF2D6A4F).withOpacity(0.3))),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Color(0xFF2D6A4F), size: 16),
                        SizedBox(width: 6),
                        Text('本人確認をする',
                            style: TextStyle(fontSize: 13,
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          userData: {
                            'name': _userName,
                            'age': _userAge,
                            'prefecture': _userPrefecture,
                            'animal': _userAnimal,
                            'gender': _userData?['gender'],
                            'showing': _userData?['showing'],
                            'bio': _userBio,
                            'relation': _userRelation,
                            'activities': _userActivities,
                            'purpose': _userPurpose,
                          },
                        ),
                      ),
                    );
                    if (result == true) _loadUserData();
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            color: Colors.grey, size: 16),
                        SizedBox(width: 6),
                        Text('編集',
                            style: TextStyle(fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // スタッツ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem('0', 'スワイプ'),
                  _StatItem('0', 'マッチ'),
                  _StatItem('0', 'お気に入り'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 自己紹介
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('自己紹介',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 8),
                  Text(
                    _userBio.isNotEmpty ? _userBio : '自己紹介を書いてみよう！',
                    style: TextStyle(
                        fontSize: 14,
                        color: _userBio.isNotEmpty
                            ? const Color(0xFF3D2B1F)
                            : Colors.grey,
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 動物との関わり方
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('動物との関わり方',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['🏠 飼ってる', '👀 見るのが好き', '🔥 ガチ勢', '🌱 これから飼いたい']
                        .map((r) {
                      final sel = r.contains(_userRelation) && _userRelation.isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8845A)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(r,
                            style: TextStyle(
                                fontSize: 13,
                                color: sel ? Colors.white : Colors.grey[600])),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 一緒にやりたいこと
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('一緒にやりたいこと',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['🐾 散歩', '☕ カフェ', '🏕️ キャンプ', '📸 写真撮影',
                      '🎪 イベント', '🍳 料理', '🎬 映画', '✈️ 旅行',
                      '🏃 運動', '📚 読書']
                        .map((act) {
                      final actName = act.split(' ').last;
                      final sel = _userActivities.contains(actName);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8845A)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(act,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white : Colors.grey[700])),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 利用目的
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('利用目的',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8845A),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _userPurpose.isNotEmpty ? _userPurpose : '未設定',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 価値観診断バナー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => ValuesPage(
                        onComplete: (answers) {},
                      ))),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8845A), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('価値観診断',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('動物への価値観をチェック！\n相性スコアに反映されます',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.white70, height: 1.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ペット情報
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('私のペット 🐾',
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      TextButton.icon(
                        onPressed: _addPet,
                        icon: const Icon(Icons.add_circle_rounded,
                            color: Color(0xFFE8845A), size: 18),
                        label: const Text('追加',
                            style: TextStyle(color: Color(0xFFE8845A),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_pets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('ペットを追加しよう！',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13)),
                    )
                  else
                    ..._pets.asMap().entries.map((entry) {
                      final i = entry.key;
                      final pet = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F5),
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: pet.imagePath != null
                                  ? Image.file(File(pet.imagePath!),
                                  width: 56, height: 56, fit: BoxFit.cover)
                                  : Container(
                                  width: 56, height: 56,
                                  color: Colors.orange[50],
                                  child: const Center(
                                      child: Text('🐾',
                                          style: TextStyle(fontSize: 28)))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${pet.name}（${pet.type}）',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3D2B1F))),
                                  Text('${pet.age}歳',
                                      style: TextStyle(fontSize: 12,
                                          color: Colors.grey[600])),
                                  Wrap(
                                    spacing: 4,
                                    children: pet.tags.map((tag) =>
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFE8845A)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(8)),
                                          child: Text(tag,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFFE8845A))),
                                        )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                    onPressed: () => _editPet(i),
                                    icon: const Icon(Icons.edit_rounded,
                                        color: Colors.grey, size: 20)),
                                IconButton(
                                    onPressed: () => setState(
                                            () => _pets.removeAt(i)),
                                    icon: const Icon(Icons.delete_rounded,
                                        color: Colors.red, size: 20)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // スタンプ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('解除済みスタンプ 🎁',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 12),
                  Text('50回スワイプすると解放されます',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['🐕', '🐱', '🐰', '🦎', '👑'].map((stamp) =>
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: Text(stamp,
                                  style: const TextStyle(fontSize: 24,
                                      color: Colors.grey))),
                        )).toList(),
                  ),
                ],
              ),
            ),
          ),
              const SizedBox(height: 16),
              // 設定メニュー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.workspace_premium_rounded,
                        label: 'プレミアムプラン👑',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const PremiumPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.notifications_rounded,
                        label: '通知設定🔔',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationSettingsPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.people_rounded,
                        label: 'フレンド',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const FriendsPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.report_rounded,
                        label: '虐待を通報する🆘',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AbuseReportPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.delete_forever_rounded,
                        label: 'アカウント削除',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const DeleteAccountPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.lock_rounded,
                        label: 'プライバシーポリシー',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.description_rounded,
                        label: '利用規約',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const TermsPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.mail_rounded,
                        label: 'お問い合わせ',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ContactPage())),
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'ログアウト',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('ログアウト'),
                              content: const Text('ログアウトしますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('ログアウト',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
}
class _Badge extends StatelessWidget {
  final String emoji;
  final String label;
  const _Badge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber[200]!)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.amber[800],
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8845A))),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  const _EditField({required this.label, required this.ctrl,
    this.keyboardType, this.maxLines = 1, this.inputFormatters});


  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8845A))),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _AddPetSheet extends StatefulWidget {
  final Function(PetData) onAdd;
  const _AddPetSheet({required this.onAdd});

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ペットを追加',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _EditField(label: '名前', ctrl: _nameCtrl),
          const SizedBox(height: 12),
          _EditField(label: '種類', ctrl: _typeCtrl),
          const SizedBox(height: 12),
          _EditField(label: '年齢', ctrl:_ageCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),


          const SizedBox(height: 12),
          _EditField(label: '自己紹介', ctrl: _bioCtrl, maxLines: 3),
          const SizedBox(height: 16),
          const Text('性格タグ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['元気', '人懐こい', 'おっとり', 'やんちゃ',
              '甘えん坊', '独立心強い', '賢い', '遊び好き']
                .map((tag) {
              final sel = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selectedTags.remove(tag)
                    : _selectedTags.add(tag)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8845A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(tag,
                      style: TextStyle(fontSize: 12,
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) return;
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final petData = {
                  'name': _nameCtrl.text,
                  'type': _typeCtrl.text,
                  'age': int.tryParse(_ageCtrl.text) ?? 1,
                  'bio': _bioCtrl.text,
                  'tags': _selectedTags,
                  'createdAt': FieldValue.serverTimestamp(),
                };
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('pets')
                    .add(petData);
                widget.onAdd(PetData(
                  name: _nameCtrl.text,
                  type: _typeCtrl.text,
                  age: int.tryParse(_ageCtrl.text) ?? 1,
                  bio: _bioCtrl.text,
                  tags: _selectedTags,
                  avatarPath: '',
                ));
              },

              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8845A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('追加する',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE8845A), size: 22),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 15,
                        color: Color(0xFF3D2B1F)))),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
