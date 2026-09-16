import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'root_page.dart';

class UserProfilePage extends StatefulWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
Map<String, dynamic>? _userData;
List<Map<String, dynamic>> _pets = [];
bool _isLoading = true;
bool _isMyProfile = false;

@override
void initState() {
super.initState();
_loadUserData();
}

Future<void> _loadUserData() async {
try {
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null) {
_isMyProfile = currentUser.uid == widget.uid;
}

final myUid2 = FirebaseAuth.instance.currentUser?.uid;
if (myUid2 != null) {
final blockedByDoc = await FirebaseFirestore.instance
.collection('blocks')
.doc(widget.uid)
.collection('blocked')
.doc(myUid2)
.get();
if (blockedByDoc.exists && mounted) {
setState(() => _isLoading = false);
return;
}
}

final doc = await FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.get();
if (doc.exists && mounted) {
final petsSnapshot = await FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.collection('pets')
.get();
final pets = petsSnapshot.docs.map((d) => d.data()).toList();

setState(() {
_userData = doc.data();
_pets = pets;
_isLoading = false;
});
}
} catch (e) {
print('🔥 エラー: $e');
if (mounted) setState(() => _isLoading = false);
}
}

void _showBlockDialog() {
showDialog(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('ブロックしますか？'),
content: const Text('ブロックするとこのユーザーは表示されなくなります。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () async {
Navigator.pop(context);
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;
await FirebaseFirestore.instance
.collection('blocks')
.doc(myUid)
.collection('blocked')
.doc(widget.uid)
.set({'createdAt': FieldValue.serverTimestamp()});
if (mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(builder: (_) => const RootPage(initialIndex: 3)),
(route) => false,
);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('ブロックしました'),
backgroundColor: Colors.orange,
),
);
}
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
}

void _showReportDialog() {
showDialog(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('通報しますか？'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text('通報する理由を選んでください'),
const SizedBox(height: 12),
...['スパム', '不適切なコンテンツ', '嫌がらせ', 'なりすまし', 'その他'].map((reason) =>
ListTile(
title: Text(reason),
onTap: () async {
Navigator.pop(context);
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;
await FirebaseFirestore.instance
.collection('reports')
.add({
'type': 'user',
'reporterId': myUid,
'targetId': widget.uid,
'reason': reason,
'createdAt': FieldValue.serverTimestamp(),
});

await FirebaseFirestore.instance
.collection('blocks')
.doc(myUid)
.collection('blocked')
.doc(widget.uid)
.set({'createdAt': FieldValue.serverTimestamp()});

if (mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(builder: (_) => const RootPage(initialIndex: 3)),
(route) => false,
);
}

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('通報しました。ご報告ありがとうございます。'),
backgroundColor: Color(0xFFE8845A),
),
);
}
},
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
],
),
);
}
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
    );
  }

  if (_userData == null) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3D2B1F)),
        ),
      ),
      backgroundColor: const Color(0xFFFFF8F5),
      body: const Center(child: Text('ユーザーが見つかりません')),
    );
  }

  final name = _userData!['name'] ?? '';
  final age = _userData!['age'] ?? '';
  final prefecture = _userData!['prefecture'] ?? '';
  final animal = _userData!['animal'] ?? '';
  final bio = _userData!['bio'] ?? '';

  return Scaffold(
    backgroundColor: const Color(0xFFFFF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFFF8F5),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3D2B1F)),
      ),
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
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
                      name.isNotEmpty ? name[0] : '🐾',
                      style: const TextStyle(
                          fontSize: 40,
                          color: Color(0xFFE8845A),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D2B1F))),
                Text('$age歳・$prefecture', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('$animal好き',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection('📝 自己紹介',
            Text(bio.isNotEmpty ? bio : '自己紹介はありません',
                style: TextStyle(
                    fontSize: 14,
                    color: bio.isNotEmpty ? const Color(0xFF3D2B1F) : Colors.grey,
                    height: 1.6)),
          ),
          const SizedBox(height: 16),
          _buildSection('🐾 ペット情報',
            _pets.isEmpty
                ? Text('ペット情報なし', style: TextStyle(fontSize: 13, color: Colors.grey[500]))
                : Column(
              children: _pets.map((pet) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F5),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: pet['imageUrl'] != null &&
                          (pet['imageUrl'] as String).isNotEmpty
                          ? Image.network(pet['imageUrl'],
                          width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                          width: 56, height: 56,
                          color: Colors.orange[50],
                          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 28)))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pet['name']}（${pet['type']}）',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                          if ((pet['age'] ?? '').toString().isNotEmpty)
                            Text(pet['age'].toString(),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          if (!_isMyProfile) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showBlockDialog,
                      icon: const Icon(Icons.block_rounded, color: Colors.grey),
                      label: const Text('ブロック', style: TextStyle(color: Colors.grey)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showReportDialog,
                      icon: const Icon(Icons.flag_rounded, color: Colors.red),
                      label: const Text('通報', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

Widget _buildSection(String title, Widget content) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 12),
          content,
        ],
      ),
    ),
  );
}
}
