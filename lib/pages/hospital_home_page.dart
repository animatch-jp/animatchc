import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prefectures.dart';
import 'hospital_tags.dart';
import 'login_page.dart';
import '../services/cloudinary_service.dart';
import 'notification_page.dart';


class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  State<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
Map<String, dynamic>? _data;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadData();
}

Future<void> _loadData() async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final doc = await FirebaseFirestore.instance.collection('hospitals').doc(uid).get();
if (mounted) {
setState(() {
_data = doc.data();
_isLoading = false;
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

Future<void> _togglePause(bool current) async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: Text(current ? '掲載を再開しますか？' : '一時的に非公開にしますか？'),
content: Text(current ? 'どうぶつマップに再び表示されます。' : '休診中などの場合、どうぶつマップから一時的に非表示にできます。いつでも再開できます。'),
actions: [
TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DA8DA), foregroundColor: Colors.white),
child: Text(current ? '再開する' : '非公開にする'),
),
],
),
);
if (confirm == true) {
await FirebaseFirestore.instance.collection('hospitals').doc(uid).update({'isPaused': !current});
_loadData();
}
}

Future<void> _pickImage() async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final url = await CloudinaryService.pickAndUploadImage();
if (url != null) {
await FirebaseFirestore.instance.collection('hospitals').doc(uid).update({'imageUrl': url});
_loadData();
}
}
void _showEditSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _EditHospitalSheet(
hospitalId: FirebaseAuth.instance.currentUser?.uid ?? '',
currentData: _data ?? {},
onSaved: () {
Navigator.pop(context);
_loadData();
},
),
),
);
}

Widget _infoChip(String label, bool value) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
decoration: BoxDecoration(
color: value ? const Color(0xFF4DA8DA).withOpacity(0.15) : Colors.grey[100],
borderRadius: BorderRadius.circular(10)),
child: Text(label,
style: TextStyle(fontSize: 11, color: value ? const Color(0xFF4DA8DA) : Colors.grey, fontWeight: value ? FontWeight.bold : FontWeight.normal)),
);
}
@override
Widget build(BuildContext context) {
if (_isLoading) {
return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA))));
}

final animalTags = List<String>.from(_data?['animalTags'] ?? []);
final isPaused = _data?['isPaused'] ?? false;

