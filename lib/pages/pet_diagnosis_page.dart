import 'package:flutter/material.dart';

const _questions = [
  {
    'question': 'あなたの生活スタイルは？',
    'options': [
      {'text': 'アクティブ！毎日外出する', 'type': 'dog'},
      {'text': 'インドア派。家でのんびり', 'type': 'cat'},
      {'text': 'ほどほど。週末は外に出る', 'type': 'rabbit'},
      {'text': '不規則。仕事が忙しい', 'type': 'hamster'},
    ],
  },
  {
    'question': '住環境は？',
    'options': [
      {'text': '広い家・庭あり', 'type': 'dog'},
      {'text': '一人暮らし・マンション', 'type': 'cat'},
      {'text': '家族と同居・普通の家', 'type': 'rabbit'},
      {'text': '狭めの部屋', 'type': 'hamster'},
    ],
  },
  {
    'question': 'ペットにどれくらい時間をかけられる？',
    'options': [
      {'text': '毎日たっぷり時間がある', 'type': 'dog'},
      {'text': 'あまり時間がない', 'type': 'cat'},
      {'text': '週末は時間がある', 'type': 'rabbit'},
      {'text': '忙しくて少ししかない', 'type': 'hamster'},
    ],
  },
  {
    'question': 'どんなペットとの関係が理想？',
    'options': [
      {'text': '一緒に遊んで運動したい', 'type': 'dog'},
      {'text': 'そばにいてくれるだけでいい', 'type': 'cat'},
      {'text': 'のんびり眺めて癒されたい', 'type': 'rabbit'},
      {'text': 'かわいい姿を観察したい', 'type': 'hamster'},
    ],
  },
  {
    'question': 'ペットの世話で一番大変でも大丈夫なのは？',
    'options': [
      {'text': '毎日の散歩・運動', 'type': 'dog'},
      {'text': 'トイレの掃除', 'type': 'cat'},
      {'text': '毎日の餌やり・掃除', 'type': 'rabbit'},
      {'text': 'ケージの掃除', 'type': 'hamster'},
    ],
  },
];

const _results = {
  'dog': {
    'title': '犬タイプ🐕',
    'desc': 'アクティブで一緒に楽しめる犬があなたにぴったり！\n毎日の散歩や運動を通じて深い絆が生まれます。',
    'emoji': '🐕',
    'traits': ['アクティブ', '社交的', '忠実', '遊び好き'],
    'advice': '柴犬・ゴールデンレトリバー・ラブラドールがおすすめ！',
  },
  'cat': {
    'title': '猫タイプ🐱',
    'desc': 'マイペースで自立した猫があなたにぴったり！\nそばにいるだけで癒される関係が築けます。',
    'emoji': '🐱',
    'traits': ['独立心', 'マイペース', '清潔好き', '賢い'],
    'advice': 'スコティッシュフォールド・ノルウェージャンがおすすめ！',
  },
  'rabbit': {
    'title': 'うさぎタイプ🐰',
    'desc': 'おっとりしたうさぎがあなたにぴったり！\nのんびり眺めるだけで癒される存在です。',
    'emoji': '🐰',
    'traits': ['穏やか', '癒し系', 'のんびり', 'かわいい'],
    'advice': 'ネザーランドドワーフ・ホーランドロップがおすすめ！',
  },
  'hamster': {
    'title': 'ハムスタータイプ🐹',
    'desc': 'かわいいハムスターがあなたにぴったり！\n忙しくても飼いやすく癒されます。',
    'emoji': '🐹',
    'traits': ['かわいい', '観察好き', '世話しやすい', '癒し系'],
    'advice': 'ジャンガリアン・ゴールデンハムスターがおすすめ！',
  },
};

class PetDiagnosisPage extends StatefulWidget {
  const PetDiagnosisPage({super.key});

  @override
  State<PetDiagnosisPage> createState() => _PetDiagnosisPageState();
}

class _PetDiagnosisPageState extends State<PetDiagnosisPage> {
  int _currentQuestion = 0;
  final Map<String, int> _scores = {'dog': 0, 'cat': 0, 'rabbit': 0, 'hamster': 0};
  bool _finished = false;
  String? _result;

  void _answer(String type) {
    setState(() {
      _scores[type] = (_scores[type] ?? 0) + 1;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _finished = true;
        _result = _scores.entries
            .reduce((a, b) => a.value >= b.value ? a : b).key;
      }
    });
  }

  void _reset() {
    setState(() {
      _currentQuestion = 0;
      _scores.updateAll((key, value) => 0);
      _finished = false;
      _result = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_finished && _result != null) {
      final result = _results[_result!]!;
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('ペット診断 🐾',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8845A), Color(0xFFFFCC80)]),
                    borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    Text(result['emoji'] as String,
                        style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),
                    Text(result['title'] as String,
                        style: const TextStyle(fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(result['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14,
                            color: Colors.white70, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('あなたの特徴',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (result['traits'] as List).map((trait) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8845A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(trait as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE8845A),
                                    fontWeight: FontWeight.bold)),
                          )).toList(),
                    ),
                    const Divider(height: 32),
                    const Text('おすすめの品種',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Text(result['advice'] as String,
                        style: TextStyle(fontSize: 14,
                            color: Colors.grey[600], height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('もう一度診断する',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final question = _questions[_currentQuestion];
    final options = question['options'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ペット診断 🐾',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(
                    Color(0xFFE8845A)),
              ),
            ),
            const SizedBox(height: 8),
            Text('${_currentQuestion + 1} / ${_questions.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 32),
            Text(question['question'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 32),
            ...options.map((option) => GestureDetector(
              onTap: () => _answer(option['type'] as String),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
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
                    Expanded(
                        child: Text(option['text'] as String,
                            style: const TextStyle(fontSize: 15,
                                color: Color(0xFF3D2B1F)))),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFE8845A)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
