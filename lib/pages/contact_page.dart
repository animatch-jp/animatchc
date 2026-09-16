import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _categoryCtrl = ValueNotifier<String>('利用方法について');
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _submitted = false;
  bool _isSending = false;

  final _categories = [
    '利用方法について',
    'アカウントについて',
    '不具合・バグ報告',
    '通報・違反報告',
    '動物病院情報について',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _contentCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('contacts').add({
        'uid': uid ?? '',
        'category': _categoryCtrl.value,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': '未対応',
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('送信に失敗しました。もう一度お試しください'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('お問い合わせ',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🙏', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('お問い合わせを受け付けました',
                  style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('内容を確認後、3〜5営業日以内にご返信します',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14,
                        color: Colors.grey[600], height: 1.6)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14)),
                child: const Text('戻る',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('お問い合わせ',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('お問い合わせ📩',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 6),
                  Text('お気軽にご連絡ください\n3〜5営業日以内にご返信します',
                      style: TextStyle(fontSize: 13,
                          color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('カテゴリ',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: _categoryCtrl,
              builder: (_, selected, __) => Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final isSel = selected == cat;
                  return GestureDetector(
                    onTap: () => _categoryCtrl.value = cat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFE8845A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSel
                                  ? const Color(0xFFE8845A)
                                  : Colors.grey[300]!)),
                      child: Text(cat,
                          style: TextStyle(fontSize: 12,
                              color: isSel ? Colors.white : Colors.grey[700],
                              fontWeight: isSel
                                  ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('件名',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '件名を入力してください',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFE8845A))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('内容',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'お問い合わせ内容を入力してください',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFE8845A))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleCtrl.text.isEmpty ||
                    _contentCtrl.text.isEmpty ||
                    _isSending
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('送信する',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
