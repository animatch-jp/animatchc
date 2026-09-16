import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import '../services/cloudinary_service.dart';
import 'organization_chat_list_page.dart';
import 'prefectures.dart';
import 'notification_page.dart';
import 'lost_pet_page.dart';



class OrganizationHomePage extends StatefulWidget {
  const OrganizationHomePage({super.key});

  @override
  State<OrganizationHomePage> createState() => _OrganizationHomePageState();
}

class _OrganizationHomePageState extends State<OrganizationHomePage> {
Map<String, dynamic>? _orgData;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadOrgData();
}

Future<void> _loadOrgData() async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final doc = await FirebaseFirestore.instance
.collection('organizations')
.doc(uid)
.get();
if (mounted) {
setState(() {
_orgData = doc.data();
_isLoading = false;
});
}
}

void _showAdoptionPostSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding:
EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _AdoptionPostSheet(
orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
orgName: _orgData?['name'] ?? '',
onPosted: () {
Navigator.pop(context);
},
),
),
);
}
void _showEditOrgSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _EditOrgSheet(
orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
currentData: _orgData ?? {},
onSaved: () {
Navigator.pop(context);
_loadOrgData();
},
),
),
);
}


void _showVolunteerPostSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding:
EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _VolunteerPostSheet(
orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
orgName: _orgData?['name'] ?? '',
onPosted: () {
Navigator.pop(context);
},
),
),
);
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

@override
Widget build(BuildContext context) {
if (_isLoading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A))),
);
}

return Scaffold(
backgroundColor: const Color(0xFFFFF8F5),
appBar: AppBar(
title: const Text('団体マイページ 🏢',
style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
backgroundColor: const Color(0xFFFFF8F5),
elevation: 0,
automaticallyImplyLeading: false,
  actions: [
    IconButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => const NotificationPage())),
      icon: const Icon(Icons.notifications_outlined,
          color: Color(0xFFE8845A)),
    ),
    IconButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => const OrganizationChatListPage())),
      icon: const Icon(Icons.chat_bubble_outline_rounded,
          color: Color(0xFFE8845A)),
    ),

    IconButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('ログアウトしますか？'),
            content: const Text('もう一度ログインが必要になります'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845A),
                    foregroundColor: Colors.white),
                child: const Text('ログアウト'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          _logout();
        }
      },
      icon: const Icon(Icons.logout_rounded, color: Color(0xFFE8845A)),
    ),
  ],

),
body: Padding(
padding: const EdgeInsets.all(20),
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(_orgData?['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            IconButton(
              onPressed: _showEditOrgSheet,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
        if ((_orgData?['nameUpdatePending'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('団体名の変更を確認中です',
                style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
        const SizedBox(height: 8),
        Text(_orgData?['activityDescription'] ?? '',
            style: const TextStyle(
                fontSize: 13, color: Colors.white70, height: 1.5)),
        if ((_orgData?['activityUpdatePending'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('活動内容の変更を確認中です',
                style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
      ],
    ),
  ),
  const SizedBox(height: 24),

const Text('投稿管理',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
const SizedBox(height: 12),
GestureDetector(
onTap: _showAdoptionPostSheet,
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
borderRadius: BorderRadius.circular(16)),
child: const Row(
children: [
Text('🐾', style: TextStyle(fontSize: 24)),
SizedBox(width: 12),
Expanded(
child: Text('里親募集を投稿する',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: Colors.white)),
),
Icon(Icons.arrow_forward_ios_rounded,
color: Colors.white, size: 16),
],
),
),
),
const SizedBox(height: 12),
GestureDetector(
onTap: _showVolunteerPostSheet,
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
borderRadius: BorderRadius.circular(16)),
child: const Row(
children: [
Text('🤝', style: TextStyle(fontSize: 24)),
SizedBox(width: 12),
Expanded(
child: Text('ボランティア募集を投稿する',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: Colors.white)),
),
Icon(Icons.arrow_forward_ios_rounded,
color: Colors.white, size: 16),
],
),
),
),
const SizedBox(height: 24),
  GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LostPetPage())),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF3498DB),
          borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Text('🔍', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Text('迷子情報を見る・投稿する',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 16),
        ],
      ),
    ),
  ),

