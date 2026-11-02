import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/activity_log.dart';
import '../widgets/motion.dart';

// 運営の画面：「続けて使ってくれている人」の割合（1日後・7日後・30日後）
// activity/{uid} の「アプリを開いた日」から計算する
class RetentionView extends StatefulWidget {
  const RetentionView({super.key});

  @override
  State<RetentionView> createState() => _RetentionViewState();
}

class _Row {
  final String label;
  final String hint;
  final int eligible;
  final int returned;
  const _Row(this.label, this.hint, this.eligible, this.returned);
  double get rate => eligible == 0 ? 0 : returned / eligible;
}

class _RetentionViewState extends State<RetentionView> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  static DateTime? _parse(String? s) {
    if (s == null || s.length != 10) return null;
    return DateTime.tryParse(s);
  }

  Future<Map<String, dynamic>> _load() async {
    final snap = await FirebaseFirestore.instance.collection('activity').get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // [ラベル, 説明, 何日目から, 何日目まで]
    const windows = [
      ('1日後', '始めた次の日に、また開いた', 1, 1),
      ('7日後', '7〜13日目に、1回でも開いた', 7, 13),
      ('30日後', '30〜59日目に、1回でも開いた', 30, 59),
    ];
    final rows = <_Row>[];
    for (final w in windows) {
      var eligible = 0;
      var returned = 0;
      for (final d in snap.docs) {
        final first = _parse(d.data()['firstDay'] as String?);
        if (first == null) continue;
        // 期間がまるごと終わった人だけを数える
        if (today.difference(first).inDays <= w.$4) continue;
        eligible++;
        final days = List<String>.from(d.data()['days'] ?? const []);
        final hit = days.any((k) {
          final day = _parse(k);
          if (day == null) return false;
          final n = day.difference(first).inDays;
          return n >= w.$3 && n <= w.$4;
        });
        if (hit) returned++;
      }
      rows.add(_Row(w.$1, w.$2, eligible, returned));
    }
    final todayKey = ActivityLog.todayKey();
    final weekAgo = today.subtract(const Duration(days: 6));
    var todayCount = 0;
    var weekCount = 0;
    var newWeek = 0;
    for (final d in snap.docs) {
      final days = List<String>.from(d.data()['days'] ?? const []);
      if (days.contains(todayKey)) todayCount++;
      if (days.any((k) => !(_parse(k)?.isBefore(weekAgo) ?? true))) weekCount++;
      if (!(_parse(d.data()['firstDay'] as String?)?.isBefore(weekAgo) ?? true)) newWeek++;
    }
    return {
      'total': snap.docs.length,
      'today': todayCount,
      'week': weekCount,
      'newWeek': newWeek,
      'rows': rows,
    };
  }

  Widget _stat(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            CountUp(
                value: value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('読みこめませんでした（データを守るルールが新しくなっているか確かめてください）\n${snap.error}',
                textAlign: TextAlign.center),
          ));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final m = snap.data!;
        final rows = m['rows'] as List<_Row>;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                _stat('記録のある人', m['total'] as int),
                const SizedBox(width: 8),
                _stat('今日開いた人', m['today'] as int),
                const SizedBox(width: 8),
                _stat('7日間で開いた人', m['week'] as int),
              ]),
              const SizedBox(height: 8),
              Text('この7日間に始めた人：${m['newWeek']}人',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 20),
              const Text('続けて使ってくれている人の割合',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('期間が終わった人だけで計算します。人数が少ないうちは、ぶれが大きいです。',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 10),
              ...rows.asMap().entries.map((e) => FadeSlideIn(index: e.key, child: Builder(builder: (_) {
                final r = e.value;
                return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.label,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            r.eligible == 0
                                ? const Text('まだ計算できません',
                                    style: TextStyle(fontSize: 13, color: Colors.grey))
                                : CountUp(
                                    value: (r.rate * 100).round(),
                                    suffix: '%',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE8845A))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: r.rate),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF3E8E1),
                              color: const Color(0xFFE8845A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${r.hint}（${r.returned}人 / ${r.eligible}人）',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  );
              }))),
              const SizedBox(height: 8),
              Text('記録しているのは「アプリを開いた日」だけです（プライバシーポリシーに書いてあります）。',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        );
      },
    );
  }
}
