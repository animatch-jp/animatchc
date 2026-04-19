import 'package:flutter/material.dart';
import 'login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  int _step = 0;
  String _selectedReason = '';
  bool _confirmed = false;

  final _reasons = [
    '使わなくなった',
    '別のアプリを使う',
    'パートナーが見つかった🎉',
    'プライバシーが心配',
    '不具合が多い',
    'その他',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('アカウント削除',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 0
            ? _buildStep1()
            : _step == 1
            ? _buildStep2()
            : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アカウントを削除しますか？',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[300]!)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ 削除前にご確認ください',
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              SizedBox(height: 8),
              Text('・削除後30日以内なら復活できます\n・30日後に完全削除されます\n・マッチング・チャット履歴が消えます\n・プレミアムは自動解約されません',
                  style: TextStyle(fontSize: 13,
                      color: Colors.orange, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('削除する理由を教えてください',
            style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 12),
        ..._reasons.map((reason) {
          final sel = _selectedReason == reason;
          return GestureDetector(
            onTap: () => setState(() => _selectedReason = reason),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: sel ? Colors.red[50] : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? Colors.red : Colors.grey[300]!)),
              child: Row(
                children: [
                  Expanded(
                      child: Text(reason,
                          style: TextStyle(fontSize: 14,
                              color: sel ? Colors.red : const Color(0xFF3D2B1F)))),
                  if (sel)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.red, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedReason.isEmpty
                ? null
                : () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('次へ',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本当に削除しますか？',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red[300]!)),
          child: Column(
            children: [
              const Text('🥹', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('寂しいです...',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const SizedBox(height: 8),
              Text('動物たちのために\n一緒に頑張りましょう🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13,
                      color: Colors.grey[600], height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _confirmed = !_confirmed),
          child: Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                    color: _confirmed ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _confirmed ? Colors.red : Colors.grey[400]!)),
                child: _confirmed
                    ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('削除することを理解しました',
                    style: TextStyle(fontSize: 14,
                        color: Color(0xFF3D2B1F))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmed
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('削除する',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE8845A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('やっぱりやめる',
                style: TextStyle(fontSize: 16,
                    color: Color(0xFFE8845A),
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text('🐾', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 20),
        const Text('削除申請を受け付けました',
            style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
              '30日以内であれば\nアカウントを復活できます\n\n30日後に完全削除されます',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14,
                  color: Colors.grey[600], height: 1.7)),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('ログアウトする',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
