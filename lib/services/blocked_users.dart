import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// 自分がブロックした人の一覧（blocks/自分/blocked）を、いつも新しい状態で持っておく。
// 一覧やランキングで、ブロックした人の投稿を外すために使う。
class BlockedUsers {
  BlockedUsers._();
  static final BlockedUsers instance = BlockedUsers._();

  final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});
  StreamSubscription? _sub;
  String? _forUid;

  // 使う前に呼ぶ（何回呼んでもよい）。ログインしている人が変わったら、読み直す。
  void ensureListening() {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == _forUid) return;
    _sub?.cancel();
    _forUid = me;
    ids.value = <String>{};
    if (me == null) return;
    _sub = FirebaseFirestore.instance
        .collection('blocks')
        .doc(me)
        .collection('blocked')
        .snapshots()
        .listen((s) => ids.value = s.docs.map((d) => d.id).toSet(),
            onError: (_) {});
  }

  bool isBlocked(dynamic uid) {
    ensureListening();
    return uid is String && ids.value.contains(uid);
  }
}
