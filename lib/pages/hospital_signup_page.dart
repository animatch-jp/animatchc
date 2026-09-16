import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prefectures.dart';
import 'hospital_tags.dart';
import 'hospital_pending_page.dart';
import '../services/cloudinary_service.dart';

class HospitalSignupPage extends StatefulWidget {
  const HospitalSignupPage({super.key});

  @override
  State<HospitalSignupPage> createState() => _HospitalSignupPageState();
}

class _HospitalSignupPageState extends State<HospitalSignupPage> {
final _nameCtrl = TextEditingController();
final _addressCtrl = TextEditingController();
final _hoursCtrl = TextEditingController();
final _contactCtrl = TextEditingController();
final _emailCtrl = TextEditingController();
final _passCtrl = TextEditingController();
bool _isLoading = false;
bool _obscurePassword = true;
String? _selectedArea;
List<String> _selectedAnimals = [];
bool _acceptingNew = false;
bool _hasInpatient = false;
bool _hasCT = false;
bool _hasMRI = false;
bool _hasNightCare = false;
String? _imageUrl;
bool _isUploadingImage = false;

Future<void> _pickImage() async {
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
}


Future<void> _confirmBeforeSubmit() async {
if (_nameCtrl.text.trim().isEmpty ||
_addressCtrl.text.trim().isEmpty ||
_contactCtrl.text.trim().isEmpty ||
_emailCtrl.text.trim().isEmpty ||
_passCtrl.text.trim().isEmpty ||
_selectedArea == null ||
_selectedAnimals.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('必須項目を入力してください'), backgroundColor: Colors.red),
);
return;
}

final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('この内容で申請しますか？'),
content: const Text('入力内容は後から自分で変更できません。運営の審査後、修正が必要な場合はお問い合わせください。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4DA8DA),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
child: const Text('申請する'),
),
],
),
);

if (confirm == true) {
await _submit();
}
}
Future<void> _submit() async {
  setState(() => _isLoading = true);
  UserCredential? userCredential;
  try {
    userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    final uid = userCredential.user?.uid;

    await FirebaseFirestore.instance.collection('hospitals').doc(uid).set({
      'name': _nameCtrl.text.trim(),
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
      'isPaused': false,
      'imageUrl': _imageUrl ?? '',
      'email': _emailCtrl.text.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HospitalPendingPage()),
            (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    String message = '申請に失敗しました';
    if (e.code == 'email-already-in-use') message = 'このメールアドレスは既に使われています';
    if (e.code == 'weak-password') message = 'パスワードは6文字以上にしてください';
    if (e.code == 'invalid-email') message = 'メールアドレスの形式が正しくありません';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    if (userCredential?.user != null) {
      try {
        await userCredential!.user!.delete();
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('申請の保存に失敗しました。もう一度お試しください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
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
  return Scaffold(
    backgroundColor: const Color(0xFFF0F8FC),
    appBar: AppBar(
      title: const Text('病院・獣医師の方はこちら', style: TextStyle(fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFF0F8FC),
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('申請内容を確認の上、運営が承認します', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  image: (_imageUrl != null)
                      ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: _isUploadingImage
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA)))
                    : (_imageUrl == null
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 28),
                      SizedBox(height: 6),
                      Text('病院の外観写真（任意）', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
                    : null),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('写真があると、審査がスムーズに進みます', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: '病院名 *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: '住所（番地まで） *',
              hintText: '例：京都市左京区〇〇町1-2-3',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hoursCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '診療時間・休診日',
              hintText: '例：平日 9:00〜18:00　木曜休診',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactCtrl,
            decoration: InputDecoration(
              labelText: '連絡先（電話番号など） *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text('都道府県 *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                      color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('対応動物（得意分野） *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                      color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('診療体制', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('ログイン用の情報', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'メールアドレス *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'パスワード（6文字以上） *',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmBeforeSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DA8DA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('申請する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ),
  );
}
}