const Text('投稿した里親募集',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Color(0xFF3D2B1F))),
const SizedBox(height: 12),
SizedBox(
height: 160,
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('adoptions')
.where('orgId',
isEqualTo: FirebaseAuth.instance.currentUser?.uid)
.orderBy('createdAt', descending: true)
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(
color: Color(0xFFE8845A)));
}
final docs = snapshot.data!.docs;
if (docs.isEmpty) {
return const Center(
child: Text('まだ投稿がありません🐾',
style: TextStyle(color: Colors.grey)),
);
}
return ListView.builder(
  itemCount: docs.length,
  itemBuilder: (_, i) {
    final data = docs[i].data() as Map<String, dynamic>;
    final docId = docs[i].id;
    final isAdopted = data['status'] == 'adopted';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: data['imageUrl'] != null &&
                    (data['imageUrl'] as String).isNotEmpty
                    ? Image.network(data['imageUrl'],
                    width: 56, height: 56, fit: BoxFit.cover)
                    : Container(
                  width: 56,
                  height: 56,
                  color: Colors.orange[50],
                  child: const Center(child: Text('🐾')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(data['petName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (isAdopted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(6)),
                            child: const Text('里親決定', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Text(data['type'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('adoptions')
                    .doc(docId)
                    .update({'status': isAdopted ? 'available' : 'adopted'});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isAdopted ? Colors.grey[700] : const Color(0xFF2D6A4F),
                side: BorderSide(color: isAdopted ? Colors.grey[400]! : const Color(0xFF2D6A4F)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(isAdopted ? '募集中に戻す' : '里親が決まりました', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  },
);

},
),
),
  const SizedBox(height: 20),
  const Text('投稿したボランティア募集',
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D2B1F))),
  const SizedBox(height: 12),
  Expanded(
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteers')
          .where('orgId',
          isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFE8845A)));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('まだ投稿がありません🤝',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            final isClosed = data['status'] == 'closed';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: data['imageUrl'] != null &&
                            (data['imageUrl'] as String).isNotEmpty
                            ? Image.network(data['imageUrl'],
                            width: 56, height: 56, fit: BoxFit.cover)
                            : Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          child: const Center(child: Text('🤝')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(data['title'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                if (isClosed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('締切', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            Text(data['location'] ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('volunteers')
                            .doc(docId)
                            .update({'status': isClosed ? 'open' : 'closed'});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isClosed ? const Color(0xFF2D6A4F) : Colors.grey[700],
                        side: BorderSide(color: isClosed ? const Color(0xFF2D6A4F) : Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(isClosed ? '募集を再開する' : '募集を締め切る', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );

      },
    ),
  ),
],
),
),
);
}
}
class _AdoptionPostSheet extends StatefulWidget {
  final String orgId;
  final String orgName;
  final VoidCallback onPosted;

  const _AdoptionPostSheet({
    required this.orgId,
    required this.orgName,
    required this.onPosted,
  });

  @override
  State<_AdoptionPostSheet> createState() => _AdoptionPostSheetState();
}

class _AdoptionPostSheetState extends State<_AdoptionPostSheet> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isPosting = false;
  final _petNameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'オス';
  final _personalityCtrl = TextEditingController();
  final _backgroundCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _submit() async {
    if (_imageUrl == null ||
        _petNameCtrl.text.trim().isEmpty ||
        _typeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真・名前・種類は必須です')),
      );
      return;
    }

    setState(() => _isPosting = true);

    await FirebaseFirestore.instance.collection('adoptions').add({
      'orgId': widget.orgId,
      'orgName': widget.orgName,
      'petName': _petNameCtrl.text.trim(),
      'type': _typeCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'gender': _gender,
      'personality': _personalityCtrl.text.trim(),
      'imageUrl': _imageUrl,
      'background': _backgroundCtrl.text.trim(),
      'conditions': _conditionsCtrl.text.trim(),
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });

    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('里親募集を投稿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16)),
              child: _isUploading
                  ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8845A)))
                  : _imageUrl != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_imageUrl!,
                      width: double.infinity, fit: BoxFit.cover))
                  : const Center(
                  child: Text('📸 写真を選ぶ', style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _petNameCtrl,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: '名前 *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: '種類（犬・猫など） *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageCtrl,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: '年齢',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('性別', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['オス', 'メス', '不明'].map((g) {
              final sel = _gender == g;
              return GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(g,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _personalityCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '性格・特徴',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _backgroundCtrl,
            maxLines: 4,
            maxLength: 800,
            decoration: InputDecoration(
              labelText: '保護に至った経緯',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditionsCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '希望する里親の条件',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('投稿する', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
class _VolunteerPostSheet extends StatefulWidget {
  final String orgId;
  final String orgName;
  final VoidCallback onPosted;

  const _VolunteerPostSheet({
    required this.orgId,
    required this.orgName,
    required this.onPosted,
  });

  @override
  State<_VolunteerPostSheet> createState() => _VolunteerPostSheetState();
}

class _VolunteerPostSheetState extends State<_VolunteerPostSheet> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isPosting = false;
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedArea;


  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルは必須です')),
      );
      return;
    }

    setState(() => _isPosting = true);

    await FirebaseFirestore.instance.collection('volunteers').add({
      'orgId': widget.orgId,
      'orgName': widget.orgName,
      'title': _titleCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'area': _selectedArea ?? '',
      'schedule': _scheduleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'imageUrl': _imageUrl ?? '',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ボランティア募集を投稿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: _isUploading
                  ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8845A)))
                  : _imageUrl != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_imageUrl!,
                      width: double.infinity, fit: BoxFit.cover))
                  : const Center(
                  child: Text('📸 写真を選ぶ（任意）', style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: 'タイトル *',
              hintText: '例：週末の保護犬お散歩ボランティア募集',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: '活動場所',
              hintText: '例：京都市内 保護施設',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('都道府県（どうぶつマップに表示されます）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefectures.map((pref) {
              final sel = _selectedArea == pref;
              return GestureDetector(
                onTap: () => setState(() => _selectedArea = pref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref,
                      style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _scheduleCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: '活動日時・頻度',
              hintText: '例：毎週土曜 10:00〜12:00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 5,
            maxLength: 800,
            decoration: InputDecoration(
              labelText: '活動内容',
              hintText: '具体的な活動内容や、参加条件などを書いてください',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('投稿する', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
class _EditOrgSheet extends StatefulWidget {
  final String orgId;
  final Map<String, dynamic> currentData;
  final VoidCallback onSaved;

  const _EditOrgSheet({
    required this.orgId,
    required this.currentData,
    required this.onSaved,
  });

  @override
  State<_EditOrgSheet> createState() => _EditOrgSheetState();
}

class _EditOrgSheetState extends State<_EditOrgSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _activityCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _websiteCtrl;
  String? _selectedArea;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentData['name'] ?? '');
    _activityCtrl = TextEditingController(text: widget.currentData['activityDescription'] ?? '');
    _contactCtrl = TextEditingController(text: widget.currentData['contactInfo'] ?? '');
    _websiteCtrl = TextEditingController(text: widget.currentData['websiteUrl'] ?? '');
    _selectedArea = widget.currentData['area'] ?? '';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'contactInfo': _contactCtrl.text.trim(),
      'websiteUrl': _websiteCtrl.text.trim(),
      'area': _selectedArea ?? '',
    };

    final nameChanged = _nameCtrl.text.trim() != (widget.currentData['name'] ?? '');
    final activityChanged = _activityCtrl.text.trim() != (widget.currentData['activityDescription'] ?? '');

    if (nameChanged) {
      updates['nameUpdatePending'] = _nameCtrl.text.trim();
    }
    if (activityChanged) {
      updates['activityUpdatePending'] = _activityCtrl.text.trim();
    }

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(widget.orgId)
        .update(updates);

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('団体情報を編集',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
            child: const Text(
                '団体名・活動内容は、変更後すぐには反映されません。運営が確認してから反映されます。連絡先・サイト・都道府県は、すぐに反映されます。',
                style: TextStyle(fontSize: 11, color: Colors.orange)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: '団体名 または お名前',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _activityCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '活動内容・実績',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactCtrl,
            decoration: InputDecoration(
              labelText: '連絡先（電話番号など）',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _websiteCtrl,
            decoration: InputDecoration(
              labelText: '公式サイト・SNS',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('都道府県', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefectures.map((pref) {
              final sel = _selectedArea == pref;
              return GestureDetector(
                onTap: () => setState(() => _selectedArea = pref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref,
                      style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('保存する', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
