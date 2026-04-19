import 'package:flutter/material.dart';

const _questions = [
  {
    'question': 'ペットのしつけについてどう思いますか？',
    'options': [
      '厳しくしっかり教える',
      'やさしく根気よく教える',
      'ある程度自由にさせる',
      'しつけはあまり気にしない',
    ],
  },
  {
    'question': 'ペットとの距離感は？',
    'options': [
      '常に一緒にいたい',
      '適度な距離感が好き',
      '自立してほしい',
      '気が向いた時だけ関わる',
    ],
  },
  {
    'question': 'ペットが病気になった時は？',
    'options': [
      'すぐ病院に連れて行く',
      '様子を見てから病院へ',
      'できるだけ自然に任せる',
      'ペット保険に入って備える',
    ],
  },
  {
    'question': 'ペットと外出する頻度は？',
    'options': [
      '毎日連れて行きたい',
      '週に数回',
      '月に数回',
      'ほとんど家にいる',
    ],
  },
  {
    'question': 'ペットに対してお金をかける？',
    'options': [
      'できる限りかける',
      'バランスよくかける',
      '必要最低限でいい',
      'あまりかけたくない',
    ],
  },
];

class ValuesPage extends StatefulWidget {
  final Function(List<int>) onComplete;
  const ValuesPage({super.key, required this.onComplete});

  @override
  State<ValuesPage> createState() => _ValuesPageState();
}

class _ValuesPageState extends State<ValuesPage> {
  int _currentQuestion = 0;
  final List<int> _answers = [];

  void _onAnswer(int index) {
    setState(() {
      _answers.add(index);
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        widget.onComplete(_answers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('価値観診断 🐾',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('質問 ${_currentQuestion + 1} / ${_questions.length}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text('${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A598)),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8A598), Color(0xFFFFCC80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(q['question'] as String,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.5),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: (q['options'] as List).length,
                itemBuilder: (_, i) {
                  final option = (q['options'] as List)[i] as String;
                  return GestureDetector(
                    onTap: () => _onAnswer(i),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8A598).withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                ['A', 'B', 'C', 'D'][i],
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE8A598)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(option,
                                style: const TextStyle(
                                    fontSize: 15, height: 1.4)),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ValuesResultPage extends StatelessWidget {
  final List<int> answers;
  const ValuesResultPage({super.key, required this.answers});

  String get _resultType {
    final sum = answers.reduce((a, b) => a + b);
    if (sum <= 4) return 'しっかり派🏠';
    if (sum <= 8) return 'バランス派⚖️';
    if (sum <= 12) return 'のんびり派🌿';
    return '自由派🌈';
  }

  String get _resultDesc {
    switch (_resultType) {
      case 'しっかり派🏠':
        return 'ペットのことをしっかり管理したい責任感の強いタイプ。同じ価値観を持つ人と出会えると最高です！';
      case 'バランス派⚖️':
        return 'ペットとの関係をバランスよく保てるタイプ。幅広い人と相性が良いです！';
      case 'のんびり派🌿':
        return 'ペットと穏やかに過ごすことを大切にするタイプ。同じゆったりした価値観の人と合います！';
      default:
        return 'ペットに自由を与えることを大切にするタイプ。おおらかな人と相性抜群です！';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('診断結果 🎉',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8A598), Color(0xFFFFCC80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('あなたのタイプ',
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(_resultType,
                      style: const TextStyle(fontSize: 32,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(_resultDesc,
                      style: const TextStyle(fontSize: 14,
                          color: Colors.white, height: 1.6),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Text('✅ ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text('同じタイプの人と相性スコアが上がる',
                                  style: TextStyle(fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text('✅ ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text('価値観が合う人と出会いやすくなる',
                                  style: TextStyle(fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('あなたの回答',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...List.generate(answers.length, (i) {
                    final q = _questions[i];
                    final a = (q['options'] as List)[answers[i]] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(
                                color: Color(0xFFE8A598),
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(a,
                                style: TextStyle(fontSize: 13,
                                    color: Colors.grey[700])),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A598),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('プロフィールに戻る',
                    style: TextStyle(fontSize: 15,
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
