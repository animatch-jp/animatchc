import 'package:flutter/material.dart';

const _reviews = [
  {
    'name': 'さくら',
    'emoji': '🐶',
    'rating': 5,
    'comment': '動物への愛情が伝わる素敵な方でした！一緒に散歩できて楽しかったです🐾',
    'time': '1日前',
    'tags': ['優しい', '動物好き', 'マナーが良い'],
  },
  {
    'name': 'ゆい',
    'emoji': '🐱',
    'rating': 4,
    'comment': 'ペットの話がとても盛り上がりました！また会いたいです✨',
    'time': '3日前',
    'tags': ['話しやすい', '知識豊富'],
  },
  {
    'name': 'けんた',
    'emoji': '🐕',
    'rating': 5,
    'comment': '保護活動に積極的で尊敬します！一緒にボランティアしたいです🌱',
    'time': '1週間前',
    'tags': ['積極的', '信頼できる', '動物好き'],
  },
];

class ReviewPage extends StatefulWidget {
  final String userName;
  const ReviewPage({super.key, required this.userName});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _myRating = 0;
  final _commentCtrl = TextEditingController();
  final _selectedTags = <String>[];
  bool _submitted = false;

  final _tags = ['優しい', '話しやすい', '動物好き', '知識豊富',
    '信頼できる', 'マナーが良い', '積極的', 'また会いたい'];

  double get _avgRating {
    final total = _reviews.fold<int>(0,
            (sum, r) => sum + (r['rating'] as int));
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: Text('${widget.userName}さんのレビュー',
              style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 評価サマリー
              Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(_avgRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      Row(
                        children: List.generate(5, (i) => Icon(
                            i < _avgRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.white, size: 20)),
                      ),
                      const SizedBox(height: 4),
                      Text('${_reviews.length}件のレビュー',
                          style: const TextStyle(fontSize: 13,
                              color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // レビュー一覧
            const Text('レビュー一覧',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ..._reviews.map((review) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
    color: const Color(0xFFE8845A).withOpacity(0.1),
    shape: BoxShape.circle),
    child: Center(
    child: Text(review['emoji'] as String,
    style: const TextStyle(fontSize: 20))),
    ),
    const SizedBox(width: 10),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(review['name'] as String,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    Row(
    children: [
    ...List.generate(5, (i) => Icon(
    i < (review['rating'] as int)
    ? Icons.star_rounded
        : Icons.star_outline_rounded,
    color: Colors.amber, size: 14)),
    const SizedBox(width: 4),
    Text(review['time'] as String,
    style: TextStyle(fontSize: 11,
    color: Colors.grey[500])),
    ],
    ),
    ],
    ),
    ),
    ],
    ),
    const SizedBox(height: 10),
    Text(review['comment'] as String,
    style: TextStyle(fontSize: 13,
    color: Colors.grey[700], height: 1.5)),
    const SizedBox(height: 8),
    Wrap(
    spacing: 6, runSpacing: 6,
    children: (review['tags'] as List<String>).map((tag) =>
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
    color: const Color(0xFFE8845A).withOpacity(0.1),
    borderRadius: BorderRadius.circular(12)),
    child: Text(tag,
    style: const TextStyle(fontSize: 11,
    color: Color(0xFFE8845A),
    fontWeight: FontWeight.bold)),
    )).toList(),
    ),
    ],
    ),
    )),
                const SizedBox(height: 20),
                // レビューを書く
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: _submitted
                      ? const Column(
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('レビューを送りました！',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('レビューを書く',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 16),
                      // 星評価
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => GestureDetector(
                          onTap: () => setState(() => _myRating = i + 1),
                          child: Icon(
                              i < _myRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber, size: 40),
                        )),
                      ),
                      const SizedBox(height: 16),
                      // タグ選択
                      const Text('タグを選ぶ',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _tags.map((tag) {
                          final sel = _selectedTags.contains(tag);
                          return GestureDetector(
                            onTap: () => setState(() => sel
                                ? _selectedTags.remove(tag)
                                : _selectedTags.add(tag)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFFE8845A) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(tag,
                                  style: TextStyle(fontSize: 12,
                                      color: sel
                                          ? Colors.white : Colors.grey[700])),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // コメント入力
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'コメントを入力してください',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8845A))),
                          filled: true,
                          fillColor: const Color(0xFFFFF8F5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _myRating == 0 ? null : () {
                            setState(() => _submitted = true);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8845A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('レビューを送る',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
        ),
    );
  }
}
