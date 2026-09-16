import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import 'profile_setup_page2.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
final _nameCtrl = TextEditingController();
final _ageCtrl = TextEditingController();
final List<String> _selectedAnimals = [];
String? _selectedGender;
String? _selectedPrefecture;
File? _profileImage;
String? _profileImageUrl;
bool _isUploadingImage = false;

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

@override
void dispose() {
_nameCtrl.dispose();
_ageCtrl.dispose();
super.dispose();
}

void _next() {
if (_nameCtrl.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('ニックネームを入力してください'),
backgroundColor: Colors.red),
);
return;
}
if (_ageCtrl.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('年齢を入力してください'),
backgroundColor: Colors.red),
);
return;
}
if (_selectedPrefecture == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('都道府県を選択してください'),
backgroundColor: Colors.red),
);
return;
}
if (_selectedAnimals.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('好きな動物を選択してください'),
backgroundColor: Colors.red),
);
return;
}
if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('プロフィール画像を設定してください'),
backgroundColor: Colors.red,
),
);
return;
}

final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
if (age < 13 || age > 100) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('正しい年齢を入力してください（13〜100歳）'),
backgroundColor: Colors.red),
);
return;
}


Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ProfileSetupPage2(
name: _nameCtrl.text.trim(),
age: int.parse(_ageCtrl.text.trim()),
prefecture: _selectedPrefecture!,
animal: _selectedAnimals.join('、'),
gender: _selectedGender,
profileImageUrl: _profileImageUrl,
),
),
);
}
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFFFFFF5F3),
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
Text('プロフィール設定',


style: TextStyle(fontSize: 28,
fontWeight: FontWeight.w900,
color: Colors.white)),
SizedBox(height: 8),
Text('STEP 1 / 2',
style: TextStyle(fontSize: 13,
color: Colors.white70)),
SizedBox(height: 4),
Text('基本情報を教えてください🐾',
style: TextStyle(fontSize: 13,
color: Colors.white70)),
],
),
),
Padding(
padding: const EdgeInsets.all(24),


child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: GestureDetector(
  onTap: () async {
    setState(() => _isUploadingImage = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      _profileImageUrl = url;
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
color: const Color(0xFFE8845A).withOpacity(0.1),
border: Border.all(
color: const Color(0xFFE8845A), width: 2)),
child: _isUploadingImage
? const Center(child: CircularProgressIndicator(
color: Color(0xFFE8845A)))
: _profileImageUrl != null
? ClipOval(child: Image.network(
_profileImageUrl!,
fit: BoxFit.cover,
width: 100, height: 100))
: const Center(child: Text('🐾',
style: TextStyle(fontSize: 40))),
),
Positioned(
right: 0, bottom: 0,
child: Container(
padding: const EdgeInsets.all(6),
decoration: const BoxDecoration(
color: Color(0xFFE8845A),
shape: BoxShape.circle),
child: const Icon(Icons.camera_alt_rounded,
color: Colors.white, size: 16),
),
),
],
),
),
),
  const SizedBox(height: 16),
  const Text('ニックネーム',
      style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  TextField(
    controller: _nameCtrl,
    decoration: InputDecoration(
      hintText: 'ニックネームを入力',
      prefixIcon: const Icon(Icons.person_outline,
          color: Color(0xFFE8A598)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: Color(0xFFE8A598)),
      ),
      filled: true, fillColor: Colors.white,
    ),
  ),
  const SizedBox(height: 16),
  const Text('年齢',
      style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  TextField(
    controller: _ageCtrl,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      hintText: '例：25',
      prefixIcon: const Icon(Icons.cake_outlined,
          color: Color(0xFFE8A598)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: Color(0xFFE8A598)),
      ),
      filled: true, fillColor: Colors.white,
    ),
  ),
  const SizedBox(height: 16),
  const Text('都道府県',
      style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  DropdownButtonFormField<String>(
    value: _selectedPrefecture,
    hint: const Text('都道府県を選択'),
    items: _prefectures.map((p) =>
        DropdownMenuItem(value: p, child: Text(p))).toList(),
    onChanged: (v) => setState(() => _selectedPrefecture = v),
    decoration: InputDecoration(
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
      filled: true, fillColor: Colors.white,
    ),
  ),
  const SizedBox(height: 16),
  const Text('好きな動物（複数選択可）',
      style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8, runSpacing: 8,
    children: _animals.map((animal) {
      final isSelected = _selectedAnimals.contains(animal['name']);
      return GestureDetector(
        onTap: () => setState(() {
          if (isSelected) {
            _selectedAnimals.remove(animal['name']);
          } else {
            _selectedAnimals.add(animal['name']!);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8845A)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8845A)
                    : Colors.grey.shade300),
          ),
          child: Text(
            '${animal['emoji']} ${animal['name']}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 16),
  const Text('性別',
      style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8, runSpacing: 8,
    children: [
      {'name': '男性', 'emoji': '👨'},
      {'name': '女性', 'emoji': '👩'},
      {'name': 'その他・回答しない', 'emoji': '🌈'},
    ].map((g) {
      final isSelected = _selectedGender == g['name'];
      return GestureDetector(
        onTap: () => setState(
                () => _selectedGender = g['name']),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8845A)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8845A)
                    : Colors.grey.shade300),
          ),
          child: Text(
            '${g['emoji']} ${g['name']}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
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
      onPressed: _next,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8845A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('次へ →',
          style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.bold)),
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
