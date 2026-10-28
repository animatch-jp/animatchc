// 運営管理画面で使う部品
// ・入るときのパスワード確認（AdminLockScreen）
// ・通報された投稿の中身・開く・削除（ReportedContentCard）
// ・ユーザーを開く・一時停止（UserActionButtons）
// ・同じ相手への通報が多いときの印（HotBadge）、未対応の数（ReportSummary）
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_board_page.dart';
import 'event_chat_page.dart';
import 'user_profile_page.dart';

const _brown = Color(0xFF3D2B1F);
const _orange = Color(0xFFE8845A);
const _green = Color(0xFF2D6A4F);

// 同じ相手が、何人から通報されたら「要対応」にするか
const int hotReportThreshold = 3;

/* ---------------- 通報の comment の読み取り ---------------- */

// 投稿の通報のとき、comment の「場所: ...」から、消してよい投稿の場所を取り出す。
// 質問・回答・イベントのチャットのメッセージ以外は、消せないようにする。
String? reportedContentPath(dynamic comment) {
  if (comment is! String || !comment.startsWith('[')) return null;
  final match = RegExp(r'^場所: (\S+)$', multiLine: true).firstMatch(comment);
  final path = match?.group(1);
  if (path == null) return null;
  const id = r'[A-Za-z0-9_-]+';
  final allowed = RegExp('^questions/$id(/answers/$id)?\$').hasMatch(path) ||
      RegExp('^events/$id/messages/$id\$').hasMatch(path);
  return allowed ? path : null;
}

// 一覧に出す名前（投稿の通報なら「質問掲示板の回答」など）
String? reportContentLabel(dynamic comment) {
  if (reportedContentPath(comment) == null) return null;
  final m = RegExp(r'^\[([^\]]+)\]').firstMatch(comment as String);
  final label = m?.group(1);
  if (label == null) return null;
  if (label.contains('チャット')) return '💬 $label';
  return '📝 $label';
}

// 通報した人が書いたメモだけを取り出す（投稿の情報の行は除く）
String? reportDetailText(dynamic comment) {
  if (comment is! String) return null;
  final text = comment.trim();
  if (text.isEmpty) return null;
  if (reportedContentPath(text) == null) return text;
  final m = RegExp(r'^詳細: ([\s\S]*)$', multiLine: true).firstMatch(text);
  final detail = m?.group(1)?.trim();
  return (detail == null || detail.isEmpty) ? null : detail;
}

String formatReportTime(dynamic ts) {
  if (ts is! Timestamp) return '';
  final t = ts.toDate();
  return '${t.month}/${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

/* ---------------- 入るときのパスワード確認 ---------------- */

class AdminLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const AdminLockScreen({super.key, required this.onUnlocked});

  @override
  State<AdminLockScreen> createState() => _AdminLockScreenState();
}

