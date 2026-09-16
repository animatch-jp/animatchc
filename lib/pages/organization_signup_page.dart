import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prefectures.dart';
import 'organization_pending_page.dart';


class OrganizationSignupPage extends StatefulWidget {
  const OrganizationSignupPage({super.key});

  @override
  State<OrganizationSignupPage> createState() =>
      _OrganizationSignupPageState();
}

class _OrganizationSignupPageState extends State<OrganizationSignupPage> {
  final _nameCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedArea;

Future<void> _confirmBeforeSubmit() async {
if (_nameCtrl.text.trim().isEmpty ||
_activityCtrl.text.trim().isEmpty ||
_contactCtrl.text.trim().isEmpty ||
_emailCtrl.text.trim().isEmpty ||
_passCtrl.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('必須項目を入力してください'),
backgroundColor: Colors.red,
),
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
backgroundColor: const Color(0xFFE8845A),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
child: const Text('申請する'),
),
],
),
);

if (confirm == true) {
_submit();
}
}



  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _activityCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('必須項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    UserCredential? userCredential;

    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = userCredential.user?.uid;

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'activityDescription': _activityCtrl.text.trim(),
        'contactInfo': _contactCtrl.text.trim(),
        'websiteUrl': _websiteCtrl.text.trim(),
        'area': _selectedArea ?? '',
        'email': _emailCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrganizationPendingPage()),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('団体・保護主 新規申請',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('申請内容を確認の上、運営が承認します',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '団体名 または お名前 *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _activityCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '活動内容・実績 *',
                hintText: '例：〇〇市で保護犬猫の保護活動を5年間実施',
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
            const SizedBox(height: 16),
            TextField(
              controller: _websiteCtrl,
              decoration: InputDecoration(
                labelText: '公式サイト・SNS（任意）',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('都道府県（どうぶつマップに表示されます） *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            const SizedBox(height: 24),
            const Divider(),

            const SizedBox(height: 24),
            const Text('ログイン用の情報',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                  icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
                  backgroundColor: const Color(0xFFE8845A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('申請する',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
