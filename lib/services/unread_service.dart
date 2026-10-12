import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// イベントのグループチャット1件ぶんの表示用データ
class GroupChatSummary {
  final String eventId;
  final String title;
  final String emoji;
  final String lastMessage;
  final DateTime? lastAt;
  final int unread;

  const GroupChatSummary({
    required this.eventId,
    required this.title,
    required this.emoji,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });
}

class _GroupMsg {
  final String text;
  final String senderUid;
  final bool isSystem;
  final DateTime? at;

  const _GroupMsg({
    required this.text,
    required this.senderUid,
    required this.isSystem,
    required this.at,
  });
}

/// 下タブ「チャット」のバッジと、チャット一覧の「グループ」タブに使う、
/// 未読数の共通部品。ログイン中のユーザーが変わると、自動で切り替わる。
///
/// 数えるもの:
///  ・団体とのチャットの未読（chats の unread[自分のuid]）
///  ・参加中イベントのグループチャットの未読
///    （自分が最後に開いた時刻より新しい、他の人のメッセージ。システム表示は数えない）
class UnreadService {
  UnreadService._();
  static final UnreadService instance = UnreadService._();

  /// 下タブのバッジに出す、未読の合計
  final ValueNotifier<int> totalUnread = ValueNotifier<int>(0);

  /// 参加中イベントのグループチャット一覧（新しい順）
  final ValueNotifier<List<GroupChatSummary>> groups =
  ValueNotifier<List<GroupChatSummary>>(<GroupChatSummary>[]);

  /// グループ一覧の最初の読み込みが終わったか
  final ValueNotifier<bool> groupsLoaded = ValueNotifier<bool>(false);

  bool _inited = false;
  String? _uid;
  int _epoch = 0; // ユーザーが切り替わるたびに増やす（古い結果を捨てるため）
  int _chatSeq = 0;
  Future<void>? _refreshing;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _seenSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _msgSubs = {};

  final Map<String, bool> _orgCache = {};
  final Map<String, Map<String, String>> _eventMeta = {};
  final Map<String, List<_GroupMsg>> _msgs = {};
  Map<String, DateTime> _lastSeen = {};

  int _orgUnread = 0;
  int _groupUnread = 0;