return Scaffold(
backgroundColor: const Color(0xFFF0F8FC),
appBar: AppBar(
title: const Text('病院マイページ 🏥', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
backgroundColor: const Color(0xFFF0F8FC),
elevation: 0,
automaticallyImplyLeading: false,
  actions: [
    IconButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => const NotificationPage())),
      icon: const Icon(Icons.notifications_outlined,
          color: Color(0xFF4DA8DA)),
    ),
    IconButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(

context: context,
builder: (_) => AlertDialog(
title: const Text('ログアウトしますか？'),
content: const Text('もう一度ログインが必要になります'),
actions: [
TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DA8DA), foregroundColor: Colors.white),
child: const Text('ログアウト'),
),
],
),
);
if (confirm == true) _logout();
},
icon: const Icon(Icons.logout_rounded, color: Color(0xFF4DA8DA)),
),
],
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (isPaused)
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
child: const Row(
children: [
Icon(Icons.visibility_off_rounded, color: Colors.orange, size: 18),
SizedBox(width: 8),
Expanded(child: Text('現在、一時非公開中です', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
],
),
),
GestureDetector(
onTap: _pickImage,
child: Container(
width: double.infinity,
height: 160,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
image: (_data?['imageUrl'] ?? '').toString().isNotEmpty
? DecorationImage(image: NetworkImage(_data!['imageUrl']), fit: BoxFit.cover)
: null,
),
child: (_data?['imageUrl'] ?? '').toString().isEmpty
? const Center(child: Text('📷 病院の写真を追加', style: TextStyle(color: Colors.grey)))
: null,
),
),
const SizedBox(height: 16),
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
gradient: const LinearGradient(colors: [Color(0xFF4DA8DA), Color(0xFF7FC4E8)]),
borderRadius: BorderRadius.circular(20),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(_data?['name'] ?? '',
style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
),
IconButton(
onPressed: _showEditSheet,
icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
),
],
),
if ((_data?['nameUpdatePending'] ?? '').toString().isNotEmpty)
Container(
margin: const EdgeInsets.only(top: 4),
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
child: const Text('病院名の変更を確認中です', style: TextStyle(fontSize: 10, color: Colors.white)),
),
const SizedBox(height: 8),
Text(_data?['area'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70)),
if ((_data?['address'] ?? '').toString().isNotEmpty) ...[
const SizedBox(height: 4),
Row(
children: [
const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
const SizedBox(width: 4),
Expanded(child: Text(_data?['address'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70))),
],
),
],
if ((_data?['businessHours'] ?? '').toString().isNotEmpty) ...[
const SizedBox(height: 4),
Row(
children: [
const Icon(Icons.schedule_rounded, color: Colors.white70, size: 14),
const SizedBox(width: 4),
Expanded(child: Text(_data?['businessHours'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70))),
],
),
],
],
),
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () => _togglePause(isPaused),
icon: Icon(isPaused ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
label: Text(isPaused ? '掲載を再開する' : '一時的に非公開にする'),
style: OutlinedButton.styleFrom(
foregroundColor: isPaused ? const Color(0xFF2D6A4F) : Colors.orange,
side: BorderSide(color: isPaused ? const Color(0xFF2D6A4F) : Colors.orange),
),
),
),
const SizedBox(height: 20),
const Text('対応動物', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
const SizedBox(height: 8),
Wrap(
spacing: 8,
runSpacing: 8,
children: animalTags.map((t) => _infoChip(t, true)).toList(),
),
  const SizedBox(height: 20),
  const Text('診療体制', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _infoChip('新規受付中', _data?['acceptingNew'] ?? false),
      _infoChip('入院施設あり', _data?['hasInpatient'] ?? false),
      _infoChip('CT設備あり', _data?['hasCT'] ?? false),
      _infoChip('MRI設備あり', _data?['hasMRI'] ?? false),
      _infoChip('夜間・救急対応', _data?['hasNightCare'] ?? false),
    ],
  ),
  const SizedBox(height: 24),
  const Text('みんなの一言', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
  const SizedBox(height: 8),
  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('hospitals')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('tagVotes')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator(color: Color(0xFF4DA8DA));
      final counts = <String, int>{};
      for (final doc in snapshot.data!.docs) {
        final tags = List<String>.from((doc.data() as Map<String, dynamic>)['commentTags'] ?? []);
        for (final t in tags) {
          counts[t] = (counts[t] ?? 0) + 1;
        }
      }
      if (counts.isEmpty) {
        return Text('まだタグが付いていません', style: TextStyle(color: Colors.grey[500], fontSize: 13));
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: counts.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
          child: Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12, color: Color(0xFF3D2B1F))),
        )).toList(),
      );
    },
  ),
  const SizedBox(height: 10),
  GestureDetector(
    onTap: () async {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('タグについて報告しますか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('気になる理由を選んでください'),
              const SizedBox(height: 12),
              ...['実際とは違う内容のタグが付いている', 'いたずら・嫌がらせと思われる投稿', 'その他'].map((r) =>
                  ListTile(
                    title: Text(r),
                    onTap: () => Navigator.pop(context, r),
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

      if (reason == null) return;

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'hospitalTags',
        'reporterId': myUid,
        'targetId': myUid,
        'targetUid': '',
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('報告しました。運営で確認します。'),
            backgroundColor: Color(0xFF4DA8DA),
          ),
        );
      }
    },
    child: const Row(
      children: [
        Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text('気になるタグがあれば報告する', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    ),
  ),

],

),
),
);
}
}
class _EditHospitalSheet extends StatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> currentData;
  final VoidCallback onSaved;

  const _EditHospitalSheet({
    required this.hospitalId,
    required this.currentData,
    required this.onSaved,
  });

  @override
  State<_EditHospitalSheet> createState() => _EditHospitalSheetState();
}

