import 'package:flutter/material.dart';

const _hospitals = [
  {
    'name': '東京動物医療センター',
    'address': '東京都世田谷区',
    'phone': '03-1234-5678',
    'animals': ['犬', '猫', 'うさぎ', '鳥', '爬虫類'],
    'speciality': 3,
    'emergency': true,
    'surgery': true,
    'hospitalization': true,
    'exotic': true,
    'ct': true,
    'mri': true,

    'hours': '9:00〜19:00',
    'holiday': '水曜日',
    'review': 4.8,
    'reviewCount': 124,
    'badge': '認定医在籍',
    'specialtyAnimals': ['犬', '猫', 'うさぎ'],
    'doctors': [
      {'name': '山田先生', 'specialty': 'うさぎ・小動物専門', 'experience': '15年'},
      {'name': '鈴木先生', 'specialty': '犬・猫専門', 'experience': '10年'},
    ],
    'lastUpdated': '2026年3月',


  },
  {
    'name': 'アニマルクリニック大阪',
    'address': '大阪府大阪市',
    'phone': '06-1234-5678',
    'animals': ['犬', '猫', 'うさぎ', 'ハムスター', 'フェレット'],
    'speciality': 2,
    'emergency': false,
    'surgery': true,
    'hospitalization': true,
    'exotic': true,
    'ct': false,
    'mri': false,

    'hours': '10:00〜18:00',
    'holiday': '木曜日',
    'review': 4.5,
    'reviewCount': 89,
    'badge': 'エキゾチック対応',
    'specialtyAnimals': ['犬', '猫', 'うさぎ', 'ハムスター'],
    'doctors': [
      {'name': '田中先生', 'specialty': 'フェレット・ハムスター専門', 'experience': '8年'},
    ],
    'lastUpdated': '2026年2月',

  },
  {
    'name': 'エキゾチック動物病院福岡',
    'address': '福岡県福岡市',
    'phone': '092-1234-5678',
    'animals': ['うさぎ', 'チンチラ', 'モルモット', 'ハリネズミ', 'フェレット'],
    'speciality': 3,
    'emergency': false,
    'surgery': true,
    'hospitalization': false,
    'exotic': true,
    'ct': false,
    'mri': false,

    'hours': '9:00〜17:00',
    'holiday': '日曜・月曜',
    'review': 4.9,
    'reviewCount': 67,
    'badge': 'エキゾチック専門',
    'specialtyAnimals': ['うさぎ', 'チンチラ', 'モルモット', 'フェレット'],
    'doctors': [
      {'name': '田中先生', 'specialty': 'フェレット・ハムスター専門', 'experience': '8年'},
    ],
    'lastUpdated': '2026年2月',

  },
  {
    'name': '札幌ペットクリニック',
    'address': '北海道札幌市',
    'phone': '011-1234-5678',
    'animals': ['犬', '猫', 'うさぎ', '鳥', 'ハムスター'],
    'speciality': 2,
    'emergency': true,
    'surgery': true,
    'hospitalization': true,
    'exotic': false,
    'ct': true,
    'mri': false,

    'hours': '8:00〜20:00',
    'holiday': '無休',
    'review': 4.3,
    'reviewCount': 201,
    'badge': '24時間対応',
    'specialtyAnimals': ['犬', '猫'],
    'doctors': [
      {'name': '高橋先生', 'specialty': '犬・猫専門', 'experience': '20年'},
    ],
    'lastUpdated': '2026年1月',

  },
];

const _animalTypes = [
  '全て', '犬', '猫', 'うさぎ', 'ハムスター', 'フェレット',
  'チンチラ', 'モルモット', 'ハリネズミ', '鳥', '爬虫類',
  'デグー', 'イグアナ', 'ウーパールーパー', 'シマリス',
  'フクロモモンガ', 'ショウガラゴ', 'フェネック', '猛禽類',
  '家禽', 'リクガメ', 'ヒョウモントカゲモドキ', 'その他',
];


class HospitalPage extends StatefulWidget {
  const HospitalPage({super.key});

  @override
  State<HospitalPage> createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedAnimal = '全て';
  bool _emergencyOnly = false;
  bool _exoticOnly = false;
  bool _surgeryOnly = false;
  bool _hospitalizationOnly = false;
  bool _ctOnly = false;
  bool _mriOnly = false;
  final _searchCtrl = TextEditingController();

