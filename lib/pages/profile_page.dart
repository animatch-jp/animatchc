import 'pet_detail_page.dart';
import 'edit_profile_page.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'delete_account_page.dart';
import 'notification_settings_page.dart';
import 'abuse_report_page.dart';
import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'privacy_page.dart';
import 'terms_page.dart';
import 'contact_page.dart';
import 'login_page.dart';
import '../services/cloudinary_service.dart';
import 'admin_page.dart';
import 'block_list_page.dart';
import 'badge_progress_page.dart';
import 'help_page.dart';


class PetData {
  String id;
  String name;
  String type;
  String age;
  String bio;
  List<String> tags;
  String? imageUrl;

  PetData({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.bio,
    required this.tags,
    this.imageUrl,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {


Map<String, dynamic>? _userData;
String _userName = '';
int _unreadCount = 0;
Stream<int>? _unreadStream;
int _userAge = 0;
String _userPrefecture = '';
String _userAnimal = '';
String _userBio = '';
String _userRelation = '';
bool _isLoading = true;
int _bragCount = 0;
String _userMotto = '';
List<String> _earnedBadges = [];
List<String> _userInterests = [];
List<String> _userSpots = [];
List<PetData> _pets = [];


@override
void initState() {
super.initState();
_loadUserData();
_setupUnreadStream();
}

void _setupUnreadStream() {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

_unreadStream = FirebaseFirestore.instance
.collection('notifications')
.doc(myUid)
.collection('items')
.where('read', isEqualTo: false)
.snapshots()
.map((snapshot) => snapshot.docs.length);
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

final petsSnapshot = await FirebaseFirestore.instance
.collection('users')
.doc(user.uid)
.collection('pets')
.get();

final bragSnapshot = await FirebaseFirestore.instance
.collection('petBrags')
.where('uid', isEqualTo: user.uid)
.get();

setState(() {
_userName = data['name'] ?? '';
_userAge = data['age'] ?? 0;
_userPrefecture = data['prefecture'] ?? '';
_userAnimal = data['animal'] ?? '';
_userBio = data['bio'] ?? '';
_userRelation = data['relation'] ?? '';
_userMotto = data['motto'] ?? '';
_userInterests = List<String>.from(data['interests'] ?? []);
_userSpots = List<String>.from(data['spots'] ?? []);
_bragCount = bragSnapshot.docs.length;
_earnedBadges = List<String>.from(data['badges'] ?? []);


_pets = petsSnapshot.docs.map((d) => PetData(
id: d.id,
name: d['name'] ?? '',
type: d['type'] ?? '',
age: (d['age'] ?? '').toString(),
bio: d['bio'] ?? '',
tags: List<String>.from(d['tags'] ?? []),
imageUrl: d.data().containsKey('imageUrl')
? d['imageUrl'] : null,
)).toList();
_isLoading = false;
});
}
}
} catch (e) {
print('🔥 データ取得エラー: $e');
if (mounted) setState(() => _isLoading = false);
}
}
Future<void> _loadUnreadCount() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

final snapshot = await FirebaseFirestore.instance
.collection('notifications')
.doc(myUid)
.collection('items')
.where('read', isEqualTo: false)
.get();

if (mounted) {
setState(() {
_unreadCount = snapshot.docs.length;
});
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
Future<void> _deletePet(PetData pet) async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;
await FirebaseFirestore.instance
.collection('users')
.doc(user.uid)
.collection('pets')
.doc(pet.id)
.delete();
setState(() => _pets.removeWhere((p) => p.id == pet.id));
}
void _editPet(int index) {
final pet = _pets[index];
final nameCtrl = TextEditingController(text: pet.name);
final typeCtrl = TextEditingController(text: pet.type);
final ageCtrl = TextEditingController(text: pet.age);
final bioCtrl = TextEditingController(text: pet.bio);
List<String> selectedTags = List.from(pet.tags);
String? imageUrl = pet.imageUrl;
bool isUploadingImage = false;

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
style: TextStyle(
fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 16),
Center(
child: GestureDetector(
  onTap: () async {
    setModalState(() => isUploadingImage = true);
    final url =
    await CloudinaryService.pickAndUploadImage();
    setModalState(() {
      if (url != null) imageUrl = url;
      isUploadingImage = false;
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
width: 80, height: 80,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
color: Colors.orange[50]),
child: isUploadingImage
? const Center(child: CircularProgressIndicator(
color: Color(0xFFE8845A)))
: imageUrl != null && imageUrl!.isNotEmpty
? ClipRRect(
borderRadius: BorderRadius.circular(16),
child: Image.network(imageUrl!,
width: 80, height: 80,
fit: BoxFit.cover))
: const Center(child: Text('🐾',
style: TextStyle(fontSize: 36))),
),
Positioned(
right: 0, bottom: 0,
child: Container(
padding: const EdgeInsets.all(4),
decoration: const BoxDecoration(
color: Color(0xFFE8845A),
shape: BoxShape.circle),
child: const Icon(Icons.camera_alt_rounded,
color: Colors.white, size: 14),
),
),
],
),
),
),
const SizedBox(height: 16),
_EditField(label: '名前', ctrl: nameCtrl),
const SizedBox(height: 12),
_EditField(label: '種類', ctrl: typeCtrl),
const SizedBox(height: 12),
_EditField(label: '年齢', ctrl: ageCtrl,
keyboardType: TextInputType.number,
),
const SizedBox(height: 12),
_EditField(label: '自己紹介', ctrl: bioCtrl, maxLines: 3),
const SizedBox(height: 16),
const Text('性格タグ',
style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Wrap(
spacing: 8, runSpacing: 8,
children:['元気', '人懐っこい', 'おっとり', 'やんちゃ', '甘えん坊',
'独立心強い', '賢い', '遊び好き', '食いしん坊', 'ビビリ']

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
color: sel
? const Color(0xFFE8845A)
: Colors.grey[100],
borderRadius: BorderRadius.circular(20)),
child: Text(tag,
style: TextStyle(fontSize: 12,
color: sel
? Colors.white
: Colors.grey[700])),
),
);
}).toList(),
),
const SizedBox(height: 20),
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;
await FirebaseFirestore.instance
.collection('users')
.doc(user.uid)
.collection('pets')
.doc(pet.id)
.update({
'name': nameCtrl.text,
'type': typeCtrl.text,
'age': ageCtrl.text,
'bio': bioCtrl.text,
'tags': selectedTags,
'imageUrl': imageUrl ?? '',
});
setState(() {
pet.name = nameCtrl.text;
pet.type = typeCtrl.text;
pet.age = ageCtrl.text;
pet.bio = bioCtrl.text;
pet.tags = selectedTags;
pet.imageUrl = imageUrl;
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
style: TextStyle(
fontSize: 16, fontWeight: FontWeight.bold)),
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
    StreamBuilder<int>(

stream: _unreadStream,
builder: (context, snapshot) {
final unreadCount = snapshot.data ?? 0;
return IconButton(
onPressed: () async {
await Navigator.push(context,
MaterialPageRoute(
builder: (_) => const NotificationPage()));
_setupUnreadStream();
},
icon: Stack(
children: [
const Icon(Icons.notifications_rounded,
color: Color(0xFFE8845A), size: 28),
if (unreadCount > 0)
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
);
},
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
child: _userData?['profileImageUrl'] != null &&
(_userData!['profileImageUrl'] as String).isNotEmpty
? ClipOval(
child: Image.network(
_userData!['profileImageUrl'] as String,
width: 90, height: 90,
fit: BoxFit.cover,
),
)
: Center(
child: Text(
_userName.isNotEmpty ? _userName[0] : '🐾',
style: const TextStyle(
fontSize: 44,
color: Color(0xFFE8845A),
fontWeight: FontWeight.bold),
),
),
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
      style: const TextStyle(
          color: Colors.grey, fontSize: 13)),
  if (_userMotto.isNotEmpty) ...[
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFE8845A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14)),
      child: Text('💬 $_userMotto',
          style: const TextStyle(fontSize: 13, color: Color(0xFFE8845A))),
    ),
  ],
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
      'bio': _userBio,
      'relation': _userRelation,
      'motto': _userMotto,
      'interests': _userInterests,
      'spots': _userSpots,
      'profileImageUrl':
      _userData?['profileImageUrl'],
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
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatItem('$_bragCount', 'ペット自慢投稿'),
        ],
      ),
    ),
  ),
  const SizedBox(height: 16),
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
              const Text('バッジ 🏅',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BadgeProgressPage())),
                child: const Text('達成状況を見る',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE8845A))),
              ),

            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _BadgeItem(
                emoji: '🏅',
                label: 'うちの子\nお題マスター',
                sublabel: 'うちの子系(30個)',
                earned: _earnedBadges.contains('うちの子お題マスター'),
              ),
              const SizedBox(width: 16),
              _BadgeItem(
                emoji: '🔍',
                label: '発見マスター',
                sublabel: '誰でも系(20個)',
                earned: _earnedBadges.contains('発見マスター'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  const SizedBox(height: 16),
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
children: ['🏠 飼ってる', '👀 見るのが好き',
'🔥 ガチ勢', '🌱 これから飼いたい']
.map((r) {
final sel = r.contains(_userRelation) &&
_userRelation.isNotEmpty;
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: sel
? const Color(0xFFE8845A)
: Colors.grey[100],
borderRadius: BorderRadius.circular(20)),
child: Text(r,
style: TextStyle(fontSize: 13,
color: sel
? Colors.white
: Colors.grey[600])),
);
}).toList(),
),
],
),
),
),
  if (_userInterests.isNotEmpty) ...[
    const SizedBox(height: 16),
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
            const Text('好きなこと 🐾',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _userInterests.map((it) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8845A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(it,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE8845A))),
              )).toList(),
            ),
          ],
        ),
      ),
    ),
  ],
  if (_userSpots.isNotEmpty) ...[
    const SizedBox(height: 16),
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
            const Text('よく行く場所 📍',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _userSpots.map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(s,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D6A4F))),
              )).toList(),
            ),
          ],
        ),
      ),
    ),
  ],
  const SizedBox(height: 16),
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
style: TextStyle(
color: Color(0xFFE8845A),
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
    return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetDetailPage(
              uid: FirebaseAuth.instance.currentUser?.uid ?? '',
              petId: pet.id,
              petName: pet.name,
              petType: pet.type,
              petAge: pet.age,
              petBio: pet.bio,
              petTags: pet.tags,
              petImageUrl: pet.imageUrl,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8F5),
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              ClipRRect(

borderRadius: BorderRadius.circular(10),
child: pet.imageUrl != null &&
pet.imageUrl!.isNotEmpty
? Image.network(pet.imageUrl!,
width: 56, height: 56,
fit: BoxFit.cover)
: Container(
width: 56, height: 56,
color: Colors.orange[50],
child: const Center(
child: Text('🐾',
style: TextStyle(
fontSize: 28)))),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text('${pet.name}（${pet.type}）',
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
Text(pet.age.isNotEmpty ? pet.age : '',
style: TextStyle(fontSize: 12,
color: Colors.grey[600])),
Wrap(
spacing: 4,
children: pet.tags.map((tag) =>
Container(
padding: const EdgeInsets
.symmetric(
horizontal: 8,
vertical: 2),
decoration: BoxDecoration(
color: const Color(
0xFFE8845A)
.withOpacity(0.1),
borderRadius:
BorderRadius.circular(
8)),
child: Text(tag,
style: const TextStyle(
fontSize: 10,
color: Color(
0xFFE8845A))),
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
                      onPressed: () => _deletePet(pet),
                      icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red, size: 20)),
                ],
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 20),
            ],
          ),
        ),
    );
  }),

        ],
),
),
),
  const SizedBox(height: 16),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: '使い方ガイド',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const HelpPage())),
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.block_rounded,
            label: 'ブロックリスト',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const BlockListPage())),
          ),
          const Divider(height: 1),


          _MenuItem(
            icon: Icons.notifications_rounded,
            label: '通知設定🔔',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) =>
                    const NotificationSettingsPage())),
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
            icon: Icons.admin_panel_settings_rounded,
            label: '運営管理画面',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const AdminPage())),
          ),

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
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
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
  String? _imageUrl;
  bool _isUploadingImage = false;

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
          Center(
            child: GestureDetector(
              onTap: () async {
                setState(() => _isUploadingImage = true);
                final url = await CloudinaryService.pickAndUploadImage();
                setState(() {
                  if (url != null) _imageUrl = url;
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
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.orange[50]),
                    child: _isUploadingImage
                        ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFFE8845A)))
                        : _imageUrl != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_imageUrl!,
                            width: 80, height: 80,
                            fit: BoxFit.cover))
                        : const Center(child: Text('🐾',
                        style: TextStyle(fontSize: 36))),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE8845A),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _EditField(label: '名前', ctrl: _nameCtrl),
          const SizedBox(height: 12),
          _EditField(label: '種類', ctrl: _typeCtrl),
          const SizedBox(height: 12),
          _EditField(label: '年齢', ctrl: _ageCtrl,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _EditField(label: '自己紹介', ctrl: _bioCtrl, maxLines: 3),
          const SizedBox(height: 16),
          const Text('性格タグ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children:['元気', '人懐っこい', 'おっとり', 'やんちゃ', '甘えん坊',
              '独立心強い', '賢い', '遊び好き', '食いしん坊', 'ビビリ']
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
                  'age': _ageCtrl.text,
                  'bio': _bioCtrl.text,
                  'tags': _selectedTags,
                  'imageUrl': _imageUrl ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                };
                final docRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('pets')
                    .add(petData);
                widget.onAdd(PetData(
                  id: docRef.id,
                  name: _nameCtrl.text,
                  type: _typeCtrl.text,
                  age: _ageCtrl.text,
                  bio: _bioCtrl.text,
                  tags: _selectedTags,
                  imageUrl: _imageUrl,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8845A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('追加する',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
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
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

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
class _BadgeItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final bool earned;

  const _BadgeItem({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned
                  ? const LinearGradient(
                  colors: [Color(0xFFE8845A), Color(0xFFF4A261)])
                  : null,
              color: earned ? null : Colors.grey[200],
            ),
            child: Center(
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 28,
                      color: earned ? null : Colors.grey[400])),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: earned ? const Color(0xFF3D2B1F) : Colors.grey[400])),
          Text(sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
