import 'package:flutter/material.dart';

const _reportReasons = [
  {'emoji': '🚨', 'title': '虐待・暴力目的の疑い', 'desc': '動物への虐待や暴力が疑われる'},
  {'emoji': '🍖', 'title': '食用目的の疑い', 'desc': '動物を食用にする目的が疑われる'},
  {'emoji': '💰', 'title': '詐欺・金銭目的', 'desc': '金銭を騙し取る目的が疑われる'},
  {'emoji': '🔞', 'title': '不適切なコンテンツ', 'desc': '不適切な画像や文章を投稿している'},
  {'emoji': '👤', 'title': 'なりすまし', 'desc': '他人のふりをしている'},
  {'emoji': '💬', 'title': 'ハラスメント', 'desc': '嫌がらせや脅迫をされた'},
  {'emoji': '🐾', 'title': 'その他', 'desc': '上記以外の問題がある'},
];

class ReportPage extends StatefulWidget {
  final String userName;

  const ReportPage({super.key, required this.userName});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? _selectedReason;
  final _detailCtrl = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🙏', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('通報を受け付けました',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('内容を確認し適切に対応します\nご報告ありがとうございました',
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
        title: Text('${widget.userName}を通報',
            style: const TextStyle(fontWeight: FontWeight.w900,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[200]!)),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        '通報内容は運営が確認します。\n虚偽の通報はアカウント停止になる場合があります。',
                        style: TextStyle(fontSize: 12,
                            color: Colors.red, height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('通報理由を選んでください',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ..._reportReasons.map((reason) {
              final selected = _selectedReason == reason['title'];
              return GestureDetector(
                onTap: () => setState(() =>
                _selectedReason = reason['title']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.red[50] : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? Colors.red : Colors.grey[300]!),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Text(reason['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reason['title'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.red : const Color(0xFF3D2B1F))),
                            Text(reason['desc'] as String,
                                style: TextStyle(fontSize: 12,
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.red),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('詳細（任意）',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '詳しい状況を教えてください',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason == null ? null : () {
                  setState(() => _submitted = true);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('通報する',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