  List get _filtered => _hospitals.where((h) {
    final animals = h['animals'] as List;
    final matchAnimal = _selectedAnimal == '全て' ||
        animals.contains(_selectedAnimal);
    final matchEmergency = !_emergencyOnly || h['emergency'] == true;
    final matchExotic = !_exoticOnly || h['exotic'] == true;
    final matchSurgery = !_surgeryOnly || h['surgery'] == true;
    final matchHospitalization = !_hospitalizationOnly ||
        h['hospitalization'] == true;
    final matchCt = !_ctOnly || h['ct'] == true;
    final matchMri = !_mriOnly || h['mri'] == true;
    return matchAnimal && matchEmergency && matchExotic &&
        matchSurgery && matchHospitalization && matchCt && matchMri;

  }).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('動物病院マップ 🏥',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF2D6A4F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D6A4F),
          tabs: const [
            Tab(text: '病院を探す'),
            Tab(text: '病院を登録'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSearch(),
          _buildRegister(),
        ],
      ),
    );
  }
  Widget _buildSearch() {
    return Column(
        children: [
    Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
    controller: _searchCtrl,
    decoration: InputDecoration(
    hintText: '病院名・地域で検索',
    prefixIcon: const Icon(Icons.search_rounded,
    color: Color(0xFF2D6A4F)),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none),
    filled: true,
    fillColor: Colors.white,
    ),
    ),
    ),
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
    children: _animalTypes.map((animal) {
    final selected = _selectedAnimal == animal;
    return GestureDetector(
    onTap: () => setState(() => _selectedAnimal = animal),
    child: Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(
    horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
    color: selected
    ? const Color(0xFF2D6A4F) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
    color: selected
    ? const Color(0xFF2D6A4F) : Colors.grey[300]!),
    ),
    child: Text(animal,
    style: TextStyle(
    fontSize: 13,
    color: selected ? Colors.white : Colors.grey[700],
    fontWeight: selected
    ? FontWeight.bold : FontWeight.normal)),
    ),
    );
    }).toList(),
    ),
    ),
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
    children: [
    _FilterChip(
    label: '🆘 夜間対応',
    selected: _emergencyOnly,
    onTap: () => setState(
    () => _emergencyOnly = !_emergencyOnly)),
    _FilterChip(
    label: '🦎 エキゾチック専門',
    selected: _exoticOnly,
    onTap: () => setState(
    () => _exoticOnly = !_exoticOnly)),
    _FilterChip(
    label: '🔪 手術対応',
    selected: _surgeryOnly,
    onTap: () => setState(
    () => _surgeryOnly = !_surgeryOnly)),
    _FilterChip(
    label: '🏠 入院対応',
    selected: _hospitalizationOnly,
    onTap: () => setState(
    () => _hospitalizationOnly = !_hospitalizationOnly)),
      _FilterChip(
          label: '🔬 CT対応',
          selected: _ctOnly,
          onTap: () => setState(
                  () => _ctOnly = !_ctOnly)),
      _FilterChip(
          label: '🧲 MRI対応',
          selected: _mriOnly,
          onTap: () => setState(
                  () => _mriOnly = !_mriOnly)),

    ],
    ),
    ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final h = _filtered[i];
                final speciality = h['speciality'] as int;
                return GestureDetector(
                  onTap: () => _showDetail(context, h),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFF2D6A4F).withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20))),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14)),
                                child: const Center(
                                    child: Text('🏥',
                                        style: TextStyle(fontSize: 28))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h['name'] as String,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3D2B1F))),
                                    const SizedBox(height: 2),
                                    Text(h['address'] as String,
                                        style: TextStyle(fontSize: 12,
                                            color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(3, (i) => Icon(
                                            i < speciality
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: const Color(0xFF2D6A4F),
                                            size: 16)),
                                        const SizedBox(width: 4),
                                        Text(
                                            speciality == 3 ? '専門病院'
                                                : speciality == 2 ? '積極対応'
                                                : '一応対応',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF2D6A4F),
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  if (h['emergency'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(8)),
                                      child: const Text('夜間対応',
                                          style: TextStyle(fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.amber, size: 14),
                                      Text('${h['review']}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _InfoBadge(
                                      h['surgery'] == true
                                          ? '✅ 手術対応' : '❌ 手術不可'),
                                  const SizedBox(width: 8),
                                  _InfoBadge(
                                      h['hospitalization'] == true
                                          ? '✅ 入院対応' : '❌ 入院不可'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6, runSpacing: 6,
                                children: (h['animals'] as List)
                                    .take(4).map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF2D6A4F)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(a as String,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF2D6A4F))),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
    );
  }
  void _showDetail(BuildContext context, Map h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏥', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h['name'] as String,
                                  style: const TextStyle(fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF3D2B1F))),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(h['badge'] as String,
                                    style: const TextStyle(fontSize: 12,
                                        color: Color(0xFF2D6A4F),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(Icons.location_on_rounded,
                        h['address'] as String),
                    const SizedBox(height: 8),
                    _DetailRow(Icons.phone_rounded, h['phone'] as String),
                    const SizedBox(height: 8),
                    _DetailRow(Icons.access_time_rounded,
                        h['hours'] as String),
                    const SizedBox(height: 8),
                    _DetailRow(Icons.calendar_today_rounded,
                        '休診日: ${h['holiday']}'),
                    const Divider(height: 32),
                    const Text('対応情報',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _InfoBadge(h['surgery'] == true
                            ? '✅ 手術対応' : '❌ 手術不可'),
                        _InfoBadge(h['hospitalization'] == true
                            ? '✅ 入院対応' : '❌ 入院不可'),
                        _InfoBadge(h['emergency'] == true
                            ? '✅ 夜間対応' : '❌ 夜間不可'),
                        _InfoBadge(h['exotic'] == true
                            ? '✅ エキゾチック対応' : '❌ エキゾチック不可'),
                        _InfoBadge(h['ct'] == true
                            ? '✅ CT対応' : '❌ CT非対応'),
                        _InfoBadge(h['mri'] == true
                            ? '✅ MRI対応' : '❌ MRI非対応'),

                      ],
                    ),
                    const Divider(height: 32),
                    const Text('対応動物',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const Text('在籍している先生',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    ...(h['doctors'] as List).map((doc) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF2D6A4F).withOpacity(0.2))),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              color: Color(0xFF2D6A4F), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3D2B1F))),
                                Text(doc['specialty'] as String,
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('経験${doc['experience']}',
                                style: const TextStyle(fontSize: 11,
                                    color: Color(0xFF2D6A4F),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.update_rounded,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('最終更新：${h['lastUpdated']}',
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey[500])),
                      ],
                    ),
                    const Divider(height: 32),

                    const Text('専門動物',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (h['specialtyAnimals'] as List).map((a) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.5))),
                            child: Text(a as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold)),
                          )).toList(),
                    ),
                    const Divider(height: 32),

                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (h['animals'] as List).map((a) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(a as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2D6A4F),
                                    fontWeight: FontWeight.bold)),
                          )).toList(),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Text('口コミ評価',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        Text('${h['review']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(' (${h['reviewCount']}件)',
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showReviewForm(context, h);
                        },

                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('口コミを書く',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showReviewForm(BuildContext context, Map h) {
    String? _selectedRating;
    final _commentCtrl = TextEditingController();
    final _questions = [
      '専門知識はありましたか？',
      'HPの情報と実際は一致していましたか？',
      'スタッフの対応は良かったですか？',
      '再診したいと思いますか？',
    ];
    final _answers = <String, String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('口コミを書く',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D2B1F))),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('評価',
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => GestureDetector(
                          onTap: () => setModalState(() =>
                          _selectedRating = '${i + 1}'),
                          child: Icon(
                              _selectedRating != null &&
                                  int.parse(_selectedRating!) > i
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber, size: 40),
                        )),
                      ),
                      const SizedBox(height: 20),
                      ..._questions.map((q) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q,
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          const SizedBox(height: 8),
                          Row(
                            children: ['はい', 'いいえ', 'どちらとも'].map((ans) {
                              final sel = _answers[q] == ans;
                              return GestureDetector(
                                onTap: () => setModalState(() =>
                                _answers[q] = ans),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF2D6A4F)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? const Color(0xFF2D6A4F)
                                              : Colors.grey[300]!)),
                                  child: Text(ans,
                                      style: TextStyle(fontSize: 13,
                                          color: sel
                                              ? Colors.white : Colors.grey[700])),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )),
                      const Text('コメント',
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '実際に診てもらった感想を書いてください',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2D6A4F))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('口コミを投稿しました！🙏'),
                                backgroundColor: Color(0xFF2D6A4F),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A4F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('投稿する',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
                borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('病院情報を登録する🏥',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('知っている病院の情報を\nみんなで共有しましょう！',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('この機能はリリース後に使えます！\n病院情報をみんなで共有できるようになります🐾',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFF2D6A4F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? const Color(0xFF2D6A4F) : Colors.grey[300]!)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected
                    ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;
  const _InfoBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(fontSize: 12)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2D6A4F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
      ],
    );
  }
}