class _EditHospitalSheetState extends State<_EditHospitalSheet> {
late TextEditingController _nameCtrl;
late TextEditingController _addressCtrl;
late TextEditingController _hoursCtrl;
late TextEditingController _contactCtrl;
String? _selectedArea;
late List<String> _selectedAnimals;
late bool _acceptingNew;
late bool _hasInpatient;
late bool _hasCT;
late bool _hasMRI;
late bool _hasNightCare;
bool _isSaving = false;

@override
void initState() {
super.initState();
_nameCtrl = TextEditingController(text: widget.currentData['name'] ?? '');
_addressCtrl = TextEditingController(text: widget.currentData['address'] ?? '');
_hoursCtrl = TextEditingController(text: widget.currentData['businessHours'] ?? '');
_contactCtrl = TextEditingController(text: widget.currentData['contactInfo'] ?? '');
_selectedArea = widget.currentData['area'] ?? '';
_selectedAnimals = List<String>.from(widget.currentData['animalTags'] ?? []);
_acceptingNew = widget.currentData['acceptingNew'] ?? false;
_hasInpatient = widget.currentData['hasInpatient'] ?? false;
_hasCT = widget.currentData['hasCT'] ?? false;
_hasMRI = widget.currentData['hasMRI'] ?? false;
_hasNightCare = widget.currentData['hasNightCare'] ?? false;
}
Future<void> _save() async {
  setState(() => _isSaving = true);
  try {
    final updates = <String, dynamic>{
      'address': _addressCtrl.text.trim(),
      'businessHours': _hoursCtrl.text.trim(),
      'contactInfo': _contactCtrl.text.trim(),
      'area': _selectedArea ?? '',
      'animalTags': _selectedAnimals,
      'acceptingNew': _acceptingNew,
      'hasInpatient': _hasInpatient,
      'hasCT': _hasCT,
      'hasMRI': _hasMRI,
      'hasNightCare': _hasNightCare,
    };

    final nameChanged = _nameCtrl.text.trim() != (widget.currentData['name'] ?? '');
    if (nameChanged) {
      updates['nameUpdatePending'] = _nameCtrl.text.trim();
    }

    await FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).update(updates);

    widget.onSaved();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存に失敗しました。もう一度お試しください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4DA8DA)),
],
),
);
}
@override
Widget build(BuildContext context) {
return SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
const Text('病院情報を編集', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
child: const Text('病院名は、変更後すぐには反映されません。運営が確認してから反映されます。それ以外の項目は、すぐに反映されます。',
style: TextStyle(fontSize: 11, color: Colors.orange)),
),
const SizedBox(height: 16),
TextField(
controller: _nameCtrl,
decoration: InputDecoration(labelText: '病院名', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
),
const SizedBox(height: 12),
TextField(
controller: _addressCtrl,
decoration: InputDecoration(labelText: '住所（番地まで）', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
),
const SizedBox(height: 12),
TextField(
controller: _hoursCtrl,
maxLines: 2,
decoration: InputDecoration(labelText: '診療時間・休診日', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
),
const SizedBox(height: 12),
TextField(
controller: _contactCtrl,
decoration: InputDecoration(labelText: '連絡先', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
child: Text(pref, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
),
);
}).toList(),
),
  const SizedBox(height: 16),
  const Text('対応動物', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: hospitalAnimalTags.map((tag) {
      final sel = _selectedAnimals.contains(tag);
      return GestureDetector(
        onTap: () => setState(() {
          if (sel) {
            _selectedAnimals.remove(tag);
          } else {
            _selectedAnimals.add(tag);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
          child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 16),
  const Text('診療体制', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
    child: Column(
      children: [
        _toggleRow('新規患者 受付中', _acceptingNew, (v) => setState(() => _acceptingNew = v)),
        _toggleRow('入院施設あり', _hasInpatient, (v) => setState(() => _hasInpatient = v)),
        _toggleRow('CT設備あり', _hasCT, (v) => setState(() => _hasCT = v)),
        _toggleRow('MRI設備あり', _hasMRI, (v) => setState(() => _hasMRI = v)),
        _toggleRow('夜間・救急対応あり', _hasNightCare, (v) => setState(() => _hasNightCare = v)),
      ],
    ),
  ),
  const SizedBox(height: 20),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DA8DA),
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
