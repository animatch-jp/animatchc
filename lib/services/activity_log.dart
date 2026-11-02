import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

// 続けて使ってもらえているかを見るための記録（アプリを開いた日だけ。何を見たかは記録しない）
// 場所：activity/{uid} { firstDay: '2026-11-02', lastDay, days: ['2026-11-02', ...] }
// 読めるのは本人と運営。書けるのは本人だけ（データを守るルール）
class ActivityLog with WidgetsBindingObserver {
  ActivityLog._();
  static final ActivityLog instance = ActivityLog._();
  bool _observing = false;
  String? _savedFor; // 「uid と日付」。同じ日に何回も書かない

  static String todayKey([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void start() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    markToday();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) markToday();
  }

  Future<void> markToday() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final today = todayKey();
    final key = '$uid/$today';
    if (_savedFor == key) return;
    _savedFor = key;
    final ref = FirebaseFirestore.instance.collection('activity').doc(uid);
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({'firstDay': today, 'lastDay': today, 'days': [today]});
      } else if (snap.data()?['lastDay'] != today) {
        await ref.update({
          'lastDay': today,
          'days': FieldValue.arrayUnion([today]),
        });
      }
    } catch (e) {
      _savedFor = null;
      debugPrint('利用の記録エラー: $e');
    }
  }
}
