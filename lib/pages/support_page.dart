import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import 'hospital_page.dart';
import 'pet_friendly_page.dart';

const _adoptionPets = [
  {
    'name': 'ハナ',
    'type': '犬',
    'age': '2歳',
    'emoji': '🐕',
    'location': '東京',
    'desc': '人懐こくて甘えん坊な女の子です。散歩が大好き！',
    'urgent': false,
  },
  {
    'name': 'クロ',
    'type': '猫',
    'age': '3歳',
    'emoji': '🐱',
    'location': '大阪',
    'desc': 'おっとりした男の子。室内飼いに向いています。',
    'urgent': false,
  },
  {
    'name': 'ソラ',
    'type': '犬',
    'age': '1歳',
    'emoji': '🐶',
    'location': '福岡',
    'desc': '元気いっぱいの子犬！一緒に走り回りたい！',
    'urgent': true,
  },
  {
    'name': 'モモ',
    'type': '猫',
    'age': '5歳',
    'emoji': '😺',
    'location': '京都',
    'desc': 'のんびり屋さんの女の子。静かな環境が好きです。',
    'urgent': false,
  },
  {
    'name': 'レオ',
    'type': '犬',
    'age': '4歳',
    'emoji': '🦮',
    'location': '名古屋',
    'desc': '訓練済みの大型犬。広い庭のあるご家庭に向いています。',
    'urgent': true,
  },
  {
    'name': 'ユキ',
    'type': '猫',
    'age': '2歳',
    'emoji': '🐈',
    'location': '札幌',
    'desc': '白くてふわふわな女の子。人懐こくて遊び好きです。',
    'urgent': false,
  },
];

const _volunteerJobs = [
  {
    'title': '週末ボランティア',
    'org': '保護団体AniCare',
    'location': '東京・世田谷',
    'emoji': '🌱',
    'desc': '週末2時間から参加できます。犬の散歩・猫のお世話など。',
  },
  {
    'title': '一時預かりボランティア',
    'org': '保護団体HappyPaws',
    'location': '大阪・梅田',
    'emoji': '🏠',
    'desc': '里親が見つかるまでの間、自宅でお世話をしていただきます。',
  },
  {
    'title': 'SNS発信ボランティア',
    'org': '保護団体AniCare',
    'location': 'オンライン',
    'emoji': '📱',
    'desc': '保護動物の情報をSNSで発信するボランティアです。',
  },
];

const _supplies = [
  {'name': 'ドッグフード（成犬用）', 'emoji': '🍖', 'urgent': true},
  {'name': 'キャットフード', 'emoji': '🐟', 'urgent': true},
  {'name': 'ペットシーツ', 'emoji': '📄', 'urgent': false},
  {'name': 'タオル・毛布', 'emoji': '🛁', 'urgent': false},
  {'name': 'ケージ・キャリー', 'emoji': '🏠', 'urgent': true},
  {'name': '医療費支援', 'emoji': '💊', 'urgent': true},
];

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('支援・保護活動 🌱',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF2D6A4F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D6A4F),
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: '里親募集'),
            Tab(text: 'ボランティア'),
            Tab(text: 'フード支援'),
            Tab(text: '募金'),
            Tab(text: '病院マップ'),
            Tab(text: 'カフェ・公園'),

          ],
        ),

      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAdoption(),
          _buildVolunteer(),
          _buildSupplies(),
          _buildDonation(),
          const HospitalPage(),
          const PetFriendlyPage(),

        ],

      ),
    );
  }
  Widget _buildAdoption() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                  blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('里親募集中🐾',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('あなたの愛で命を救えます\n一頭でも多くの子に温かい家を',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('⚠️ 緊急里親募集',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          ..._adoptionPets.where((p) => p['urgent'] == true).map((pet) =>
              _buildPetCard(context, pet, isUrgent: true)),
          const SizedBox(height: 16),
          const Text('里親募集中',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          ..._adoptionPets.where((p) => p['urgent'] == false).map((pet) =>
              _buildPetCard(context, pet, isUrgent: false)),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, Map pet,
      {required bool isUrgent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [BoxShadow(
            color: isUrgent
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Center(
                child: Text(pet['emoji'] as String,
                    style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pet['name'] as String,
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(width: 8),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('緊急',
                            style: TextStyle(fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text('${pet['type']}・${pet['age']}・${pet['location']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(pet['desc'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              globalProvider.addSupport();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('${pet['name']}の里親申請'),
                  content: const Text(
                      '里親申請を送りますか？\n担当者から連絡があります。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('申請を送りました！❤️ 支援者バッジを獲得！'),
                              backgroundColor: Color(0xFF2D6A4F),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white),
                        child: const Text('申請する')),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isUrgent ? Colors.red : const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
            ),
            child: const Text('申請',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Widget _buildVolunteer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                  blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ボランティア募集🌱',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('あなたの時間と愛情で\n動物たちを救えます',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._volunteerJobs.map((job) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(job['emoji'] as String,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['title'] as String,
                              style: const TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          Text('${job['org']} ・ ${job['location']}',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(job['desc'] as String,
                    style: TextStyle(fontSize: 13,
                        color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ボランティア応募を送りました！🌱'),
                          backgroundColor: Color(0xFF2D6A4F),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('応募する',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  Widget _buildSupplies() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFFE8845A).withOpacity(0.3),
                  blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('フード・備品支援🍖',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('保護施設に必要な物資を支援できます\nあなたの支援が命を救います',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('⚠️ 緊急で必要なもの',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          ..._supplies.where((s) => s['urgent'] == true).map((supply) =>
              _buildSupplyCard(supply, urgent: true)),
          const SizedBox(height: 16),
          const Text('必要なもの',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          ..._supplies.where((s) => s['urgent'] == false).map((supply) =>
              _buildSupplyCard(supply, urgent: false)),
        ],
      ),
    );
  }

  Widget _buildSupplyCard(Map supply, {required bool urgent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: urgent ? Border.all(color: Colors.red, width: 1.5) : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text(supply['emoji'] as String,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(supply['name'] as String,
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D2B1F))),
          ),
          if (urgent)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('緊急',
                  style: TextStyle(fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ElevatedButton(
            onPressed: () {
              globalProvider.addSupport();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${supply['name']}の支援申請を送りました！🙏'),
                  backgroundColor: const Color(0xFFE8845A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: urgent ? Colors.red : const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8)),
            child: const Text('支援',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDonation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                  blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('募金・寄付💝',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('あなたの募金が\n動物たちの命を救います',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 募金額選択
          const Text('支援金額を選ぶ',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2,
            children: ['300円', '500円', '1000円',
              '3000円', '5000円', 'その他'].map((amount) =>
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$amountの募金はリリース後に使えます！'),
                        backgroundColor: const Color(0xFF2D6A4F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2D6A4F).withOpacity(0.3)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text(amount,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D6A4F))),
                    ),
                  ),
                )).toList(),
          ),
          const SizedBox(height: 20),
          const Text('支援の使い道',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 12),
          ...[
            {'emoji': '🍖', 'text': 'フード代・医療費'},
            {'emoji': '🏠', 'text': '保護施設の維持費'},
            {'emoji': '🚗', 'text': '保護活動の交通費'},
            {'emoji': '💊', 'text': 'ワクチン・不妊手術費'},
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(item['emoji']!,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(item['text']!,
                    style: TextStyle(fontSize: 14,
                        color: Colors.grey[700])),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('募金機能はリリース後に使えます！'),
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
              child: const Text('募金する💝',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
