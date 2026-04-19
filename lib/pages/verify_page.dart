import 'package:flutter/material.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  int _step = 0;
  bool _isLoading = false;

  final _steps = [
    {'title': '本人確認', 'desc': '安心して使えるアプリのために\n本人確認をお願いします🐾', 'emoji': '🔐'},
    {'title': '身分証明書の提出', 'desc': '以下のいずれかを選んでください', 'emoji': '📄'},
    {'title': '審査中', 'desc': '身分証明書を確認しています\n通常1〜2営業日で完了します', 'emoji': '⏳'},
    {'title': '確認完了', 'desc': '本人確認が完了しました！\n認証バッジが付与されます✨', 'emoji': '✅'},
  ];

  final _idTypes = [
    {'name': '運転免許証', 'emoji': '🚗'},
    {'name': 'マイナンバーカード', 'emoji': '💳'},
    {'name': 'パスポート', 'emoji': '📗'},
    {'name': '健康保険証', 'emoji': '🏥'},
  ];

  void _next() async {
    if (_step == 1) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('本人確認 🔐',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (_step + 1) / _steps.length,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(
                    Color(0xFFE8845A)),
              ),
            ),
            const SizedBox(height: 8),
            Text('${_step + 1} / ${_steps.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 32),
            Text(current['emoji'] as String,
                style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(current['title'] as String,
                style: const TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            Text(current['desc'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15,
                    color: Colors.grey[600], height: 1.6)),
            const SizedBox(height: 32),
            if (_step == 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('本人確認を始める',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (_step == 1)
              ...(_idTypes.map((id) => GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Text(id['emoji'] as String,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Text(id['name'] as String,
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D2B1F))),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFE8845A)),
                    ],
                  ),
                ),
              ))),
            if (_step == 2) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8845A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE8845A).withOpacity(0.2))),
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE8845A)),
                    SizedBox(height: 16),
                    Text('審査中です...',
                        style: TextStyle(fontSize: 14,
                            color: Color(0xFFE8845A),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('確認完了（テスト用）',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            if (_step == 3) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF2D6A4F).withOpacity(0.2))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF2D6A4F), size: 32),
                    SizedBox(width: 12),
                    Text('認証済みバッジ取得！',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D6A4F))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('プロフィールに戻る',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
