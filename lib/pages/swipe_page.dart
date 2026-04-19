import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../providers/app_provider.dart';
import 'chat_page.dart';
import 'report_page.dart';
import 'review_page.dart';
import 'profile_page.dart';

const _ownerProfiles = {
  '1': {
    'name': 'たかし',
    'age': '28歳',
    'city': '東京',
    'purpose': '🐾 動物好き友達探し',
    'activities': ['🐕 散歩', '☕ カフェ', '🎪 イベント'],
    'bio': '柴犬のポチと毎日散歩しています🐕 動物好きな人と繋がりたいです！',
    'petName': 'ポチ',
    'petType': '犬',
    'petAge': '3歳',
    'petBio': '元気いっぱいの柴犬🐕 お散歩とおやつが大好きです！',
    'otherPets': ['ポチ🐕', 'クロ🐈'],
    'compatibility': 95,
    'values': ['室内飼い派', '保護活動に積極的', '動物病院重視'],
  },
  '2': {
    'name': 'さくら',
    'age': '25歳',
    'city': '大阪',
    'purpose': '🐾 動物好き友達探し',
    'activities': ['🐕 散歩', '☕ カフェ', '📸 写真撮影'],
    'bio': '犬と一緒に色んな場所に行くのが好きです！休日は必ず公園に行きます🐕',
    'petName': 'マイク',
    'petType': '犬',
    'petAge': '2歳',
    'petBio': '甘えん坊で人懐こい男の子🐶 誰とでもすぐ仲良くなれます！',
    'otherPets': ['マイク🐶'],
    'compatibility': 82,
    'values': ['室内飼い派', 'のんびり派', '猫中心生活'],
  },
  '3': {
    'name': 'ゆい',
    'age': '23歳',
    'city': '京都',
    'purpose': '💕 恋愛・パートナー探し',
    'activities': ['☕ カフェ', '🎬 映画', '📚 読書'],
    'bio': 'のんびり猫と過ごすのが至福の時間です🐱 猫カフェが大好きです！',
    'petName': 'モナ',
    'petType': '猫',
    'petAge': '1歳',
    'petBio': 'おっとりした女の子🐱 窓辺でひなたぼっこが大好きです。',
    'otherPets': ['モナ🐱', 'シロ🐈', 'クロ🐈‍⬛'],
    'compatibility': 78,
    'values': ['アクティブ派', '外飼い派', '散歩重視'],
  },
  '4': {
    'name': 'けんた',
    'age': '27歳',
    'city': '福岡',
    'purpose': '🏃 散歩仲間探し',
    'activities': ['🐕 散歩', '🏕️ キャンプ', '🏃 運動'],
    'bio': '犬と一緒にアウトドアを楽しんでいます！毎朝5km走ってます🏃',
    'petName': 'チョコ',
    'petType': '犬',
    'petAge': '4歳',
    'petBio': 'チョコレート色のトイプードル🐩 トリックが得意で賢いです！',
    'otherPets': ['チョコ🐩', 'モモ🐕'],
    'compatibility': 70,
    'values': ['アクティブ派', 'アウトドア派', '運動重視'],
  },
};

const _stampLevels = [
  {'count': 50, 'name': 'わんこセット🐕'},
  {'count': 200, 'name': 'にゃんこセット🐱'},
  {'count': 400, 'name': 'うさぎセット🐰'},
  {'count': 700, 'name': 'エキゾチックセット🦎'},
  {'count': 1000, 'name': 'プレミアムセット👑'},
];

class SwipePage extends StatefulWidget {
  final List<Pet> pets;
  final int initialIndex;

  const SwipePage({
    super.key,
    required this.pets,
    required this.initialIndex,
  });

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _liked = false;
  bool _disliked = false;
  bool _showMatch = false;
  int _swipeCount = 0;
  final _provider = globalProvider;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Pet get _pet => widget.pets[_currentIndex];

  int get _nextStampCount {
    for (final level in _stampLevels) {
      if (_swipeCount < (level['count'] as int)) {
        return level['count'] as int;
      }
    }
    return 1000;
  }

