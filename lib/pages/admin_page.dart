import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_page.dart';
import 'admin_report_tools.dart';
import 'package:flutter/services.dart';


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdmin = false;
  bool _loading = true;
  // 通報一覧の表示：open=未対応 / hot=要対応 / done=対応済み / all=すべて
  String _reportFilter = 'open';
  // 入るたびにパスワードで確かめる（この画面を閉じると、また鍵がかかる）
  bool _unlocked = false;


@override
void initState() {
super.initState();
_tabController = TabController(length: 5, vsync: this);


_checkAdmin();
}

Future<void> _checkAdmin() async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) {
setState(() => _loading = false);
return;
}
final doc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
setState(() {
_isAdmin = doc.exists;
_loading = false;
});
}

@override
void dispose() {
_tabController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
if (!_isAdmin) return Scaffold(
appBar: AppBar(
backgroundColor: const Color(0xFFE8845A),
foregroundColor: Colors.white,
title: const Text('運営管理画面'),
),
body: const Center(child: Text('アクセス権限がありません')),
);
if (!_unlocked) {
  return AdminLockScreen(onUnlocked: () => setState(() => _unlocked = true));
}

return Scaffold(
appBar: AppBar(
title: const Text('運営管理画面'),
backgroundColor: const Color(0xFFE8845A),
foregroundColor: Colors.white,
  bottom: TabBar(
    controller: _tabController,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    isScrollable: true,
    tabs: const [
      Tab(text: '通報一覧'),
      Tab(text: 'ユーザー管理'),
      Tab(text: '団体申請'),
      Tab(text: '病院申請'),
      Tab(text: 'お問い合わせ'),
    ],

  ),

),
  body: TabBarView(
    controller: _tabController,
    children: [
      _buildReportList(),
      const UserReportList(),
      _buildOrganizationRequests(),
      _buildHospitalRequests(),
      _buildContactList(),
    ],
  ),


);

}
Widget _buildReportList() {
return Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const ReportSummary(),
const SizedBox(height: 6),
Wrap(
spacing: 6,
children: [
for (final f in const [['open', '未対応'], ['hot', '要対応'], ['done', '対応済み'], ['all', 'すべて']])
ChoiceChip(
label: Text(f[1]),
selected: _reportFilter == f[0],
onSelected: (_) => setState(() => _reportFilter = f[0]),
),
],
),
],
),
),
Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('reports')
.orderBy('createdAt', descending: true)
.limit(300)
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
var docs = snapshot.data!.docs;
// 要対応：同じ相手が、別々の3人以上から通報されていて、まだ対応していないもの
final openReporters = <String, Set<String>>{};
for (final doc in docs) {
final d = doc.data() as Map<String, dynamic>;
if (d['resolved'] == true) continue;
final t = d['targetId'];
final r = d['reporterId'];
if (t is String && r is String) (openReporters[t] ??= <String>{}).add(r);
}
docs = docs.where((doc) {
final d = doc.data() as Map<String, dynamic>;
final done = d['resolved'] == true;
switch (_reportFilter) {
case 'open':
return !done;
case 'hot':
return !done && (openReporters[d['targetId']]?.length ?? 0) >= hotReportThreshold;
case 'done':
return done;
default:
return true;
}
}).toList();
if (docs.isEmpty) return const Center(child: Text('この表示に当てはまる通報はありません'));
return ListView.builder(
itemCount: docs.length,
itemBuilder: (context, index) {
final data = docs[index].data() as Map<String, dynamic>;
final type = data['type'] as String? ?? '';
final resolved = data['resolved'] == true;
final typeLabel = reportContentLabel(data['comment']) ?? (type == 'user' ? '👤 ユーザー通報'
: type == 'event' ? '📅 イベント通報'
: type == 'chat' ? '💬 チャット通報'
: type == 'petBrag' ? '🐾 ペット自慢通報'
: type == 'comment' ? '💬 コメント通報'
: type == 'hospitalTags' ? '🏥 病院タグ通報'
: '❓ その他');

return Card(
margin: const EdgeInsets.all(8),
color: resolved ? Colors.grey[100] : null,
child: ExpansionTile(
title: Row(
children: [
Expanded(
child: Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
),
if (!resolved && data['targetId'] is String)
HotBadge(targetId: data['targetId'] as String),
if (resolved)
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
child: const Text('対応済み', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
),
],
),
  subtitle: FutureBuilder<DocumentSnapshot>(
    future: type == 'hospitalTags'
        ? FirebaseFirestore.instance.collection('hospitals').doc(data['reporterId']).get()
        : FirebaseFirestore.instance.collection('users').doc(data['reporterId']).get(),
    builder: (context, snap) {
      if (!snap.hasData) return const Text('通報者：読み込み中...');
      if (!snap.data!.exists) return const Text('通報者：不明');
      final name = (snap.data!.data() as Map<String, dynamic>?)?['name'] as String? ?? '不明';
      return Text('通報者：$name　${formatReportTime(data['createdAt'])}');
    },
  ),

children: [
Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// 質問掲示板・イベントのチャットの投稿の通報：中身を見せて、開く・消すができる
if (reportedContentPath(data['comment']) != null)
ReportedContentCard(path: reportedContentPath(data['comment'])!, reportId: docs[index].id),
if (type == 'petBrag' && data['targetId'] is String)
FutureBuilder<DocumentSnapshot>(
future: FirebaseFirestore.instance
.collection('petBrags')
.doc(data['targetId'] as String)
.get(),
builder: (context, snap) {
if (!snap.hasData) return const Text('読み込み中...');
if (!snap.data!.exists) {
return const Text('対象：投稿は既に削除されています');
}
final postData = snap.data!.data() as Map<String, dynamic>;
final petName = postData['petName'] ?? '不明';
final imageUrl = postData['imageUrl'] as String?;
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('対象の投稿：$petName'),
if (imageUrl != null && imageUrl.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8),
child: ClipRRect(
borderRadius: BorderRadius.circular(12),
child: Image.network(imageUrl, width: 120, height: 120, fit: BoxFit.cover),
),
),
const SizedBox(height: 8),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () async {
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text('投稿を削除しますか？'),
content: const Text('この操作は取り消せません。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
child: const Text('削除'),
),
],
),
);
if (confirm == true) {
await FirebaseFirestore.instance
.collection('petBrags')
.doc(data['targetId'] as String)
.delete();
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('投稿を削除しました'), backgroundColor: Colors.grey),
);
}
}
},
icon: const Icon(Icons.delete_forever, color: Colors.red),
label: const Text('投稿を削除', style: TextStyle(color: Colors.red)),
style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
),
),
],
);
},
),
if (type == 'comment' && data['targetId'] is String && data['postId'] is String)
FutureBuilder<DocumentSnapshot>(
future: FirebaseFirestore.instance
.collection('petBrags')
.doc(data['postId'] as String)
.collection('comments')
.doc(data['targetId'] as String)
.get(),
builder: (context, snap) {
if (!snap.hasData) return const Text('読み込み中...');
if (!snap.data!.exists) {
return const Text('対象：コメントは既に削除されています');
}
final commentData = snap.data!.data() as Map<String, dynamic>;
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('対象のコメント：${commentData['text'] ?? ''}'),
const SizedBox(height: 4),
Text('投稿者：${commentData['name'] ?? '不明'}',
style: TextStyle(fontSize: 12, color: Colors.grey[600])),
const SizedBox(height: 8),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () async {
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text('コメントを削除しますか？'),
content: const Text('この操作は取り消せません。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
child: const Text('削除'),
),
],
),
);
if (confirm == true) {
await FirebaseFirestore.instance
.collection('petBrags')
.doc(data['postId'] as String)
.collection('comments')
.doc(data['targetId'] as String)
.delete();
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('コメントを削除しました'), backgroundColor: Colors.grey),
);
}
}
},
icon: const Icon(Icons.delete_forever, color: Colors.red),
label: const Text('コメントを削除', style: TextStyle(color: Colors.red)),
style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
),
),
],
);
},
),
if (type == 'hospitalTags' && data['targetId'] is String)
FutureBuilder<DocumentSnapshot>(
future: FirebaseFirestore.instance
.collection('hospitals')
.doc(data['targetId'] as String)
.get(),
builder: (context, snap) {
if (!snap.hasData) return const Text('読み込み中...');
if (!snap.data!.exists) {
return const Text('対象：病院情報が見つかりません');
}
final hospitalData = snap.data!.data() as Map<String, dynamic>;
return Text(
'対象の病院：${hospitalData['name'] ?? '不明'}\n（hospitals/${data['targetId']}/tagVotes を直接確認してください。個別の投票は自動削除できません）');
},
),
  if (data['targetId'] is String &&
      (type == 'user' || type == 'event' || type == 'chat'))
    FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['targetId'] as String)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Text('読み込み中...');
        if (!snap.data!.exists) {
          return const Text('対象：ユーザーが見つかりません');
        }
        final name = (snap.data!.data() as Map<String, dynamic>?)?['name']
        as String? ?? '不明';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('対象のユーザー：$name'),
            UserActionButtons(uid: data['targetId'] as String, reportId: docs[index].id),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteUser(data['targetId'] as String),
                icon: const Icon(Icons.block, color: Colors.red),
                label: const Text('退会させる（元に戻せない）', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        );
      },
    ),

  if (data['reason'] != null)
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('理由：${data['reason']}'),
    ),
  if (reportDetailText(data['comment']) != null)
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('通報した人のメモ：${reportDetailText(data['comment'])}'),
    ),
  const SizedBox(height: 8),
  if (type == 'event' && data['eventId'] is String)
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventPage(initialEventId: data['eventId'] as String),
            ),
          );
        },
        icon: const Icon(Icons.open_in_new),
        label: const Text('イベントを確認'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
        ),
      ),
    ),
  if (type == 'event' && data['eventId'] is String)
    Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('イベントを削除しますか？'),
              content: const Text('この操作は取り消せません。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('削除'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await FirebaseFirestore.instance
                .collection('events')
                .doc(data['eventId'] as String)
                .delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('イベントを削除しました'), backgroundColor: Colors.grey),
              );
            }
          }
        },
        icon: const Icon(Icons.delete_forever),
        label: const Text('イベントを削除'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  ReportActionLog(actions: data['actions']),
  const SizedBox(height: 8),
  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: resolved
              ? null
              : () => resolveReport(context, docs[index].id, data),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(resolved ? '対応済み' : '対応済みにする'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D6A4F),
            side: const BorderSide(color: Color(0xFF2D6A4F)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _deleteReport(docs[index].id),
          icon: const Icon(Icons.delete),
          label: const Text('通報を削除'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ],
  ),
],
),
),
],
),
);
},
);
},
),
),
],
);
}


