import 'package:cloud_firestore/cloud_firestore.dart';

/// イベントを消すときは、中にある参加者・メッセージ・キャンセルの記録もいっしょに消す。
/// （イベントだけ消すと、中身がデータベースに残り続けるため）
class EventCleanup {
  static Future<void> _deleteAll(CollectionReference<Map<String, dynamic>> col) async {
    while (true) {
      final snap = await col.limit(300).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 300) return;
    }
  }

  /// 中身を消してから、イベント本体を消す。中身の一部が消せなくても、本体は消す
  static Future<void> deleteEvent(DocumentReference<Map<String, dynamic>> eventRef) async {
    for (final name in ['messages', 'participants', 'cancellations']) {
      try {
        await _deleteAll(eventRef.collection(name));
      } catch (_) {}
    }
    await eventRef.delete();
  }
}
