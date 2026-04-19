import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'swipe_page.dart';
import 'online_page.dart';

const _searchPets = [
  Pet(
    id: '1', name: 'ポチ', type: '犬', age: 3,
    bio: '元気いっぱいの柴犬🐕',
    avatarPath: 'assets/images/pochi.jpg',
    photos: ['assets/images/pochi.jpg'],
    owner: 'たかし', ownerCity: '東京',
  ),
  Pet(
    id: '2', name: 'マイク', type: '犬', age: 2,
    bio: '甘えん坊で人懐こい男の子🐶',
    avatarPath: 'assets/images/mike.jpg',
    photos: ['assets/images/mike.jpg'],
    owner: 'さくら', ownerCity: '大阪',
  ),
  Pet(
    id: '3', name: 'モナ', type: '猫', age: 1,
    bio: 'おっとりした女の子🐱',
    avatarPath: 'assets/images/mona.jpg',
    photos: ['assets/images/mona.jpg'],
    owner: 'ゆい', ownerCity: '京都',
  ),
  Pet(
    id: '4', name: 'チョコ', type: '犬', age: 4,
    bio: 'チョコレート色のトイプードル🐩',
    avatarPath: 'assets/images/choco.jpg',
    photos: ['assets/images/choco.jpg'],
    owner: 'けんた', ownerCity: '福岡',
  ),
  Pet(
    id: '5', name: 'ルナ', type: '猫', age: 2,
    bio: '黒猫の女の子🐈‍⬛',
    avatarPath: 'assets/images/pochi.jpg',
    photos: ['assets/images/pochi.jpg'],
    owner: 'みか', ownerCity: '名古屋',
  ),
  Pet(
    id: '6', name: 'ピーチ', type: 'うさぎ', age: 1,
    bio: 'ふわふわのうさぎ🐰',
    avatarPath: 'assets/images/mona.jpg',
    photos: ['assets/images/mona.jpg'],
    owner: 'あい', ownerCity: '札幌',
  ),
  Pet(
    id: '7', name: 'ハナ', type: 'ハムスター', age: 1,
    bio: 'ほっぺがぷくぷく🐹',
    avatarPath: 'assets/images/choco.jpg',
    photos: ['assets/images/choco.jpg'],
    owner: 'りか', ownerCity: '横浜',
  ),
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _selectedType = '全て';
  String _selectedCity = '全て';
  String _selectedDistance = '全国';
  String _selectedPurpose = '全て';
  RangeValues _ageRange = const RangeValues(0, 10);
  bool _showFilter = false;
  List<String> _searchHistory = [];

  final _types = ['全て', '犬', '猫', 'うさぎ', 'ハムスター',
    'フェレット', 'チンチラ', 'モルモット', 'ハリネズミ',
    '鳥', '爬虫類', 'デグー', 'その他'];
  final _cities = ['全て',
    '北海道', '青森', '岩手', '宮城', '秋田', '山形', '福島',
    '茨城', '栃木', '群馬', '埼玉', '千葉', '東京', '神奈川',
    '新潟', '富山', '石川', '福井', '山梨', '長野', '岐阜',
    '静岡', '愛知', '三重', '滋賀', '京都', '大阪', '兵庫',
    '奈良', '和歌山', '鳥取', '島根', '岡山', '広島', '山口',
    '徳島', '香川', '愛媛', '高知', '福岡', '佐賀', '長崎',
    '熊本', '大分', '宮崎', '鹿児島', '沖縄'];

  final _distances = ['全国', '10km以内', '30km以内', '50km以内', '100km以内'];
  final _purposes = ['全て', '💕 恋愛', '🐾 友達', '🌱 保護活動', '🏃 散歩仲間'];

  List<Pet> get _filtered => _searchPets.where((p) {
    final matchType = _selectedType == '全て' || p.type == _selectedType;
    final matchCity = _selectedCity == '全て' || p.ownerCity == _selectedCity;
    final matchAge = p.age >= _ageRange.start && p.age <= _ageRange.end;
    final matchSearch = _searchCtrl.text.isEmpty ||
        p.name.contains(_searchCtrl.text) ||
        p.owner.contains(_searchCtrl.text);
    return matchType && matchCity && matchAge && matchSearch;
  }).toList();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('検索 🔍',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OnlinePage())),
            icon: const Icon(Icons.people_rounded,
                color: Color(0xFFE8845A)),
          ),
        ],
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ペット名・オーナー名で検索',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFFE8845A)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showFilter = !_showFilter),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _showFilter
                      ? const Color(0xFFE8845A) : Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.tune_rounded,
                  color: _showFilter
                      ? Colors.white : const Color(0xFFE8845A)),
            ),
          ),
        ],
      ),
    ),
    if (_showFilter)
    Expanded(
    child: SingleChildScrollView(
    child: Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16)),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text('動物の種類',
    style: TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    const SizedBox(height: 8),
    Wrap(
    spacing: 8, runSpacing: 8,
    children: _types.map((type) {
    final sel = _selectedType == type;
    return GestureDetector(
    onTap: () => setState(() => _selectedType = type),
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: sel
    ? const Color(0xFFE8845A) : Colors.grey[100],
    borderRadius: BorderRadius.circular(20)),
    child: Text(type,
    style: TextStyle(fontSize: 12,
    color: sel ? Colors.white : Colors.grey[700])),
    ),
    );
    }).toList(),
    ),
    const SizedBox(height: 12),
    const Text('距離',
    style: TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    const SizedBox(height: 8),
    Wrap(
    spacing: 8, runSpacing: 8,
    children: _distances.map((distance) {
    final sel = _selectedDistance == distance;
    return GestureDetector(
    onTap: () => setState(() => _selectedDistance = distance),
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: sel
    ? const Color(0xFFE8845A) : Colors.grey[100],
    borderRadius: BorderRadius.circular(20)),
    child: Text(distance,
    style: TextStyle(fontSize: 12,
    color: sel ? Colors.white : Colors.grey[700])),
    ),
    );
    }).toList(),
    ),
    const SizedBox(height: 12),
    const Text('利用目的',
    style: TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    const SizedBox(height: 8),
    Wrap(
    spacing: 8, runSpacing: 8,
    children: _purposes.map((purpose) {
    final sel = _selectedPurpose == purpose;
    return GestureDetector(
    onTap: () => setState(() => _selectedPurpose = purpose),
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: sel
    ? const Color(0xFFE8845A) : Colors.grey[100],
    borderRadius: BorderRadius.circular(20)),
    child: Text(purpose,
    style: TextStyle(fontSize: 12,
    color: sel ? Colors.white : Colors.grey[700])),
    ),
    );
    }).toList(),
    ),
    const SizedBox(height: 12),
    const Text('地域',
    style: TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    const SizedBox(height: 8),
    Wrap(
    spacing: 8, runSpacing: 8,
    children: _cities.map((city) {
    final sel = _selectedCity == city;
    return GestureDetector(
    onTap: () => setState(() => _selectedCity = city),
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: sel
    ? const Color(0xFFE8845A) : Colors.grey[100],
    borderRadius: BorderRadius.circular(20)),
    child: Text(city,
    style: TextStyle(fontSize: 12,
    color: sel ? Colors.white : Colors.grey[700])),
    ),
    );
    }).toList(),
    ),
    const SizedBox(height: 12),
    Text('年齢: ${_ageRange.start.toInt()}〜${_ageRange.end.toInt()}歳',
    style: const TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    RangeSlider(
    values: _ageRange,
    min: 0, max: 15,
    divisions: 15,
    activeColor: const Color(0xFFE8845A),
    onChanged: (v) => setState(() => _ageRange = v),
    ),
    ],
    ),
    ),
    ),
    ),
    if (!_showFilter) ...[
    if (_searchHistory.isNotEmpty && _searchCtrl.text.isEmpty)
    Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text('検索履歴',
    style: TextStyle(fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    TextButton(
    onPressed: () => setState(() => _searchHistory.clear()),
    child: const Text('クリア',
    style: TextStyle(color: Color(0xFFE8845A)))),
    ],
    ),
    Wrap(
    spacing: 8, runSpacing: 8,
    children: _searchHistory.map((h) => GestureDetector(
    onTap: () => setState(() => _searchCtrl.text = h),
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.grey[300]!)),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    const Icon(Icons.history_rounded,
    size: 14, color: Colors.grey),
    const SizedBox(width: 4),
    Text(h, style: TextStyle(
    fontSize: 12, color: Colors.grey[700])),
    ],
    ),
    ),
    )).toList(),
    ),
    ],
    ),
    ),
      Expanded(
        child: _filtered.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('見つかりませんでした',
                  style: TextStyle(fontSize: 16,
                      color: Colors.grey[600])),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final pet = _filtered[i];
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SwipePage(
                      pets: _filtered, initialIndex: i))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(pet.avatarPath,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(
                              width: 60, height: 60,
                              color: Colors.orange[50],
                              child: const Center(
                                  child: Text('🐾')))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pet.name}・${pet.age}歳',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          Text('${pet.type} ・ ${pet.ownerCity}',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.grey[600])),
                          Text('オーナー: ${pet.owner}さん',
                              style: TextStyle(fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFE8845A)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
          ],
      ),
    );
  }
}