  /// 何度呼んでも大丈夫。最初に1回だけ動き出す。
  void init() {
    if (_inited) return;
    _inited = true;
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) _start(current.uid);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid == _uid) return;
      _stop();
      if (user != null) _start(user.uid);
    });
  }

  void _start(String uid) {
    _uid = uid;
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen(_onChats, onError: (_) {});
    _seenSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('groupChatLastSeen')
        .snapshots()
        .listen(_onSeen, onError: (_) {});
    refreshMembership();
  }

  void _stop() {
    _epoch++;
    _chatSeq++;
    _uid = null;
    _chatSub?.cancel();
    _chatSub = null;
    _seenSub?.cancel();
    _seenSub = null;
    for (final s in _msgSubs.values) {
      s.cancel();
    }
    _msgSubs.clear();
    _msgs.clear();
    _eventMeta.clear();
    _lastSeen = {};
    _orgUnread = 0;
    _groupUnread = 0;
    _refreshing = null;
    groups.value = <GroupChatSummary>[];
    groupsLoaded.value = false;
    totalUnread.value = 0;
  }

  void _publish() {
    totalUnread.value = _orgUnread + _groupUnread;
  }

  // ---------- 団体とのチャット ----------

  Future<bool> _isOrg(String uid) async {
    final cached = _orgCache[uid];
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(uid)
          .get();
      _orgCache[uid] = doc.exists;
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onChats(QuerySnapshot<Map<String, dynamic>> snap) async {
    final uid = _uid;
    if (uid == null) return;
    final epoch = _epoch;
    final seq = ++_chatSeq;

    var sum = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      var n = 0;
      final unreadMap = data['unread'];
      if (unreadMap is Map) {
        final v = unreadMap[uid];
        if (v is num) n = v.toInt();
      }
      if (n <= 0) continue;

      final participants = List<String>.from(data['participants'] ?? []);
      final other = participants.firstWhere((u) => u != uid, orElse: () => '');
      if (other.isEmpty) continue;
      if (!await _isOrg(other)) continue; // チャット一覧に出るのは団体だけ
      sum += n;
    }

    if (epoch != _epoch || seq != _chatSeq) return;
    _orgUnread = sum;
    _publish();
  }

  // ---------- グループチャット ----------

  void _onSeen(QuerySnapshot<Map<String, dynamic>> snap) {
    final map = <String, DateTime>{};
    for (final d in snap.docs) {
      final t = d.data()['lastSeen'];
      if (t is Timestamp) {
        map[d.id] = t.toDate();
      } else if (d.metadata.hasPendingWrites) {
        // 書き込んだ直後で、サーバーの時刻がまだ確定していない
        map[d.id] = DateTime.now();
      }
    }
    _lastSeen = map;
    _recomputeGroups();
  }

  /// 参加中のイベントを調べ直す。チャットタブを開いたときなどに呼ぶ。
  Future<void> refreshMembership() {
    final running = _refreshing;
    if (running != null) return running;
    final f = _loadMembership().whenComplete(() => _refreshing = null);
    _refreshing = f;
    return f;
  }

  Future<void> _loadMembership() async {
    final uid = _uid;
    if (uid == null) {
      groupsLoaded.value = true;
      return;
    }
    final epoch = _epoch;
    try {
      final eventsSnap =
      await FirebaseFirestore.instance.collection('events').get();
      final flags = await Future.wait(eventsSnap.docs.map((d) async {
        if (d.data()['organizerUid'] == uid) return true;
        final p = await d.reference.collection('participants').doc(uid).get();
        return p.exists;
      }));
      if (epoch != _epoch) return;

      final joined = <String>{};
      _eventMeta.clear();
      for (var i = 0; i < eventsSnap.docs.length; i++) {
        if (!flags[i]) continue;
        final d = eventsSnap.docs[i];
        final data = d.data();
        joined.add(d.id);
        _eventMeta[d.id] = {
          'title': (data['title'] as String?) ?? '',
          'emoji': (data['emoji'] as String?) ?? '🐾',
        };
      }

      // 参加をやめたイベントの監視をやめて、新しく参加したイベントの監視を始める
      for (final id in _msgSubs.keys.toList()) {
        if (!joined.contains(id)) {
          _msgSubs.remove(id)?.cancel();
          _msgs.remove(id);
        }
      }
      for (final id in joined) {
        if (!_msgSubs.containsKey(id)) _listenMessages(id, epoch);
      }

      _recomputeGroups();
      groupsLoaded.value = true;
    } catch (e) {
      debugPrint('UnreadService.loadMembership エラー: $e');
      if (epoch == _epoch) groupsLoaded.value = true;
    }
  }

  void _listenMessages(String eventId, int epoch) {
    _msgSubs[eventId] = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      if (epoch != _epoch) return;
      _msgs[eventId] = snap.docs.map((d) {
        final m = d.data();
        final t = m['createdAt'];
        return _GroupMsg(
          text: (m['text'] as String?) ?? '',
          senderUid: (m['senderUid'] as String?) ?? '',
          isSystem: m['isSystem'] == true,
          at: t is Timestamp ? t.toDate() : null,
        );
      }).toList();
      _recomputeGroups();
    }, onError: (_) {
      // 追放された・イベントが消えたなど。一覧から外す
      _msgSubs.remove(eventId)?.cancel();
      _msgs.remove(eventId);
      _eventMeta.remove(eventId);
      _recomputeGroups();
    });
  }

  void _recomputeGroups() {
    final uid = _uid;
    if (uid == null) return;

    final list = <GroupChatSummary>[];
    var total = 0;
    for (final entry in _eventMeta.entries) {
      final id = entry.key;
      final msgs = _msgs[id];

      var lastMessage = '';
      DateTime? lastAt;
      var unread = 0;
      if (msgs != null && msgs.isNotEmpty) {
        final last = msgs.first; // 新しい順なので、先頭が最新
        lastMessage = last.text;
        lastAt = last.at ?? DateTime.now();

        final seen = _lastSeen[id];
        for (final m in msgs) {
          if (m.isSystem || m.senderUid == uid) continue;
          final at = m.at;
          if (at == null) continue;
          if (seen == null || at.isAfter(seen)) unread++;
        }
      }

      total += unread;
      list.add(GroupChatSummary(
        eventId: id,
        title: entry.value['title'] ?? '',
        emoji: entry.value['emoji'] ?? '🐾',
        lastMessage: lastMessage,
        lastAt: lastAt,
        unread: unread,
      ));
    }

    list.sort((a, b) {
      final at = a.lastAt;
      final bt = b.lastAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    groups.value = list;
    _groupUnread = total;
    _publish();
  }
}