class _AdminLockScreenState extends State<AdminLockScreen> {
  final _passCtrl = TextEditingController();
  bool _checking = false;
  String? _error;
  int _failCount = 0;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final pass = _passCtrl.text;
    if (user == null || email == null || pass.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      // ログインのパスワードで、もう一度本人か確かめる
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: pass));
      if (!mounted) return;
      widget.onUnlocked();
    } on FirebaseAuthException catch (e) {
      _failCount++;
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = e.code == 'too-many-requests'
            ? '失敗が多すぎます。しばらく待ってから、もう一度ためしてください'
            : 'パスワードがちがいます';
      });
      // 5回まちがえたら、画面を閉じる
      if (_failCount >= 5 && mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = '確かめられませんでした。通信を確認して、もう一度ためしてください';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('運営管理画面'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: _orange),
                const SizedBox(height: 12),
                const Text('運営管理画面に入るには、ログインのパスワードが必要です',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: _brown, height: 1.5)),
                const SizedBox(height: 20),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  autofocus: true,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    errorText: _error,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checking ? null : _unlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('開く', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- 未対応の数と、要対応の印 ---------------- */

class ReportSummary extends StatelessWidget {
  const ReportSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final open = snap.data!.docs.where((d) => d.data()['resolved'] != true).toList();
        final byTarget = <String, Set<String>>{};
        for (final d in open) {
          final t = d.data()['targetId'];
          final r = d.data()['reporterId'];
          if (t is String && r is String) (byTarget[t] ??= <String>{}).add(r);
        }
        final hot = byTarget.values.where((s) => s.length >= hotReportThreshold).length;
        return Wrap(
          spacing: 6,
          children: [
            _chip('未対応 ${open.length}件', open.isEmpty ? Colors.grey : _orange),
            if (hot > 0) _chip('要対応 $hot人', Colors.red),
          ],
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      );
}

// 同じ相手が、別々の人から何人に通報されているか（未対応のものだけ数える）
class HotBadge extends StatelessWidget {
  final String targetId;
  const HotBadge({super.key, required this.targetId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('targetId', isEqualTo: targetId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final reporters = <String>{};
        for (final d in snap.data!.docs) {
          if (d.data()['resolved'] == true) continue;
          final r = d.data()['reporterId'];
          if (r is String) reporters.add(r);
        }
        if (reporters.length < 2) return const SizedBox.shrink();
        final hot = reporters.length >= hotReportThreshold;
        return Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: hot ? Colors.red : Colors.orange[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(hot ? '要対応 ${reporters.length}人が通報' : '${reporters.length}人が通報',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

/* ---------------- 通報された投稿の中身・開く・削除 ---------------- */

class ReportedContentCard extends StatelessWidget {
  final String path;
  final String? reportId; // 対応の記録を残す通報
  const ReportedContentCard({super.key, required this.path, this.reportId});

  bool get _isMessage => path.startsWith('events/');
  String get _firstId => path.split('/')[1];

  Future<void> _open(BuildContext context) async {
    if (_isMessage) {
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(_firstId).get();
      if (!context.mounted) return;
      if (!eventDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('このイベントは、もう削除されています')));
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventChatPage(
            eventId: _firstId,
            eventTitle: eventDoc.data()?['title'] as String? ?? 'イベント',
          ),
        ),
      );
    } else {
      showQuestionDetail(context, _firstId);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('通報された投稿を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.doc(path).delete();
      await logReportAction(reportId, 'delete_post');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('投稿を削除しました'), backgroundColor: Colors.grey));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('削除できませんでした。Firestoreのルールで止められている可能性があります')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E1D7)),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.doc(path).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Text('読み込み中...');
          if (!snap.data!.exists) {
            return const Text('通報された投稿は、もう削除されています',
                style: TextStyle(color: Colors.grey));
          }
          final d = snap.data!.data() ?? const <String, dynamic>{};
          final author = (d['name'] ?? d['senderName'] ?? '') as String;
          final title = d['title'] as String?;
          final body = (d['body'] ?? d['text'] ?? '') as String;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('通報された投稿${author.isNotEmpty ? '（$author さん）' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 6),
              if (title != null && title.isNotEmpty)
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
              Text(body, style: const TextStyle(fontSize: 13, height: 1.5, color: _brown)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('その画面を開く'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _green, side: const BorderSide(color: _green)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('投稿を削除'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ---------------- ユーザーを開く・一時停止 ---------------- */

class UserActionButtons extends StatelessWidget {
  final String uid;
  final String? reportId; // 対応の記録を残す通報
  const UserActionButtons({super.key, required this.uid, this.reportId});

  Future<void> _setSuspended(BuildContext context, bool suspend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspend ? 'このユーザーを一時停止しますか？' : '一時停止を解除しますか？'),
        content: Text(suspend
            ? 'このユーザーはアプリを使えなくなります。データは消えないので、あとで解除できます。'
            : 'このユーザーは、またアプリを使えるようになります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: suspend ? Colors.red : _green, foregroundColor: Colors.white),
            child: Text(suspend ? '一時停止する' : '解除する'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'suspended': suspend,
        'suspendedAt': suspend ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
      await logReportAction(reportId, suspend ? 'suspend' : 'unsuspend');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(suspend ? '一時停止しました' : '一時停止を解除しました'),
            backgroundColor: Colors.grey));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('変更できませんでした。Firestoreのルールで止められている可能性があります')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final suspended = snap.data?.data()?['suspended'] == true;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => UserProfilePage(uid: uid))),
                  icon: const Icon(Icons.person_search, size: 18),
                  label: const Text('プロフィール'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _green, side: const BorderSide(color: _green)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _setSuspended(context, !suspended),
                  icon: Icon(suspended ? Icons.lock_open : Icons.pause_circle, size: 18),
                  label: Text(suspended ? '停止を解除' : '一時停止'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: suspended ? _green : Colors.orange[800],
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ---------------- 対応の記録と、通報した人への連絡 ---------------- */

const Map<String, String> _actionLabels = {
  'resolve': '対応済みにした',
  'delete_post': '投稿を削除した',
  'suspend': '一時停止した',
  'unsuspend': '一時停止を解除した',
  'delete_user': '退会させた',
};

// 通報ごとに「いつ・何をしたか」を残す
Future<void> logReportAction(String? reportId, String action) async {
  if (reportId == null) return;
  try {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'actions': FieldValue.arrayUnion([
        {
          'action': action,
          'at': Timestamp.now(),
          'by': FirebaseAuth.instance.currentUser?.uid ?? '',
        }
      ]),
    });
  } catch (_) {
    // 記録できなくても、対応そのものは止めない
  }
}

// 対応済みにして、通報した人に「対応しました」と知らせる
Future<void> resolveReport(
    BuildContext context, String reportId, Map<String, dynamic> data) async {
  try {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'resolved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('対応済みにできませんでした')));
    }
    return;
  }
  await logReportAction(reportId, 'resolve');
  final reporterId = data['reporterId'];
  if (reporterId is String && reporterId.isNotEmpty) {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(reporterId)
          .collection('items')
          .add({
        'type': 'reportHandled',
        'emoji': '✅',
        'title': '通報への対応が終わりました',
        'desc': 'ご報告ありがとうございました。運営が内容を確かめて、対応しました。',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('対応済みにして、通報した人に知らせました'), backgroundColor: Colors.grey));
  }
}

// 通報のカードの中に出す「対応の記録」
class ReportActionLog extends StatelessWidget {
  final dynamic actions;
  const ReportActionLog({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions is! List || (actions as List).isEmpty) return const SizedBox.shrink();
    final list = (actions as List).whereType<Map>().toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('対応の記録', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          ...list.map((a) => Text(
                '${formatReportTime(a['at'])}　${_actionLabels[a['action']] ?? a['action']}',
                style: const TextStyle(fontSize: 12, color: _brown),
              )),
        ],
      ),
    );
  }
}

/* ---------------- 通報を「人ごと」にまとめる ---------------- */

class ReportStats {
  final Set<String> reporters = {};
  final Set<String> openReporters = {};
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> reports = [];
}

Map<String, ReportStats> buildReportStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final map = <String, ReportStats>{};
  for (final d in docs) {
    final t = d.data()['targetId'];
    final r = d.data()['reporterId'];
    if (t is! String || t.isEmpty) continue;
    final s = map[t] ??= ReportStats();
    s.reports.add(d);
    if (r is String) {
      s.reporters.add(r);
      if (d.data()['resolved'] != true) s.openReporters.add(r);
    }
  }
  return map;
}

// ユーザー管理：通報された人数の多い順に並べ、押すとその人への通報が全部見られる
class UserReportList extends StatefulWidget {
  const UserReportList({super.key});

  @override
  State<UserReportList> createState() => _UserReportListState();
}

class _UserReportListState extends State<UserReportList> {
  String _query = '';
  bool _onlyReported = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, repSnap) {
        final stats = repSnap.hasData
            ? buildReportStats(repSnap.data!.docs)
            : <String, ReportStats>{};
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '名前で検索',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('通報された人だけ'),
                    selected: _onlyReported,
                    onSelected: (v) => setState(() => _onlyReported = v),
                  ),
                  const Spacer(),
                  Text('3人以上の通報で「要対応」',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  var users = snap.data!.docs.where((d) {
                    final name = d.data()['name']?.toString() ?? '';
                    if (_query.isNotEmpty && !name.contains(_query)) return false;
                    if (_onlyReported && !stats.containsKey(d.id)) return false;
                    return true;
                  }).toList();
                  users.sort((a, b) {
                    final ca = stats[a.id]?.openReporters.length ?? 0;
                    final cb = stats[b.id]?.openReporters.length ?? 0;
                    if (ca != cb) return cb.compareTo(ca);
                    final ta = stats[a.id]?.reporters.length ?? 0;
                    final tb = stats[b.id]?.reporters.length ?? 0;
                    return tb.compareTo(ta);
                  });
                  if (users.isEmpty) {
                    return Center(
                        child: Text(_onlyReported ? '通報された人はいません' : 'ユーザーが見つかりません'));
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final d = u.data();
                      final s = stats[u.id];
                      final open = s?.openReporters.length ?? 0;
                      final total = s?.reporters.length ?? 0;
                      final suspended = d['suspended'] == true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(d['name']?.toString() ?? '名前なし',
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (suspended) _tag('停止中', Colors.grey),
                              if (open >= hotReportThreshold) _tag('要対応', Colors.red),
                            ],
                          ),
                          subtitle: Text(
                              '${d['age']?.toString() ?? '-'}歳　${d['prefecture'] ?? ''}　ID: ${u.id.substring(0, u.id.length < 6 ? u.id.length : 6)}'),
                          trailing: total == 0
                              ? null
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$total人が通報',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: open >= hotReportThreshold ? Colors.red : _brown)),
                                    Text('未対応 $open', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                          onTap: () => _openUserSheet(context, u.id, d['name']?.toString() ?? '名前なし', s),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tag(String text, Color color) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      );

  void _openUserSheet(BuildContext context, String uid, String name, ReportStats? s) {
    final reports = [...?s?.reports];
    reports.sort((a, b) {
      final ta = a.data()['createdAt'];
      final tb = b.data()['createdAt'];
      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
      return 0;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brown)),
            Text('${s?.reporters.length ?? 0}人から、${reports.length}件の通報',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            UserActionButtons(uid: uid),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              const Text('通報はありません', style: TextStyle(color: Colors.grey)),
            ...reports.map((r) {
              final rd = r.data();
              final path = reportedContentPath(rd['comment']);
              final resolved = rd['resolved'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: resolved ? Colors.grey[100] : const Color(0xFFFFF8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3E1D7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${reportContentLabel(rd['comment']) ?? '👤 ユーザーへの通報'}　${formatReportTime(rd['createdAt'])}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        if (resolved) _tag('対応済み', Colors.grey),
                      ],
                    ),
                    if (rd['reason'] != null) Text('理由：${rd['reason']}', style: const TextStyle(fontSize: 12)),
                    if (reportDetailText(rd['comment']) != null)
                      Text('通報した人のメモ：${reportDetailText(rd['comment'])}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    if (path != null) ReportedContentCard(path: path, reportId: r.id),
                    ReportActionLog(actions: rd['actions']),
                    if (!resolved)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => resolveReport(context, r.id, rd),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('対応済みにする'),
                          style: TextButton.styleFrom(foregroundColor: _green),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// プロフィールの「運営管理画面」のとなりに出す、未対応の数
class OpenReportCount extends StatelessWidget {
  const OpenReportCount({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snap) {
        // resolved が無い通報も「未対応」に数える
        final n = snap.data?.docs.where((d) => d.data()['resolved'] != true).length ?? 0;
        if (n == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
          child: Text('未対応 $n', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