Widget _buildOrganizationRequests() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return const Center(child: Text('申請はありません'));
      }
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final orgId = docs[index].id;
          final status = data['status'] ?? 'pending';
          final statusLabel = status == 'approved'
              ? '✅ 承認済み'
              : status == 'rejected'
              ? '❌ 却下'
              : '⏳ 審査中';

          final hasPendingUpdate = (data['nameUpdatePending'] ?? '').toString().isNotEmpty ||
              (data['activityUpdatePending'] ?? '').toString().isNotEmpty;

          return Card(
            margin: const EdgeInsets.all(8),
            color: hasPendingUpdate ? Colors.orange[50] : null,
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(data['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (hasPendingUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('変更あり',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text(statusLabel),

              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('活動内容：${data['activityDescription'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('連絡先：${data['contactInfo'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('サイト：${data['websiteUrl'] ?? 'なし'}'),
                      const SizedBox(height: 6),
                      Text('メール：${data['email'] ?? ''}'),
                      const SizedBox(height: 16),
                      if (status == 'approved' &&
                          ((data['nameUpdatePending'] ?? '').toString().isNotEmpty ||
                              (data['activityUpdatePending'] ?? '').toString().isNotEmpty))
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 変更申請があります',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              if ((data['nameUpdatePending'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('団体名の変更案：${data['nameUpdatePending']}'),
                              ],
                              if ((data['activityUpdatePending'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('活動内容の変更案：${data['activityUpdatePending']}'),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final updates = <String, dynamic>{
                                          'nameUpdatePending': FieldValue.delete(),
                                          'activityUpdatePending': FieldValue.delete(),
                                        };
                                        if ((data['nameUpdatePending'] ?? '').toString().isNotEmpty) {
                                          updates['name'] = data['nameUpdatePending'];
                                        }
                                        if ((data['activityUpdatePending'] ?? '').toString().isNotEmpty) {
                                          updates['activityDescription'] = data['activityUpdatePending'];
                                        }
                                        await FirebaseFirestore.instance
                                            .collection('organizations')
                                            .doc(orgId)
                                            .update(updates);
                                        await FirebaseFirestore.instance
                                            .collection('notifications')
                                            .doc(orgId)
                                            .collection('items')
                                            .add({
                                          'type': 'orgUpdateReflected',
                                          'emoji': '📝',
                                          'title': '変更内容が反映されました',
                                          'desc': '団体情報の変更が反映されました',
                                          'read': false,
                                          'createdAt': FieldValue.serverTimestamp(),
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('変更を反映しました'), backgroundColor: Color(0xFF2D6A4F)),
                                          );
                                        }
                                      },

                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white),
                                      child: const Text('反映する'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('organizations')
                                            .doc(orgId)
                                            .update({
                                          'nameUpdatePending': FieldValue.delete(),
                                          'activityUpdatePending': FieldValue.delete(),
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('変更を却下しました'), backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                      child: const Text('却下する'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (status == 'pending')

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('organizations')
                                      .doc(orgId)
                                      .update({'status': 'approved'});
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .doc(orgId)
                                      .collection('items')
                                      .add({
                                    'type': 'orgApproved',
                                    'emoji': '✅',
                                    'title': '団体登録が承認されました',
                                    'desc': '${data['name'] ?? ''}の登録が承認されました。マイページから情報を確認できます',
                                    'read': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('承認しました'),
                                          backgroundColor:
                                          Color(0xFF2D6A4F)),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('承認する'),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6A4F),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('organizations')
                                      .doc(orgId)
                                      .update({'status': 'rejected'});
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .doc(orgId)
                                      .collection('items')
                                      .add({
                                    'type': 'orgRejected',
                                    'emoji': '😢',
                                    'title': '団体登録は承認されませんでした',
                                    'desc': '内容についてご不明な点があれば、お問い合わせください',
                                    'read': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('却下しました'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('却下する'),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
Widget _buildHospitalRequests() {
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('hospitals')
.orderBy('createdAt', descending: true)
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Center(child: CircularProgressIndicator());
}
final docs = snapshot.data!.docs;
if (docs.isEmpty) {
return const Center(child: Text('申請はありません'));
}
return ListView.builder(
itemCount: docs.length,
itemBuilder: (context, index) {
final data = docs[index].data() as Map<String, dynamic>;
final hospitalId = docs[index].id;
final status = data['status'] ?? 'pending';
final statusLabel = status == 'approved'
? '✅ 承認済み'
: status == 'rejected'
? '❌ 却下'
: '⏳ 審査中';
final hasPendingUpdate = (data['nameUpdatePending'] ?? '').toString().isNotEmpty;
final animalTags = List<String>.from(data['animalTags'] ?? []);

return Card(
margin: const EdgeInsets.all(8),
color: hasPendingUpdate ? Colors.orange[50] : null,
child: ExpansionTile(
title: Row(
children: [
Expanded(
child: Text(data['name'] ?? '',
style: const TextStyle(fontWeight: FontWeight.bold)),
),
if (hasPendingUpdate)
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
child: const Text('変更あり', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
),
],
),
subtitle: Text(statusLabel),
children: [
Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
  Text('都道府県：${data['area'] ?? ''}'),
  const SizedBox(height: 6),
  Text('住所：${data['address'] ?? ''}'),
  const SizedBox(height: 6),
  Text('診療時間：${data['businessHours'] ?? ''}'),
  const SizedBox(height: 6),
  Text('連絡先：${data['contactInfo'] ?? ''}'),
  const SizedBox(height: 10),
  InkWell(
    onTap: () {
      final query = '${data['name'] ?? ''} ${data['address'] ?? ''}';
      Clipboard.setData(ClipboardData(text: query));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('検索キーワードをコピーしました。ブラウザで検索してください'), backgroundColor: Color(0xFF2D6A4F)),
      );
    },
    child: Row(
      children: [
        const Icon(Icons.search, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        const Text('病院名と住所をコピーする（検索用）', style: TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
      ],
    ),
  ),

  const SizedBox(height: 6),
Text('メール：${data['email'] ?? ''}'),
const SizedBox(height: 6),
Text('対応動物：${animalTags.join('、')}'),
const SizedBox(height: 6),
Text('新規受付：${data['acceptingNew'] == true ? "○" : "×"}　入院：${data['hasInpatient'] == true ? "○" : "×"}　CT：${data['hasCT'] == true ? "○" : "×"}　MRI：${data['hasMRI'] == true ? "○" : "×"}　夜間：${data['hasNightCare'] == true ? "○" : "×"}'),
const SizedBox(height: 16),
  if (status == 'pending')
    Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('hospitals')
                  .doc(hospitalId)
                  .update({'status': 'approved'});
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(hospitalId)
                  .collection('items')
                  .add({
                'type': 'hospitalApproved',
                'emoji': '✅',
                'title': '病院登録が承認されました',
                'desc': '${data['name'] ?? ''}の登録が承認されました。マイページから情報を確認できます',
                'read': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('承認しました'), backgroundColor: Color(0xFF2D6A4F)),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('承認する'),

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('hospitals')
                  .doc(hospitalId)
                  .update({'status': 'rejected'});
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(hospitalId)
                  .collection('items')
                  .add({
                'type': 'hospitalRejected',
                'emoji': '😢',
                'title': '病院登録は承認されませんでした',
                'desc': '内容についてご不明な点があれば、お問い合わせください',
                'read': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('却下しました'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('却下する'),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  if (hasPendingUpdate)
    Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 病院名の変更申請', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Text('変更案：${data['nameUpdatePending']}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('hospitals')
                        .doc(hospitalId)
                        .update({
                      'name': data['nameUpdatePending'],
                      'nameUpdatePending': FieldValue.delete(),
                    });
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(hospitalId)
                        .collection('items')
                        .add({
                      'type': 'hospitalUpdateReflected',
                      'emoji': '📝',
                      'title': '変更内容が反映されました',
                      'desc': '病院情報の変更が反映されました',
                      'read': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('変更を反映しました'), backgroundColor: Color(0xFF2D6A4F)),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white),
                  child: const Text('反映する'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('hospitals')
                        .doc(hospitalId)
                        .update({'nameUpdatePending': FieldValue.delete()});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('変更を却下しました'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('却下する'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
],
),
),
],
),
);
},
);
},
);
}


Future<void> _deleteReport(String reportId) async {
  await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
}
  Widget _buildContactList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contacts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('お問い合わせはありません'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final contactId = docs[index].id;
            final status = data['status'] ?? '未対応';
            final isResolved = status == '対応済み';

            return Card(
              margin: const EdgeInsets.all(8),
              color: isResolved ? Colors.grey[100] : null,
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(data['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: isResolved ? Colors.grey : const Color(0xFFE8845A),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(status,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: Text(data['category'] ?? ''),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['content'] ?? ''),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isResolved
                                    ? null
                                    : () async {
                                  await FirebaseFirestore.instance
                                      .collection('contacts')
                                      .doc(contactId)
                                      .update({'status': '対応済み'});
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(isResolved ? '対応済み' : '対応済みにする'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2D6A4F),
                                  side: const BorderSide(color: Color(0xFF2D6A4F)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('contacts')
                                      .doc(contactId)
                                      .delete();
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('削除'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

Future<void> _deleteUser(String uid) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('確認'),
      content: const Text('このユーザーを強制退会させますか？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('退会させる', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (confirm == true) {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }
}
}
