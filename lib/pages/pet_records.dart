import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/content_filter.dart';

// うちの子の記録帳（体重・ワクチン・薬・通院・メモ）
// 場所：users/{uid}/pets/{petId}/records/{id}（本人だけが読める・書ける）
// { kind, date, weight(kgの数・体重のときだけ), note, nextDate(次の予定日・なくてもよい), createdAt, updatedAt }
class PetRecords {
  static const kinds = <String, String>{
    'weight': '体重',
    'vaccine': 'ワクチン',
    'medicine': '薬',
    'hospital': '通院',
    'other': 'メモ',
  };
  static const emoji = <String, String>{
    'weight': '⚖️',
    'vaccine': '💉',
    'medicine': '💊',
    'hospital': '🏥',
    'other': '📝',
  };
  static const maxNote = 200;

  static CollectionReference<Map<String, dynamic>> col(String uid, String petId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pets')
          .doc(petId)
          .collection('records');

  static String dateLabel(DateTime d) => '${d.year}/${d.month}/${d.day}';

  static DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

  static String weightLabel(dynamic w) {
    if (w is! num) return '';
    final s = w.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '${s}kg';
  }

  // ペットを消すときに、中の記録（お世話・記録帳）もいっしょに消す
  static Future<void> deletePetWithData(DocumentReference petRef) async {
    final db = FirebaseFirestore.instance;
    final refs = <DocumentReference>[];
    final tasks = await petRef.collection('tasks').get();
    for (final t in tasks.docs) {
      final logs = await t.reference.collection('logs').get();
      refs.addAll(logs.docs.map((d) => d.reference));
      refs.add(t.reference);
    }
    final records = await petRef.collection('records').get();
    refs.addAll(records.docs.map((d) => d.reference));
    for (var i = 0; i < refs.length; i += 400) {
      final b = db.batch();
      for (final r in refs.skip(i).take(400)) {
        b.delete(r);
      }
      await b.commit();
    }
    await petRef.delete();
  }

  static Future<void> openSheet(BuildContext context,
      {required String uid,
      required String petId,
      String? docId,
      Map<String, dynamic>? initial}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PetRecordSheet(uid: uid, petId: petId, docId: docId, initial: initial),
      ),
    );
  }
}

class PetRecordSheet extends StatefulWidget {
  final String uid;
  final String petId;
  final String? docId;
  final Map<String, dynamic>? initial;
  const PetRecordSheet(
      {super.key, required this.uid, required this.petId, this.docId, this.initial});

  @override
  State<PetRecordSheet> createState() => _PetRecordSheetState();
}

