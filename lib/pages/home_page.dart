import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'disaster_page.dart';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../providers/app_provider.dart';
import 'swipe_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';
import 'likes_page.dart';
import 'match_list_page.dart';
import 'online_page.dart';
import 'hospital_page.dart';
import 'lost_pet_page.dart';
import 'hotel_page.dart';
import 'pet_diagnosis_page.dart';
import 'ranking_page.dart';

const _allPets = [
  Pet(
    id: '1', name: 'ポチ', type: '犬', age: 3,
    bio: '元気いっぱいの柴犬🐕 お散歩とおやつが大好き！',
    avatarPath: 'assets/images/pochi.jpg',
    photos: ['assets/images/pochi.jpg'],
    owner: 'たかし', ownerCity: '東京',
  ),
  Pet(
    id: '2', name: 'マイク', type: '犬', age: 2,
    bio: '甘えん坊で人懐こい男の子🐶 一緒に公園行こう！',
    avatarPath: 'assets/images/mike.jpg',
    photos: ['assets/images/mike.jpg',
      'assets/images/mona.jpg',
      'assets/images/choco.jpg'],
    owner: 'さくら', ownerCity: '大阪',
  ),
  Pet(
    id: '3', name: 'モナ', type: '猫', age: 1,
    bio: 'おっとりした女の子🐱 窓辺でひなたぼっこが好き',
    avatarPath: 'assets/images/mona.jpg',
    photos: ['assets/images/mona.jpg'],
    owner: 'ゆい', ownerCity: '京都',
  ),
  Pet(
    id: '4', name: 'チョコ', type: '犬', age: 4,
    bio: 'チョコレート色のトイプードル🐩 トリック得意！',
    avatarPath: 'assets/images/choco.jpg',
    photos: ['assets/images/choco.jpg'],
    owner: 'けんた', ownerCity: '福岡',
  ),
  Pet(
    id: '5', name: 'ルナ', type: '猫', age: 2,
    bio: '黒猫の女の子🐈‍⬛ 夜に活発になります',
    avatarPath: 'assets/images/pochi.jpg',
    photos: ['assets/images/pochi.jpg'],
    owner: 'みか', ownerCity: '名古屋',
  ),
  Pet(
    id: '6', name: 'ピーチ', type: 'うさぎ', age: 1,
    bio: 'ふわふわのうさぎ🐰 野菜が大好きです',
    avatarPath: 'assets/images/mona.jpg',
    photos: ['assets/images/mona.jpg'],
    owner: 'あい', ownerCity: '札幌',
  ),
  Pet(
    id: '7', name: 'ハナ', type: 'ハムスター', age: 1,
    bio: 'ほっぺがぷくぷくのハムスター🐹 回し車が好き！',
    avatarPath: 'assets/images/choco.jpg',
    photos: ['assets/images/choco.jpg'],
    owner: 'りか', ownerCity: '横浜',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  final _tabs = ['おすすめ', '近く', '新着'];
  final _provider = globalProvider;
  String _userName = '';

  List<Pet> get _displayPets {
    switch (_tabIndex) {
      case 0: return _allPets;
      case 1: return _allPets.where((p) =>
          ['東京', '大阪', '京都'].contains(p.ownerCity)).toList();
      case 2: return _allPets.reversed.toList();
      default: return _allPets;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userName = doc.data()!['name'] ?? '';
          });
        }
      }
    } catch (e) {
      print('🔥 名前取得エラー: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty
                            ? 'こんにちは、${_userName}さん！🐾'
                            : 'こんにちは！🐾',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const Text('AniMatch',
                          style: TextStyle(fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3D2B1F))),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const RankingPage())),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8)]),
                          child: const Text('🏆',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('サポート 🐾',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const HospitalPage())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🏥', style: TextStyle(fontSize: 28)),
                            SizedBox(height: 8),
                            Text('動物病院',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text('病院を探す',
                                style: TextStyle(fontSize: 11,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const LostPetPage())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔍', style: TextStyle(fontSize: 28)),
                            SizedBox(height: 8),
                            Text('迷子情報',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text('情報を共有',
                                style: TextStyle(fontSize: 11,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const HotelPage())),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFF9B59B6), Color(0xFFBB8FCE)]),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🏨', style: TextStyle(fontSize: 28)),
                                  SizedBox(height: 8),
                                  Text('ペットホテル',
                                      style: TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text('ホテルを探す',
                                      style: TextStyle(fontSize: 11,
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const PetDiagnosisPage())),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🔮', style: TextStyle(fontSize: 28)),
                                  SizedBox(height: 8),
                                  Text('ペット診断',
                                      style: TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text('あなたに合うペットは？',
                                      style: TextStyle(fontSize: 11,
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('フレンド 🟢',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const OnlinePage())),
                  child: const Text('全員見る',
                      style: TextStyle(color: Color(0xFFE8845A))),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                {'name': 'さくら', 'emoji': '🐕', 'online': true},
                {'name': 'ゆい', 'emoji': '🐱', 'online': true},
                {'name': 'みか', 'emoji': '🐰', 'online': true},
                {'name': 'あい', 'emoji': '🐈', 'online': false},
                {'name': 'けんた', 'emoji': '🐶', 'online': false},
              ].map((user) => Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8845A).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: (user['online'] as bool)
                                      ? Colors.green : Colors.grey,
                                  width: 2)),
                          child: Center(
                              child: Text(user['emoji'] as String,
                                  style: const TextStyle(fontSize: 26))),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                                color: (user['online'] as bool)
                                    ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user['name'] as String,
                        style: const TextStyle(fontSize: 11,
                            color: Color(0xFF3D2B1F))),
                  ],
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const DisasterPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[300]!)),
                child: const Row(
                  children: [
                    Text('🆘', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('災害時安否確認',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Text('フレンドの安否を確認する',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.red),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final sel = _tabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8845A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: sel ? [BoxShadow(
                          color: const Color(0xFFE8845A).withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Text(_tabs[i],
                        style: TextStyle(
                            fontSize: 13,
                            color: sel ? Colors.white : Colors.grey[600],
                            fontWeight: sel
                                ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日のおすすめ 🐾',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              itemCount: _displayPets.length,
              itemBuilder: (_, i) {
                final pet = _displayPets[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SwipePage(
                          pets: _displayPets, initialIndex: i))),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.asset(pet.avatarPath,
                              width: 150, height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => Container(
                                  color: Colors.orange[50],
                                  child: const Center(
                                      child: Text('🐾',
                                          style: TextStyle(fontSize: 40))))),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Color(0xDD000000),
                                        Colors.transparent])),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('${pet.name}・${pet.age}歳',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  Text(pet.ownerCity,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: const Text('クイックアクション',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          _QuickAction(
                            emoji: '❤️',
                            label: 'いいね',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => LikesPage(
                                      allPets: _allPets,
                                      likedIds: _provider.likedIds,
                                    ))),
                          ),
                          _QuickAction(
                            emoji: '⭐',
                            label: 'お気に入り',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => FavoritesPage(
                                      allPets: _allPets,
                                      favIds: _provider.favIds,
                                      onToggle: (id) => setState(() =>
                                          _provider.toggleFav(id)),
                                    ))),
                          ),
                          _QuickAction(
                            emoji: '🎉',
                            label: 'マッチ',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const MatchListPage())),
                          ),
                          _QuickAction(
                            emoji: '🔍',
                            label: '検索',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const SearchPage())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => SwipePage(
                                pets: _displayPets, initialIndex: 0))),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE8845A), Color(0xFFF4A261)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFFE8845A).withOpacity(0.4),
                                blurRadius: 15, offset: const Offset(0, 6))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🐾', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 12),
                              Text('ペットを探す',
                                  style: TextStyle(fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
              ),
            ),
        ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
