import 'package:flutter/material.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isYearly = false;

  final _features = [
    {'emoji': '❤️', 'label': 'いいね無制限', 'free': '1日30回', 'premium': '無制限'},
    {'emoji': '👀', 'label': '誰がいいねしたか', 'free': '❌', 'premium': '✅'},
    {'emoji': '✅', 'label': '既読機能', 'free': '❌', 'premium': '✅'},
    {'emoji': '⭐', 'label': 'お気に入り', 'free': '10件まで', 'premium': '無制限'},
    {'emoji': '🌟', 'label': 'スーパーいいね', 'free': '❌', 'premium': '1日1回'},
    {'emoji': '🎨', 'label': '限定スタンプ', 'free': '❌', 'premium': '✅'},
    {'emoji': '👆', 'label': 'プロフィール上位表示', 'free': '❌', 'premium': '✅'},
    {'emoji': '🔍', 'label': '足あと（誰が見たか）', 'free': '誰かが見たのみ', 'premium': '誰が見たかわかる'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('プレミアムプラン 👑',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            // ヘッダー
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8845A), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Text('👑', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('AniMatch プレミアム',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 8),
                const Text('動物好き同士のマッチングを\nもっと充実させよう',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 月額・年額切り替え
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearly = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: !_isYearly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text('月額プラン',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !_isYearly
                                  ? const Color(0xFFE8845A) : Colors.grey)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearly = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: _isYearly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('年額プラン',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isYearly
                                      ? const Color(0xFFE8845A) : Colors.grey)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('お得',
                                style: TextStyle(fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 価格表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFE8845A), width: 2)),
            child: Column(
              children: [
                Text(_isYearly ? '年額' : '月額',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(_isYearly ? '¥4,800' : '¥500',
                    style: const TextStyle(fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE8845A))),
                if (_isYearly)
                  Text('月あたり¥400（2ヶ月分お得！）',
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 機能比較
          const Text('無料プランとの比較',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8845A).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20))),
                  child: const Row(
                    children: [
                      Expanded(flex: 3,
                          child: Text('機能',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F)))),
                      Expanded(flex: 2,
                          child: Text('無料',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey))),
                      Expanded(flex: 2,
                          child: Text('👑 プレミアム',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE8845A)))),
                    ],
                  ),
                ),
                ..._features.asMap().entries.map((entry) {
                  final i = entry.key;
                  final feature = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: i % 2 == 0
                            ? Colors.white : Colors.grey[50],
                        borderRadius: i == _features.length - 1
                            ? const BorderRadius.vertical(
                            bottom: Radius.circular(20))
                            : null),
                    child: Row(
                      children: [
                        Expanded(flex: 3,
                            child: Row(
                              children: [
                                Text(feature['emoji'] as String,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(feature['label'] as String,
                                        style: const TextStyle(fontSize: 12,
                                            color: Color(0xFF3D2B1F)))),
                              ],
                            )),
                        Expanded(flex: 2,
                            child: Text(feature['free'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11,
                                    color: Colors.grey[600]))),
                        Expanded(flex: 2,
                            child: Text(feature['premium'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11,
                                    color: Color(0xFFE8845A),
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
              const SizedBox(height: 24),
              // 登録ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('プレミアム登録はリリース後に使えます！👑'),
                        backgroundColor: Color(0xFFE8845A),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: Text(
                      _isYearly
                          ? '年額¥4,800で始める👑'
                          : '月額¥500で始める👑',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Text('いつでもキャンセル可能です',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }
}