class _PetRecordSheetState extends State<PetRecordSheet> {
  String _kind = 'weight';
  DateTime _date = DateTime.now();
  DateTime? _next;
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.docId != null;
  bool get _canHaveNext => _kind != 'weight';

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      final k = (d['kind'] ?? '').toString();
      if (PetRecords.kinds.containsKey(k)) _kind = k;
      _date = PetRecords.toDate(d['date']) ?? _date;
      _next = PetRecords.toDate(d['nextDate']);
      final w = d['weight'];
      if (w is num) _weightCtrl.text = PetRecords.weightLabel(w).replaceAll('kg', '');
      _noteCtrl.text = (d['note'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, {bool future = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 予定日は今日より前を選べないので、前の日付が入っていたら今日から選ぶ
    if (future && initial.isBefore(today)) initial = today;
    if (!future && initial.isAfter(now)) initial = now;
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: future ? DateTime(now.year, now.month, now.day) : DateTime(2000),
      lastDate: future ? DateTime(now.year + 3, 12, 31) : now,
    );
  }

  Future<void> _save() async {
    double? weight;
    if (_kind == 'weight') {
      weight = double.tryParse(
          _weightCtrl.text.trim().replaceAll('，', '.').replaceAll(',', '.').replaceAll('kg', ''));
      if (weight == null || weight <= 0 || weight > 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('体重を数字で入れてください（例：4.2）')));
        return;
      }
    }
    final note = _noteCtrl.text.trim();
    if (_kind != 'weight' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内容を書いてください（例：混合ワクチン、〇〇病院）')));
      return;
    }
    if (ContentFilter.blocked(context, [note], allowContact: true)) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'kind': _kind,
      'date': Timestamp.fromDate(DateTime(_date.year, _date.month, _date.day)),
      'note': note,
      'weight': weight ?? FieldValue.delete(),
      'nextDate': (_canHaveNext && _next != null)
          ? Timestamp.fromDate(DateTime(_next!.year, _next!.month, _next!.day))
          : FieldValue.delete(),
    };
    try {
      final col = PetRecords.col(widget.uid, widget.petId);
      if (_isEdit) {
        await col.doc(widget.docId).update({...body, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        body.removeWhere((_, v) => v is FieldValue); // 新しく作るときは、空の項目を入れない
        await col.add({...body, 'createdAt': FieldValue.serverTimestamp()});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('記録帳の保存エラー: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存できませんでした。もう一度ためしてください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isEdit ? '記録を直す' : '記録をつける',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('記録帳は、あなただけが見られます',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PetRecords.kinds.entries.map((e) {
              final sel = _kind == e.key;
              return ChoiceChip(
                label: Text('${PetRecords.emoji[e.key]} ${e.value}'),
                selected: sel,
                onSelected: (_) => setState(() => _kind = e.key),
                selectedColor: const Color(0xFFE8845A),
                labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFF3D2B1F)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded, color: Color(0xFFE8845A)),
            title: const Text('日付', style: TextStyle(fontSize: 13)),
            trailing: Text(PetRecords.dateLabel(_date),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () async {
              final d = await _pick(_date);
              if (d != null) setState(() => _date = d);
            },
          ),
          if (_kind == 'weight')
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '体重 *',
                suffixText: 'kg',
                hintText: '例：4.2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: PetRecords.maxNote,
            decoration: InputDecoration(
              labelText: _kind == 'weight' ? 'メモ（なくてもOK）' : '内容 *',
              hintText: switch (_kind) {
                'vaccine' => '例：混合ワクチン（5種）',
                'medicine' => '例：フィラリアの薬',
                'hospital' => '例：〇〇動物病院で健康診断',
                'other' => '例：初めてシャンプーした',
                _ => '例：ごはんを少し減らした',
              },
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_canHaveNext) ...[
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFF2D6A4F)),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('次の予定日（ホームでお知らせ）', style: TextStyle(fontSize: 13))),
                if (_next != null)
                  IconButton(
                    tooltip: '予定日を外す',
                    onPressed: () => setState(() => _next = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final init = _next ??
                        (_kind == 'vaccine'
                            ? DateTime(now.year + 1, now.month, now.day.clamp(1, 28))
                            : DateTime(now.year, now.month + 1, now.day.clamp(1, 28)));
                    final d = await _pick(init, future: true);
                    if (d != null) setState(() => _next = d);
                  },
                  child: Text(_next == null ? '決める' : PetRecords.dateLabel(_next!)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('保存する', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ペットのページに出す「記録帳」
class PetRecordSection extends StatelessWidget {
  final String uid;
  final String petId;
  const PetRecordSection({super.key, required this.uid, required this.petId});

  Future<void> _delete(BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('この記録を消しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('消す', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PetRecords.col(uid, petId).doc(docId).delete();
    } catch (e) {
      debugPrint('記録帳の削除エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8845A).withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8845A).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📒', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('記録帳',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB4642E))),
              ),
              GestureDetector(
                onTap: () => PetRecords.openSheet(context, uid: uid, petId: petId),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFE8845A)),
                    SizedBox(width: 4),
                    Text('記録する', style: TextStyle(fontSize: 12, color: Color(0xFFE8845A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('体重・ワクチン・薬・通院を残せます（あなただけが見られます）',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: PetRecords.col(uid, petId)
                .orderBy('date', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('記録帳の読みこみエラー: ${snap.error}');
                return Text('記録帳を読みこめませんでした',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]));
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Color(0xFFE8845A)))),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('まだ記録はありません。「記録する」から、まず体重を1つ入れてみましょう',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                );
              }
              final weights = docs
                  .where((d) => d.data()['kind'] == 'weight' && d.data()['weight'] is num)
                  .toList()
                  .reversed
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (weights.length >= 2) _WeightChart(points: weights.map((d) {
                    final x = d.data();
                    return MapEntry(PetRecords.toDate(x['date']) ?? DateTime.now(),
                        (x['weight'] as num).toDouble());
                  }).toList()),
                  ...docs.map((d) => _RecordRow(
                        data: d.data(),
                        onEdit: () => PetRecords.openSheet(context,
                            uid: uid, petId: petId, docId: d.id, initial: d.data()),
                        onDelete: () => _delete(context, d.id),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RecordRow({required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final kind = (data['kind'] ?? 'other').toString();
    final date = PetRecords.toDate(data['date']);
    final next = PetRecords.toDate(data['nextDate']);
    final note = (data['note'] ?? '').toString();
    final w = PetRecords.weightLabel(data['weight']);
    final main = kind == 'weight' ? w : note;
    final sub = kind == 'weight' ? note : '';
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(PetRecords.emoji[kind] ?? '📝', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${PetRecords.kinds[kind] ?? 'メモ'}・${date == null ? '' : PetRecords.dateLabel(date)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(main,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                  if (sub.isNotEmpty)
                    Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  if (next != null)
                    Text('次の予定：${PetRecords.dateLabel(next)}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
                ],
              ),
            ),
            IconButton(
              tooltip: '消す',
              onPressed: onDelete,
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// 体重の変わり方（かんたんな線のグラフ）
class _WeightChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> points;
  const _WeightChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final first = points.first;
    final last = points.last;
    final diff = last.value - first.value;
    final sign = diff > 0 ? '+' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '体重の変わり方（${PetRecords.dateLabel(first.key)}から $sign${diff.toStringAsFixed(1)}kg）',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(painter: _WeightPainter(points)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(PetRecords.weightLabel(first.value),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text(PetRecords.weightLabel(last.value),
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE8845A))),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> points;
  _WeightPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final t0 = points.first.key.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.key.millisecondsSinceEpoch.toDouble();
    final vs = points.map((p) => p.value);
    var lo = vs.reduce((a, b) => a < b ? a : b);
    var hi = vs.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 0.2) {
      hi += 0.1;
      lo -= 0.1;
    }
    Offset at(int i) {
      final p = points[i];
      final x = t1 == t0
          ? size.width * i / (points.length - 1)
          : size.width * (p.key.millisecondsSinceEpoch - t0) / (t1 - t0);
      final y = size.height - 6 - (size.height - 12) * (p.value - lo) / (hi - lo);
      return Offset(x, y);
    }

    final grid = Paint()
      ..color = const Color(0xFFEEE4DC)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), grid);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE8845A)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round);
    final dot = Paint()..color = const Color(0xFFE8845A);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(at(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightPainter old) => old.points != points;
}