  String get _nextStampName {
    for (final level in _stampLevels) {
      if (_swipeCount < (level['count'] as int)) {
        return level['name'] as String;
      }
    }
    return 'プレミアムセット👑';
  }

  void _nextPet({bool liked = false}) {
    setState(() {
      _liked = liked;
      _disliked = !liked;
      _swipeCount++;
    });
    for (final level in _stampLevels) {
      if (_swipeCount == (level['count'] as int)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('🎉 スタンプ解放！'),
                content: Text('${level['name']}が解放されました！'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('やった！'),
                  ),
                ],
              ),
            );
          }
        });
      }
    }
    _animCtrl.forward().then((_) {
      setState(() {
        _liked = false;
        _disliked = false;
        if (liked) {
          _showMatch = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showMatch = false);
          });
        }
        if (_currentIndex < widget.pets.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
      });
      _animCtrl.reset();
    });
  }

  Color _compatibilityColor(int value) {
    if (value >= 80) return const Color(0xFF2D6A4F);
    if (value >= 60) return const Color(0xFFE8845A);
    return Colors.red;
  }
  @override
  Widget build(BuildContext context) {
    final progress = _nextStampCount > 0
        ? _swipeCount / _nextStampCount
        : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: Text('今日のおすすめ ${widget.pets.length}人 🐾',
            style: const TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
            icon: const Icon(Icons.person_rounded,
                color: Color(0xFFE8845A)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('🎁 $_nextStampName まで',
                            style: const TextStyle(fontSize: 11,
                                color: Color(0xFFE8845A),
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('あと${_nextStampCount - _swipeCount}回',
                            style: TextStyle(fontSize: 11,
                                color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFE8845A)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentIndex < widget.pets.length - 1)
                      Positioned(
                        top: 16,
                        child: _buildCard(
                            widget.pets[_currentIndex + 1],
                            isBackground: true),
                      ),
                    SlideTransition(
                      position: _slideAnim,
                      child: GestureDetector(
                        onTap: () => _showOwnerProfile(context),
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 300) {
                            _nextPet(liked: true);
                          } else if (details.primaryVelocity! < -300) {
                            _nextPet(liked: false);
                          }
                        },
                        child: Stack(
                          children: [
                            _buildCard(_pet),
                            if (_liked)
                              Positioned(
                                top: 40, left: 20,
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xFF2D6A4F),
                                            width: 3),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('LIKE 💚',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF2D6A4F))),
                                  ),
                                ),
                              ),
                            if (_disliked)
                              Positioned(
                                top: 40, right: 20,
                                child: Transform.rotate(
                                  angle: 0.3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.red,
                                            width: 3),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('NOPE ✕',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.red)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.close_rounded,
                      color: Colors.red,
                      size: 56,
                      onTap: () => _nextPet(liked: false),
                    ),
                    _ActionButton(
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      size: 44,
                      onTap: () {
                        _provider.toggleFav(_pet.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('お気に入りに追加しました！⭐'),
                            backgroundColor: Colors.amber,
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF2D6A4F),
                      size: 56,
                      onTap: () => _nextPet(liked: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showMatch)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text('マッチしました！',
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                      Text('チャットを始めましょう🐾',
                          style: TextStyle(fontSize: 14,
                              color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _showMatch = false);
                          final owner = _ownerProfiles[_pet.id];
                          if (owner != null) {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    ChatPage(
                                        userName: owner['name'] as String,
                                        userEmoji: '🐾')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8845A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14)),
                        child: const Text('チャットする🐾',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _showMatch = false),
                        child: const Text('続けてスワイプする',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildCard(Pet pet, {bool isBackground = false}) {
    final owner = _ownerProfiles[pet.id];
    final compatibility = owner != null
        ? (owner['compatibility'] as int)
        : 75;

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(pet.avatarPath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(
                    color: Colors.orange[50],
                    child: const Center(
                        child: Text('🐾',
                            style: TextStyle(fontSize: 80))))),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xDD000000), Colors.transparent])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('${pet.name}・${pet.age}歳',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900))),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _compatibilityColor(compatibility),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('相性 $compatibility%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(pet.ownerCity,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.pets_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(pet.type,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(pet.bio,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (owner != null && (owner['otherPets'] as List).length > 1)
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: () => _showOtherPets(context, owner),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pets_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('他のペット(${(owner['otherPets'] as List).length})',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOtherPets(BuildContext context, Map owner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Color(0xFFFFF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${owner['name']}さんのペット',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: (owner['otherPets'] as List).map((pet) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6)]),
                    child: Text(pet as String,
                        style: const TextStyle(fontSize: 14)),
                  )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  void _showOwnerProfile(BuildContext context) {
    final owner = _ownerProfiles[_pet.id];
    if (owner == null) return;
    final compatibility = owner['compatibility'] as int;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
                color: Color(0xFFFFF8F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              children: [
              Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                children: [
                Container(
                width: 70, height: 70,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8845A).withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Center(
                      child: Text('🐾',
                          style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['name'] as String,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3D2B1F))),
                      Text('${owner['age']} ・ ${owner['city']}',
                          style: TextStyle(fontSize: 13,
                              color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8845A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(owner['purpose'] as String,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE8845A),
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('相性',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const Spacer(),
                        Text('$compatibility%',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _compatibilityColor(compatibility))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: compatibility / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                            _compatibilityColor(compatibility)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (owner.containsKey('values'))
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: (owner['values'] as List).map((v) =>
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(v as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2D6A4F),
                                      fontWeight: FontWeight.bold)),
                            )).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('自己紹介',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Text(owner['bio'] as String,
                        style: TextStyle(fontSize: 13,
                            color: Colors.grey[600], height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('一緒にやりたいこと',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (owner['activities'] as List).map((a) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8845A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(a as String,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE8845A))),
                          )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8845A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFE8845A).withOpacity(0.2))),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: Color(0xFFE8845A), size: 16),
                    const SizedBox(width: 6),
                    const Text('利用目的',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(width: 8),
                    Text(owner['purpose'] as String,
                        style: TextStyle(fontSize: 13,
                            color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ペット情報',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8845A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child: Text('🐾',
                                  style: TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${owner['petName']}（${owner['petType']}・${owner['petAge']}）',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 4),
                              Text(owner['petBio'] as String,
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if ((owner['otherPets'] as List).length > 1) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('他のペット',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: (owner['otherPets'] as List).map((pet) =>
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE8845A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(pet as String,
                                  style: const TextStyle(fontSize: 12,
                                      color: Color(0xFFE8845A))),
                            )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _nextPet(liked: true);
                      },
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('いいね！'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                ChatPage(
                                    userName: owner['name'] as String,
                                    userEmoji: '🐾')));
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('チャット'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8845A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _provider.toggleFav(_pet.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('お気に入りに追加しました！⭐'),
                                  backgroundColor: Color(0xFFE8845A),
                                ),
                              );
                            },
                            icon: const Icon(Icons.star_rounded,
                                color: Colors.amber),
                            label: const Text('お気に入り',
                                style: TextStyle(color: Color(0xFF3D2B1F))),
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      ReviewPage(userName: owner['name'] as String)));
                            },
                            icon: const Icon(Icons.star_outline_rounded,
                                color: Color(0xFFE8845A)),
                            label: const Text('レビュー',
                                style: TextStyle(color: Color(0xFF3D2B1F))),
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Text('ブロックしますか？'),
                                  content: Text('${owner['name']}さんをブロックすると\n二度と表示されなくなります。'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('キャンセル',
                                            style: TextStyle(color: Colors.grey))),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${owner['name']}さんをブロックしました'),
                                            backgroundColor: Colors.grey[700],
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12))),
                                      child: const Text('ブロック'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.block_rounded,
                                color: Colors.grey),
                            label: const Text('ブロック',
                                style: TextStyle(color: Colors.grey)),
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      ReportPage(userName: owner['name'] as String)));
                            },
                            icon: const Icon(Icons.flag_rounded,
                                color: Colors.red),
                            label: const Text('通報',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
              ],
            ),
        ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
