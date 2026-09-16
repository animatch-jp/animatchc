import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pet_themes.dart';
import '../services/cloudinary_service.dart';
import 'monthly_themes.dart';
import 'hospital_tags.dart';
import 'notification_prefs.dart';
import 'package:in_app_review/in_app_review.dart';




void showPostDetail(BuildContext context, String postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('petBrags').doc(postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Text('この投稿は削除されました', style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final votes = data['votes'] as Map<String, dynamic>? ?? {};

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
                              ? Image.network(data['imageUrl'] as String,
                              width: double.infinity, height: 280, fit: BoxFit.cover)
                              : Container(
                            width: double.infinity,
                            height: 280,
                            color: Colors.orange[50],
                            child: const Center(child: Text('🐾', style: TextStyle(fontSize: 60))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['petName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF3D2B1F))),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8845A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text(data['theme'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFFE8845A))),
                              ),
                              if ((data['comment'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(data['comment'], style: const TextStyle(fontSize: 15, height: 1.5)),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _VoteButton(
                                      emoji: '😍',
                                      label: 'かわいい',
                                      count: votes['kawaii'] ?? 0,
                                      onTap: () => vote(context, postId, 'kawaii')),
                                  _VoteButton(
                                      emoji: '🤣',
                                      label: 'おもしろい',
                                      count: votes['omoshiroi'] ?? 0,
                                      onTap: () => vote(context, postId, 'omoshiroi')),
                                  _VoteButton(
                                      emoji: '🥹',
                                      label: '癒される',
                                      count: votes['iyashi'] ?? 0,
                                      onTap: () => vote(context, postId, 'iyashi')),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text('コメント (${data['commentCount'] ?? 0})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              _CommentList(postId: postId, postOwnerUid: data['uid'] ?? ''),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _CommentInputBar(
                  postId: postId,
                  postOwnerUid: data['uid'] ?? '',
                  petName: data['petName'] ?? '',
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}


class PetBragPage extends StatefulWidget {
  final int initialTabIndex;
  const PetBragPage({super.key, this.initialTabIndex = 0});

  @override
  State<PetBragPage> createState() => _PetBragPageState();
}

class _PetBragPageState extends State<PetBragPage>
    with SingleTickerProviderStateMixin {
late TabController _tabController;
late int _currentTabIndex;

@override
void initState() {
super.initState();
_currentTabIndex = widget.initialTabIndex;
_tabController = TabController(
length: 5, vsync: this, initialIndex: widget.initialTabIndex);

_tabController.addListener(() {
if (!_tabController.indexIsChanging) {
setState(() => _currentTabIndex = _tabController.index);
}
});
}

@override
void dispose() {
_tabController.dispose();
super.dispose();
}

String get _todayDateKey {
final now = DateTime.now();
return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

@override
Widget build(BuildContext context) {
final themes = getTodayThemes();

return Column(
children: [
_buildMonthlyArea(),
Padding(
padding: const EdgeInsets.all(16),
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFFE8845A), Color(0xFFFFCC80)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(20),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('今日のお題',
style: TextStyle(
color: Colors.white70, fontSize: 12)),
const SizedBox(height: 8),
Wrap(
spacing: 8,
runSpacing: 8,
children: themes
.map((t) => Container(
padding: const EdgeInsets.symmetric(
horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.25),
borderRadius: BorderRadius.circular(20)),
child: Text(t,
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 13)),
))
.toList(),
),
const SizedBox(height: 16),
StreamBuilder<QuerySnapshot>(
stream: FirebaseAuth.instance.currentUser == null
? null
: FirebaseFirestore.instance
.collection('petBrags')
.where('uid',
isEqualTo:
FirebaseAuth.instance.currentUser!.uid)
.where('dateKey', isEqualTo: _todayDateKey)
.snapshots(),
builder: (context, snapshot) {
final checking = !snapshot.hasData;
final postedToday =
snapshot.hasData && snapshot.data!.docs.isNotEmpty;
return SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: checking
? null
: postedToday
? null
: () => _showPostSheet(themes),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: const Color(0xFFE8845A),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14)),
padding: const EdgeInsets.symmetric(vertical: 14),
disabledBackgroundColor:
Colors.white.withOpacity(0.5),
),
child: Text(
postedToday ? '今日は投稿済みです ✓' : '投稿する 📸',
style:
const TextStyle(fontWeight: FontWeight.bold),
),
),
);
},
),
],
),
),
),
TabBar(
controller: _tabController,
labelColor: const Color(0xFFE8845A),
unselectedLabelColor: Colors.grey,
indicatorColor: const Color(0xFFE8845A),
labelPadding: const EdgeInsets.symmetric(horizontal: 4),
labelStyle: const TextStyle(fontSize: 12),
unselectedLabelStyle: const TextStyle(fontSize: 12),
tabs: const [
Tab(text: 'おすすめ'),
Tab(text: '新着'),
Tab(text: '人気'),
Tab(text: '週間ランキング'),
Tab(text: 'マイ投稿'),
],
),

if (_currentTabIndex != 4)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Text(
_currentTabIndex == 0
? '※直近30日以内の投稿からランダムに表示されます'
: _currentTabIndex == 3
? '※直近7日間の投稿が対象のランキングです'
: '※直近30日以内の投稿が表示されます',
style: TextStyle(fontSize: 11, color: Colors.grey[500]),
),
),
Expanded(
child: TabBarView(
controller: _tabController,
children: [
const _RecommendedList(),
_PetBragList(orderByField: 'createdAt'),
_PetBragList(orderByField: 'voteCount'),
const _WeeklyRankingList(),
const _MyPostsList(),
],
),
),
],
);
}

Widget _buildMonthlyArea() {
final now = DateTime.now();
final theme = getCurrentMonthlyTheme(now);
if (!isMonthlyBestPeriod(now)) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
child: Row(
children: [
Text(theme.emoji, style: const TextStyle(fontSize: 24)),
const SizedBox(width: 8),
Expanded(
child: Text('今月のテーマ：${theme.title}',
style: const TextStyle(fontWeight: FontWeight.w600)),
),
_monthlyPostButton(theme.title),
],
),
);
} else {
return SizedBox(
height: 248,
child: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
child: Row(
children: [
Text(theme.emoji, style: const TextStyle(fontSize: 20)),
const SizedBox(width: 6),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('今月のベスト10',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
Text(theme.title,
style: TextStyle(fontSize: 11, color: Colors.grey[600])),
],
),
),
_monthlyPostButton(theme.title, small: true),
],
),
),
const Expanded(child: _MonthlyBestList()),
],
),
);
}
}

Widget _monthlyPostButton(String themeTitle, {bool small = false}) {
final myUid = FirebaseAuth.instance.currentUser?.uid;
final monthKey = getMonthlyThemeKey(DateTime.now());

return StreamBuilder<QuerySnapshot>(
stream: myUid == null
? null
: FirebaseFirestore.instance
.collection('petBrags')
.where('uid', isEqualTo: myUid)
.where('monthlyThemeKey', isEqualTo: monthKey)
.snapshots(),
builder: (context, snapshot) {
final checking = !snapshot.hasData;
final postedCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
final reachedLimit = postedCount >= 5;
return TextButton(
onPressed: checking || reachedLimit
? null
: () => _showMonthlyPostSheet(themeTitle),
child: Text(
reachedLimit ? '今月の投稿上限(5/5)' : '投稿する ($postedCount/5)',
style: TextStyle(
color: reachedLimit ? Colors.grey : const Color(0xFFE8845A),
fontWeight: FontWeight.bold,
fontSize: small ? 12 : 14),
),
);
},
);
}

void _showMonthlyPostSheet(String themeTitle) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _PostMonthlyBragSheet(
themeTitle: themeTitle,
onPosted: () => Navigator.pop(context),
),
),
);
}

void _showPostSheet(List<String> themes) {
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => Padding(
    padding:
    EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: _PostBragSheet(
      themes: themes,
      dateKey: _todayDateKey,
      onPosted: () {
        Navigator.pop(context);
      },
    ),
  ),
);
}
}
Future<void> vote(BuildContext context, String postId, String voteType) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;

  final voterDoc = await FirebaseFirestore.instance
      .collection('petBrags')
      .doc(postId)
      .collection('voters')
      .doc(myUid)
      .get();

  if (voterDoc.exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('すでに投票済みです')),
    );
    return;
  }

  await FirebaseFirestore.instance
      .collection('petBrags')
      .doc(postId)
      .collection('voters')
      .doc(myUid)
      .set({'voteType': voteType, 'createdAt': FieldValue.serverTimestamp()});

  await FirebaseFirestore.instance.collection('petBrags').doc(postId).update({
    'votes.$voteType': FieldValue.increment(1),
    'voteCount': FieldValue.increment(1),
  });

  final postDoc = await FirebaseFirestore.instance.collection('petBrags').doc(postId).get();
  final postData = postDoc.data();
  final postOwnerUid = postData?['uid'] as String?;
  final petName = postData?['petName'] as String? ?? '';

  if (postOwnerUid != null && postOwnerUid != myUid &&
      await shouldSendNotification(postOwnerUid, 'リアクション')) {
    final emojiMap = {'kawaii': '😍', 'omoshiroi': '🤣', 'iyashi': '🥹'};
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(postOwnerUid)
        .collection('items')
        .add({
      'type': 'like',
      'emoji': emojiMap[voteType] ?? '🔔',
      'title': '$petNameの投稿にリアクションがつきました',
      'desc': '誰かがあなたの投稿に反応しました',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

}

class _PetBragList extends StatefulWidget {
  final String orderByField;
  const _PetBragList({required this.orderByField});

  @override
  State<_PetBragList> createState() => _PetBragListState();
}

class _PetBragListState extends State<_PetBragList> {
String? _animalFilter;

Future<void> _deletePost(BuildContext context, String postId) async {
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('投稿を削除しますか？'),
content: const Text('この操作は取り消せません。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text('削除'),
),
],
),
);

if (confirm == true) {
await FirebaseFirestore.instance
.collection('petBrags')
.doc(postId)
.delete();
}
}

Future<void> _reportPost(BuildContext context, String postId, String targetUid) async {
final reason = await showDialog<String>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('通報しますか？'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text('通報する理由を選んでください'),
const SizedBox(height: 12),
...['動物と関係ない投稿', '不適切なコンテンツ', 'スパム', 'その他'].map((r) =>
ListTile(
title: Text(r),
onTap: () => Navigator.pop(context, r),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
],
),
);

if (reason == null) return;

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

await FirebaseFirestore.instance.collection('reports').add({
'type': 'petBrag',
'reporterId': myUid,
'targetId': postId,
'targetUid': targetUid,
'reason': reason,
'createdAt': FieldValue.serverTimestamp(),
});

if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('通報しました。ご報告ありがとうございます。'),
backgroundColor: Color(0xFFE8845A),
),
);
}
}

@override
Widget build(BuildContext context) {
final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
return Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
child: SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_animalFilterChip('すべて', null),
...hospitalAnimalTags.map((t) => _animalFilterChip(t, t)),
],
),
),
),
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('petBrags')
.where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
.orderBy('createdAt', descending: true)
.limit(50)
.snapshots(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return Center(
child: Text('読み込みエラー: ${snapshot.error}',
style: const TextStyle(color: Colors.red)));
}
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)));
}
var docs = snapshot.data!.docs.toList();
if (_animalFilter != null) {
docs = docs
.where((d) =>
(d.data() as Map<String, dynamic>)['animalType'] ==
_animalFilter)
.toList();
}
if (widget.orderByField == 'voteCount') {
docs.sort((a, b) {
final aVotes =
(a.data() as Map<String, dynamic>)['voteCount'] ?? 0;
final bVotes =
(b.data() as Map<String, dynamic>)['voteCount'] ?? 0;
return (bVotes as int).compareTo(aVotes as int);
});
}

if (docs.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(32),
child: Text('まだ投稿がありません', style: TextStyle(color: Colors.grey)),
),
);
}
return ListView.builder(
padding: const EdgeInsets.all(16),
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: docs.length,
itemBuilder: (_, i) {
final data = docs[i].data() as Map<String, dynamic>;
final postId = docs[i].id;
final votes = data['votes'] as Map<String, dynamic>? ?? {};
final commentCount = data['commentCount'] ?? 0;
return GestureDetector(
onTap: () => showPostDetail(context, postId),

child: Container(
margin: const EdgeInsets.only(bottom: 16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 2))
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius:
const BorderRadius.vertical(top: Radius.circular(20)),
child: data['imageUrl'] != null &&
(data['imageUrl'] as String).isNotEmpty
? Image.network(data['imageUrl'] as String,
width: double.infinity,
height: 260,
fit: BoxFit.cover,
loadingBuilder: (context, child, progress) {
if (progress == null) return child;
return Container(
width: double.infinity,
height: 260,
color: Colors.orange[50],
child: const Center(
child: CircularProgressIndicator(
color: Color(0xFFE8845A))),
);
},
errorBuilder: (context, error, stackTrace) => Container(
width: double.infinity,
height: 260,
color: Colors.orange[50],
child: const Center(
child: Text('🐾', style: TextStyle(fontSize: 60))),
))
: Container(
width: double.infinity,
height: 260,
color: Colors.orange[50],
child: const Center(
child: Text('🐾', style: TextStyle(fontSize: 60))),
),
),
Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(data['petName'] ?? '',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
color: Color(0xFF3D2B1F))),
),
if (FirebaseAuth.instance.currentUser?.uid ==
data['uid'])
GestureDetector(
onTap: () => _deletePost(context, postId),
child: const Icon(Icons.delete_outline_rounded,
color: Colors.grey, size: 20),
)
else
GestureDetector(
onTap: () =>
_reportPost(context, postId, data['uid'] ?? ''),
child: const Icon(Icons.flag_outlined,
color: Colors.grey, size: 20),
),
],
),
const SizedBox(height: 4),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: (data['monthlyThemeKey'] != null)
? const Color(0xFF2D6A4F).withOpacity(0.1)
: const Color(0xFFE8845A).withOpacity(0.1),
borderRadius: BorderRadius.circular(12)),
child: Text(
(data['monthlyThemeKey'] != null ? '🌻 ' : '') +
(data['theme'] ?? ''),
style: TextStyle(
fontSize: 12,
color: (data['monthlyThemeKey'] != null)
? const Color(0xFF2D6A4F)
: const Color(0xFFE8845A))),
),
if ((data['comment'] ?? '').toString().isNotEmpty) ...[
const SizedBox(height: 8),
Text(data['comment'],
style: const TextStyle(fontSize: 13)),
],
const SizedBox(height: 12),
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
_VoteButton(
emoji: '😍',
label: 'かわいい',
count: votes['kawaii'] ?? 0,
onTap: () => vote(context, postId, 'kawaii')),
_VoteButton(
emoji: '🤣',
label: 'おもしろい',
count: votes['omoshiroi'] ?? 0,
onTap: () =>
vote(context, postId, 'omoshiroi')),
_VoteButton(
emoji: '🥹',
label: '癒される',
count: votes['iyashi'] ?? 0,
onTap: () => vote(context, postId, 'iyashi')),
],
),
if (commentCount > 0) ...[
const SizedBox(height: 8),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.chat_bubble_outline_rounded,
size: 12, color: Colors.grey[400]),
const SizedBox(width: 4),
Text('$commentCount件のコメント',
style: TextStyle(
fontSize: 11, color: Colors.grey[400])),
],
),
],
],
),
),
],
),
),
);
},
);
},
),
],
);
}

Widget _animalFilterChip(String label, String? value) {
final sel = _animalFilter == value;
return GestureDetector(
onTap: () => setState(() => _animalFilter = value),
child: Container(
margin: const EdgeInsets.only(right: 8, bottom: 8),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
      color: sel ? const Color(0xFF4DA8DA) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: sel
          ? []
          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
  child: Text(label,
      style: TextStyle(
          fontSize: 11,
          color: sel ? Colors.white : Colors.grey[700],
          fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
),
);
}
}
class _CommentList extends StatelessWidget {
  final String postId;
  final String postOwnerUid;
  const _CommentList({required this.postId, required this.postOwnerUid});

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('petBrags')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
    await FirebaseFirestore.instance
        .collection('petBrags')
        .doc(postId)
        .update({'commentCount': FieldValue.increment(-1)});
  }

  Future<void> _reportComment(BuildContext context, String commentId, String targetUid) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('通報しますか？（コメントは削除されます）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('通報する理由を選んでください'),
            const SizedBox(height: 12),
            ...['動物と関係ない投稿', '不適切なコンテンツ', 'スパム', 'その他'].map((r) =>
                ListTile(
                  title: Text(r),
                  onTap: () => Navigator.pop(context, r),
                ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (reason == null) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'type': 'comment',
      'reporterId': myUid,
      'targetId': commentId,
      'targetUid': targetUid,
      'postId': postId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _deleteComment(commentId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通報しました。コメントを削除しました。'),
          backgroundColor: Color(0xFFE8845A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isPostOwner = myUid != null && myUid == postOwnerUid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('petBrags')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('まだコメントがありません', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isMine = data['uid'] == myUid;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(data['text'] ?? '', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (isMine)
                    GestureDetector(
                      onTap: () => _deleteComment(doc.id),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    )
                  else if (isPostOwner)
                    GestureDetector(
                      onTap: () => _reportComment(context, doc.id, data['uid'] ?? ''),
                      child: const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
class _CommentInputBar extends StatefulWidget {
  final String postId;
  final String postOwnerUid;
  final String petName;
  const _CommentInputBar({
    required this.postId,
    required this.postOwnerUid,
    required this.petName,
  });

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
final _commentCtrl = TextEditingController();
bool _isSending = false;

@override
void dispose() {
_commentCtrl.dispose();
super.dispose();
}

Future<void> _sendComment() async {
final text = _commentCtrl.text.trim();
if (text.isEmpty) return;

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

setState(() => _isSending = true);

final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
final myName = userDoc.data()?['name'] as String? ?? '名無しさん';

await FirebaseFirestore.instance
.collection('petBrags')
.doc(widget.postId)
.collection('comments')
.add({
'uid': myUid,
'name': myName,
  'text': text,
  'createdAt': FieldValue.serverTimestamp(),
});

await FirebaseFirestore.instance
    .collection('petBrags')
    .doc(widget.postId)
    .update({'commentCount': FieldValue.increment(1)});

if (widget.postOwnerUid != myUid &&
    await shouldSendNotification(widget.postOwnerUid, 'コメント・メッセージ')) {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(widget.postOwnerUid)
      .collection('items')
      .add({
    'type': 'chat',
    'emoji': '💬',
    'title': '${widget.petName}の投稿にコメントがつきました',
    'desc': '$myName: $text',
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}


_commentCtrl.clear();
setState(() => _isSending = false);
}

@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!)),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: 'コメントする',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendComment,
            icon: _isSending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8845A)))
                : const Icon(Icons.send_rounded, color: Color(0xFFE8845A)),
          ),
        ],
      ),
    ),
  );
}
}



class _RecommendedList extends StatefulWidget {
  const _RecommendedList();

  @override
  State<_RecommendedList> createState() => _RecommendedListState();
}

class _RecommendedListState extends State<_RecommendedList> {
List<String>? _shuffledOrder;

Future<void> _deletePost(BuildContext context, String postId) async {
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('投稿を削除しますか？'),
content: const Text('この操作は取り消せません。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text('削除'),
),
],
),
);

if (confirm == true) {
await FirebaseFirestore.instance
.collection('petBrags')
.doc(postId)
.delete();
}
}

Future<void> _reportPost(BuildContext context, String postId, String targetUid) async {
final reason = await showDialog<String>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('通報しますか？'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text('通報する理由を選んでください'),
const SizedBox(height: 12),
...['動物と関係ない投稿', '不適切なコンテンツ', 'スパム', 'その他'].map((r) =>
ListTile(
title: Text(r),
onTap: () => Navigator.pop(context, r),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
],
),
);

if (reason == null) return;

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

await FirebaseFirestore.instance.collection('reports').add({
'type': 'petBrag',
'reporterId': myUid,
'targetId': postId,
'targetUid': targetUid,
'reason': reason,
'createdAt': FieldValue.serverTimestamp(),
});

if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('通報しました。ご報告ありがとうございます。'),
backgroundColor: Color(0xFFE8845A),
),
);
}
}
@override
Widget build(BuildContext context) {
final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('petBrags')
.where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
.orderBy('createdAt', descending: true)
.limit(50)
.snapshots(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return Center(
child: Text('読み込みエラー: ${snapshot.error}',
style: const TextStyle(color: Colors.red)));
}
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)));
}

final docs = snapshot.data!.docs;
final docsById = {for (final d in docs) d.id: d};

if (_shuffledOrder == null || _shuffledOrder!.length != docs.length) {
_shuffledOrder = docs.map((d) => d.id).toList()..shuffle();
}

final orderedDocs = _shuffledOrder!
.where((id) => docsById.containsKey(id))
.map((id) => docsById[id]!)
.toList();

if (orderedDocs.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(32),
child: Text('まだ投稿がありません', style: TextStyle(color: Colors.grey)),
),
);
}
return ListView.builder(
  padding: const EdgeInsets.all(16),
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: orderedDocs.length,
  itemBuilder: (_, i) {
    final data = orderedDocs[i].data() as Map<String, dynamic>;
    final postId = orderedDocs[i].id;
    final votes = data['votes'] as Map<String, dynamic>? ?? {};
    final commentCount = data['commentCount'] ?? 0;
    return GestureDetector(
      onTap: () => showPostDetail(context, postId),

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: data['imageUrl'] != null &&
                  (data['imageUrl'] as String).isNotEmpty
                  ? Image.network(data['imageUrl'] as String,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover)
                  : Container(
                width: double.infinity,
                height: 260,
                color: Colors.orange[50],
                child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 60))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(data['petName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF3D2B1F))),
                      ),
                      if (FirebaseAuth.instance.currentUser?.uid ==
                          data['uid'])
                        GestureDetector(
                          onTap: () => _deletePost(context, postId),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.grey, size: 20),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              _reportPost(context, postId, data['uid'] ?? ''),
                          child: const Icon(Icons.flag_outlined,
                              color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: (data['monthlyThemeKey'] != null)
                            ? const Color(0xFF2D6A4F).withOpacity(0.1)
                            : const Color(0xFFE8845A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        (data['monthlyThemeKey'] != null ? '🌻 ' : '') +
                            (data['theme'] ?? ''),
                        style: TextStyle(
                            fontSize: 12,
                            color: (data['monthlyThemeKey'] != null)
                                ? const Color(0xFF2D6A4F)
                                : const Color(0xFFE8845A))),
                  ),
                  if ((data['comment'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(data['comment'],
                        style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _VoteButton(
                          emoji: '😍',
                          label: 'かわいい',
                          count: votes['kawaii'] ?? 0,
                          onTap: () => vote(context, postId, 'kawaii')),
                      _VoteButton(
                          emoji: '🤣',
                          label: 'おもしろい',
                          count: votes['omoshiroi'] ?? 0,
                          onTap: () =>
                              vote(context, postId, 'omoshiroi')),
                      _VoteButton(
                          emoji: '🥹',
                          label: '癒される',
                          count: votes['iyashi'] ?? 0,
                          onTap: () => vote(context, postId, 'iyashi')),
                    ],
                  ),
                  if (commentCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('$commentCount件のコメント',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
},
);
}
}



class _VoteButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _VoteButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(count > 0 ? '$count' : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PostBragSheet extends StatefulWidget {
  final List<String> themes;
  final String dateKey;
  final VoidCallback onPosted;

  const _PostBragSheet({
    required this.themes,
    required this.dateKey,
    required this.onPosted,
  });

  @override
  State<_PostBragSheet> createState() => _PostBragSheetState();
}

class _PostBragSheetState extends State<_PostBragSheet> {
String? _imageUrl;
bool _isUploading = false;
bool _isPosting = false;
String? _selectedTheme;
String? _selectedAnimalType;
String? _selectedPetId;
final _petNameCtrl = TextEditingController();
final _commentCtrl = TextEditingController();
List<Map<String, dynamic>> _myPets = [];
bool _isLoadingPets = true;

@override
void initState() {
super.initState();
_loadMyPets();
}

Future<void> _loadMyPets() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) {
setState(() => _isLoadingPets = false);
return;
}
final snapshot = await FirebaseFirestore.instance
.collection('users')
.doc(myUid)
.collection('pets')
.get();
setState(() {
_myPets = snapshot.docs
.map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''})
.toList();
_isLoadingPets = false;
});
}

Future<void> _pickImage() async {
setState(() => _isUploading = true);
final url = await CloudinaryService.pickAndUploadImage();
setState(() {
if (url != null) _imageUrl = url;
_isUploading = false;
});
}

Future<void> _submit() async {
if (_imageUrl == null || _petNameCtrl.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('写真とペットの名前を入力してください')),
);
return;
}

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

setState(() => _isPosting = true);

await FirebaseFirestore.instance.collection('petBrags').add({
'uid': myUid,
'petId': _selectedPetId,
'petName': _petNameCtrl.text.trim(),
'imageUrl': _imageUrl,
'comment': _commentCtrl.text.trim(),
'theme': _selectedTheme,
'animalType': _selectedAnimalType,
'dateKey': widget.dateKey,
'createdAt': FieldValue.serverTimestamp(),
'votes': {'kawaii': 0, 'omoshiroi': 0, 'iyashi': 0},
'voteCount': 0,
'commentCount': 0,
});

await _checkAndAwardBadges(myUid);

await _maybeRequestReview(myUid);

widget.onPosted();

}

Future<void> _checkAndAwardBadges(String uid) async {
final snapshot = await FirebaseFirestore.instance
.collection('petBrags')
.where('uid', isEqualTo: uid)
.get();

final postedThemes = snapshot.docs
.map((d) => (d.data())['theme'] as String? ?? '')
.toSet();

final newBadges = <String>[];

if (petBragThemes.every((t) => postedThemes.contains(t))) {
newBadges.add('うちの子お題マスター');
}
if (discoveryThemes.every((t) => postedThemes.contains(t))) {
newBadges.add('発見マスター');
}

if (newBadges.isEmpty) return;

final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
final userDoc = await userRef.get();
final existingBadges =
List<String>.from(userDoc.data()?['badges'] ?? []);

final toAdd =
newBadges.where((b) => !existingBadges.contains(b)).toList();

if (toAdd.isNotEmpty) {
await userRef.update({
'badges': FieldValue.arrayUnion(toAdd),
});

for (final badge in toAdd) {
  if (!await shouldSendNotification(uid, 'ランキング・バッジ')) continue;
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .add({
    'type': 'support',
    'emoji': '🏆',
    'title': 'バッジを獲得しました！',
    'desc': '「$badge」バッジを獲得しました。プロフィールから確認できます',
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

}
}
Future<void> _maybeRequestReview(String uid) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final userDoc = await userRef.get();

  if (userDoc.data()?['hasBeenAskedForReview'] == true) return;

  final badges = List<String>.from(userDoc.data()?['badges'] ?? []);
  final hasBadge = badges.isNotEmpty;

  final postsSnapshot = await FirebaseFirestore.instance
      .collection('petBrags')
      .where('uid', isEqualTo: uid)
      .get();
  final postCount = postsSnapshot.docs.length;

  if (postCount == 3 || hasBadge) {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
    await userRef.update({'hasBeenAskedForReview': true});
  }
}

@override
Widget build(BuildContext context) {
return SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
const Text('ペット自慢を投稿',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 16),
GestureDetector(
onTap: _isUploading ? null : _pickImage,
child: Container(
width: double.infinity,
height: 180,
decoration: BoxDecoration(
color: Colors.orange[50],
borderRadius: BorderRadius.circular(16)),
child: _isUploading
? const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)))
: _imageUrl != null
? ClipRRect(
borderRadius: BorderRadius.circular(16),
child: Image.network(_imageUrl!,
width: double.infinity, fit: BoxFit.cover))
: const Center(
child: Text('📸 写真を選ぶ', style: TextStyle(color: Colors.grey))),
),
),
const SizedBox(height: 16),
if (!_isLoadingPets && _myPets.isNotEmpty) ...[
const Text('うちの子を選ぶ（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Wrap(
spacing: 8,
runSpacing: 8,
children: _myPets.map((pet) {
final sel = _selectedPetId == pet['id'];
return GestureDetector(
onTap: () => setState(() {
if (sel) {
_selectedPetId = null;
} else {
_selectedPetId = pet['id'];
_petNameCtrl.text = pet['name'];
}
}),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
borderRadius: BorderRadius.circular(20)),
child: Text('🐾 ${pet['name']}',
style: TextStyle(
color: sel ? Colors.white : Colors.grey[700])),
),
);
}).toList(),
),
const SizedBox(height: 12),
],
TextField(
controller: _petNameCtrl,
maxLength: 20,
onChanged: (_) {
if (_selectedPetId != null) {
setState(() => _selectedPetId = null);
}
},
decoration: InputDecoration(
labelText: _myPets.isNotEmpty ? 'ペットの名前（自分で入力も可）' : 'ペットの名前',
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
),
),
  const SizedBox(height: 12),
  const Text('動物の種類（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: hospitalAnimalTags.map((t) {
      final sel = _selectedAnimalType == t;
      return GestureDetector(
        onTap: () => setState(() => _selectedAnimalType = sel ? null : t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  fontSize: 12,
                  color: sel ? Colors.white : Colors.grey[700])),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 12),
  const Text('お題を選ぶ（任意）', style: TextStyle(fontWeight: FontWeight.bold)),

  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    children: widget.themes.map((t) {
      final sel = _selectedTheme == t;
      return GestureDetector(
        onTap: () => setState(() => _selectedTheme = sel ? null : t),
        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  color: sel ? Colors.white : Colors.grey[700])),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 12),
  TextField(
    controller: _commentCtrl,
    maxLines: 2,
    maxLength: 100,
    decoration: InputDecoration(
      labelText: 'コメント（任意）',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  const SizedBox(height: 20),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isPosting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8845A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isPosting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('投稿する', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ),
],
),
);
}
}
class _PostMonthlyBragSheet extends StatefulWidget {
  final String themeTitle;
  final VoidCallback onPosted;

  const _PostMonthlyBragSheet({
    required this.themeTitle,
    required this.onPosted,
  });

  @override
  State<_PostMonthlyBragSheet> createState() => _PostMonthlyBragSheetState();
}

class _PostMonthlyBragSheetState extends State<_PostMonthlyBragSheet> {
String? _imageUrl;
bool _isUploading = false;
bool _isPosting = false;
String? _selectedPetId;
String? _selectedAnimalType;
final _petNameCtrl = TextEditingController();
final _commentCtrl = TextEditingController();
List<Map<String, dynamic>> _myPets = [];
bool _isLoadingPets = true;

@override
void initState() {
super.initState();
_loadMyPets();
}

Future<void> _loadMyPets() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) {
setState(() => _isLoadingPets = false);
return;
}
final snapshot = await FirebaseFirestore.instance
.collection('users')
.doc(myUid)
.collection('pets')
.get();
setState(() {
_myPets = snapshot.docs
.map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''})
.toList();
_isLoadingPets = false;
});
}

Future<void> _pickImage() async {
setState(() => _isUploading = true);
final url = await CloudinaryService.pickAndUploadImage();
setState(() {
if (url != null) _imageUrl = url;
_isUploading = false;
});
}

Future<void> _submit() async {
if (_imageUrl == null || _petNameCtrl.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('写真とペットの名前を入力してください')),
);
return;
}

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

setState(() => _isPosting = true);

final now = DateTime.now();
final dateKey =
'${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

await FirebaseFirestore.instance.collection('petBrags').add({
'uid': myUid,
'petId': _selectedPetId,
'petName': _petNameCtrl.text.trim(),
'imageUrl': _imageUrl,
'comment': _commentCtrl.text.trim(),
'theme': widget.themeTitle,
'animalType': _selectedAnimalType,
'monthlyThemeKey': getMonthlyThemeKey(now),
'dateKey': dateKey,
'createdAt': FieldValue.serverTimestamp(),
'votes': {'kawaii': 0, 'omoshiroi': 0, 'iyashi': 0},
'voteCount': 0,
'commentCount': 0,
});

await _maybeRequestReview(myUid);

widget.onPosted();



}

Future<void> _maybeRequestReview(String uid) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final userDoc = await userRef.get();

  if (userDoc.data()?['hasBeenAskedForReview'] == true) return;

  final badges = List<String>.from(userDoc.data()?['badges'] ?? []);
  final hasBadge = badges.isNotEmpty;

  final postsSnapshot = await FirebaseFirestore.instance
      .collection('petBrags')
      .where('uid', isEqualTo: uid)
      .get();
  final postCount = postsSnapshot.docs.length;

  if (postCount == 3 || hasBadge) {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
    await userRef.update({'hasBeenAskedForReview': true});
  }
}

@override
Widget build(BuildContext context) {

return SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text('今月のお題「${widget.themeTitle}」で投稿',
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 16),
GestureDetector(
onTap: _isUploading ? null : _pickImage,
child: Container(
width: double.infinity,
height: 180,
decoration: BoxDecoration(
color: Colors.orange[50],
borderRadius: BorderRadius.circular(16)),
child: _isUploading
? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845A)))
: _imageUrl != null
? ClipRRect(
borderRadius: BorderRadius.circular(16),
child: Image.network(_imageUrl!, width: double.infinity, fit: BoxFit.cover))
: const Center(child: Text('📸 写真を選ぶ', style: TextStyle(color: Colors.grey))),
),
),
  const SizedBox(height: 16),
  if (!_isLoadingPets && _myPets.isNotEmpty) ...[
    const Text('うちの子を選ぶ（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _myPets.map((pet) {
        final sel = _selectedPetId == pet['id'];
        return GestureDetector(
          onTap: () => setState(() {
            if (sel) {
              _selectedPetId = null;
            } else {
              _selectedPetId = pet['id'];
              _petNameCtrl.text = pet['name'];
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20)),
            child: Text('🐾 ${pet['name']}',
                style: TextStyle(color: sel ? Colors.white : Colors.grey[700])),
          ),
        );
      }).toList(),
    ),
    const SizedBox(height: 12),
  ],
  TextField(
    controller: _petNameCtrl,
    maxLength: 20,
    onChanged: (_) {
      if (_selectedPetId != null) {
        setState(() => _selectedPetId = null);
      }
    },
    decoration: InputDecoration(
      labelText: _myPets.isNotEmpty ? 'ペットの名前（自分で入力も可）' : 'ペットの名前',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  const SizedBox(height: 12),
  const Text('動物の種類（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: hospitalAnimalTags.map((t) {
      final sel = _selectedAnimalType == t;
      return GestureDetector(
        onTap: () => setState(() => _selectedAnimalType = sel ? null : t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  fontSize: 12,
                  color: sel ? Colors.white : Colors.grey[700])),
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 12),
  TextField(
    controller: _commentCtrl,
    maxLines: 2,
    maxLength: 100,
    decoration: InputDecoration(
      labelText: 'コメント（任意）',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  const SizedBox(height: 20),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isPosting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8845A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isPosting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('投稿する', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ),
],
),
);
}
}
class _WeeklyRankingList extends StatefulWidget {
  const _WeeklyRankingList();

  @override
  State<_WeeklyRankingList> createState() => _WeeklyRankingListState();
}

class _WeeklyRankingListState extends State<_WeeklyRankingList> {
String _category = 'kawaii';

static const _categories = {
'kawaii': ('😍', 'かわいい部門'),
'omoshiroi': ('🤣', 'おもしろい部門'),
'iyashi': ('🥹', '癒される部門'),
};

@override
Widget build(BuildContext context) {
final weekAgo = DateTime.now().subtract(const Duration(days: 7));

return Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Row(
children: _categories.entries.map((entry) {
final sel = _category == entry.key;
return Expanded(
child: GestureDetector(
onTap: () => setState(() => _category = entry.key),
child: Container(
margin: const EdgeInsets.symmetric(horizontal: 4),
padding: const EdgeInsets.symmetric(vertical: 10),
decoration: BoxDecoration(
color: sel
? const Color(0xFFE8845A)
: Colors.grey[100],
borderRadius: BorderRadius.circular(14)),
child: Column(
children: [
Text(entry.value.$1,
style: const TextStyle(fontSize: 18)),
Text(entry.value.$2,
style: TextStyle(
fontSize: 10,
color: sel ? Colors.white : Colors.grey[700],
fontWeight: FontWeight.bold)),
],
),
),
),
);
}).toList(),
),
),
Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('petBrags')
.where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
.orderBy('createdAt')
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)));
}
final docs = snapshot.data!.docs.toList();
docs.sort((a, b) {
final aVotes = ((a.data() as Map<String, dynamic>)['votes']
as Map<String, dynamic>?)?[_category] ??
0;
final bVotes = ((b.data() as Map<String, dynamic>)['votes']
as Map<String, dynamic>?)?[_category] ??
0;
return (bVotes as int).compareTo(aVotes as int);
});

if (docs.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(32),
child: Text('今週の投稿はまだありません',
style: TextStyle(color: Colors.grey)),
),
);
}
return ListView.builder(
padding: const EdgeInsets.all(16),
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: docs.length,
itemBuilder: (_, i) {
final data = docs[i].data() as Map<String, dynamic>;
final votes = data['votes'] as Map<String, dynamic>? ?? {};
final voteCount = votes[_category] ?? 0;
final rank = i + 1;
final medal = rank == 1
? '🥇'
: rank == 2
    ? '🥈'
    : rank == 3
    ? '🥉'
    : '${rank}位';

return GestureDetector(
  onTap: () => showPostDetail(context, docs[i].id),


  child: Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: rank == 1
          ? const Color(0xFFFFF3CD)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(medal,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: data['imageUrl'] != null &&
              (data['imageUrl'] as String).isNotEmpty
              ? Image.network(data['imageUrl'] as String,
              width: 60, height: 60, fit: BoxFit.cover)
              : Container(
            width: 60,
            height: 60,
            color: Colors.orange[50],
            child: const Center(child: Text('🐾')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['petName'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              Text(data['theme'] ?? '',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Text('$voteCount票',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8845A))),
      ],
    ),
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
}
class _MonthlyBestList extends StatelessWidget {
const _MonthlyBestList();

@override
Widget build(BuildContext context) {
final now = DateTime.now();
final key = getMonthlyThemeKey(now);

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('petBrags')
.where('monthlyThemeKey', isEqualTo: key)
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)));
}
var docs = snapshot.data!.docs.toList();
docs.sort((a, b) {
final aVotes = (a.data() as Map<String, dynamic>)['voteCount'] ?? 0;
final bVotes = (b.data() as Map<String, dynamic>)['voteCount'] ?? 0;
return (bVotes as int).compareTo(aVotes as int);
});
docs = docs.take(10).toList();

if (docs.isEmpty) {
return const Center(
child: Text('今月の投稿はまだありません',
style: TextStyle(color: Colors.grey, fontSize: 12)),
);
}

return ListView.builder(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: docs.length,
itemBuilder: (_, i) {
final data = docs[i].data() as Map<String, dynamic>;
final rank = i + 1;
final isMine = data['uid'] == FirebaseAuth.instance.currentUser?.uid;

final medal = rank == 1
? '🥇'
: rank == 2
? '🥈'
: rank == 3
? '🥉'
: '${rank}位';
final voteCount = data['voteCount'] ?? 0;

return GestureDetector(
onTap: () => showPostDetail(context, docs[i].id),

child: Container(
width: 130,
margin: const EdgeInsets.only(right: 12),
decoration: BoxDecoration(
color: rank == 1 ? const Color(0xFFFFF3CD) : Colors.white,
borderRadius: BorderRadius.circular(16),
border: isMine
? Border.all(color: const Color(0xFFE8845A), width: 2)
: null,
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 6,
offset: const Offset(0, 2))
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Stack(
children: [
ClipRRect(
borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
child: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
? Image.network(data['imageUrl'] as String,
width: 130, height: 130, fit: BoxFit.cover)
: Container(
width: 130,
height: 130,
color: Colors.orange[50],
child: const Center(child: Text('🐾')),
),
),
Positioned(
top: 6,
left: 6,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.9),
borderRadius: BorderRadius.circular(10)),
child: Text(medal,
style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
),
),
if (isMine)
Positioned(
top: 6,
right: 6,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(
color: const Color(0xFFE8845A),
borderRadius: BorderRadius.circular(10)),
child: const Text('自分の投稿',
style: TextStyle(
fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
),
),
],
),
Padding(
padding: const EdgeInsets.all(8),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(data['petName'] ?? '',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Color(0xFF3D2B1F))),
  Text('$voteCount票',
      style: const TextStyle(fontSize: 11, color: Color(0xFFE8845A))),
],
),
),
],
),
),
);
},
);
},
);
}
}
class _MyPostsList extends StatelessWidget {
const _MyPostsList();

Future<void> _deletePost(BuildContext context, String postId) async {
final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('投稿を削除しますか？'),
content: const Text('この操作は取り消せません。'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text('削除'),
),
],
),
);
if (confirm == true) {
await FirebaseFirestore.instance
.collection('petBrags')
.doc(postId)
.delete();
}
}

@override
Widget build(BuildContext context) {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) {
return const Center(child: Text('ログインしてください'));
}

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('petBrags')
.where('uid', isEqualTo: myUid)
.orderBy('createdAt', descending: true)
.snapshots(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return Center(
child: Text('読み込みエラー: ${snapshot.error}',
style: const TextStyle(color: Colors.red)));
}
if (!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(color: Color(0xFFE8845A)));
}
final docs = snapshot.data!.docs;
if (docs.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(32),
child: Text('まだ投稿がありません',
style: TextStyle(color: Colors.grey)),
),
);
}
return ListView.builder(
padding: const EdgeInsets.all(16),
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: docs.length,
itemBuilder: (_, i) {
final data = docs[i].data() as Map<String, dynamic>;
final postId = docs[i].id;
final votes = data['votes'] as Map<String, dynamic>? ?? {};
final commentCount = data['commentCount'] ?? 0;
return GestureDetector(
onTap: () => showPostDetail(context, postId),
child: Container(
margin: const EdgeInsets.only(bottom: 16),
decoration: BoxDecoration(

color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 2))
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius:
const BorderRadius.vertical(top: Radius.circular(20)),
child: data['imageUrl'] != null &&
(data['imageUrl'] as String).isNotEmpty
? Image.network(data['imageUrl'] as String,
width: double.infinity,
height: 220,
fit: BoxFit.cover)
: Container(
width: double.infinity,
height: 220,
color: Colors.orange[50],
child: const Center(
child: Text('🐾', style: TextStyle(fontSize: 60))),
),
),
Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(data['petName'] ?? '',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
color: Color(0xFF3D2B1F))),
),
GestureDetector(
onTap: () => _deletePost(context, postId),
child: const Icon(Icons.delete_outline_rounded,
color: Colors.grey, size: 20),
),
],
),
const SizedBox(height: 4),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
borderRadius: BorderRadius.circular(12)),
child: Text(data['theme'] ?? '',
style: const TextStyle(
fontSize: 12, color: Color(0xFFE8845A))),
),
const SizedBox(height: 12),
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
_VoteButton(
emoji: '😍',
label: 'かわいい',
count: votes['kawaii'] ?? 0,
onTap: () => vote(context, postId, 'kawaii')),
_VoteButton(
emoji: '🤣',
label: 'おもしろい',
count: votes['omoshiroi'] ?? 0,
onTap: () => vote(context, postId, 'omoshiroi')),
_VoteButton(
emoji: '🥹',
label: '癒される',
count: votes['iyashi'] ?? 0,
onTap: () => vote(context, postId, 'iyashi')),
],
),
if (commentCount > 0) ...[
const SizedBox(height: 8),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.chat_bubble_outline_rounded,
size: 12, color: Colors.grey[400]),
const SizedBox(width: 4),
Text('$commentCount件のコメント',
style: TextStyle(
fontSize: 11, color: Colors.grey[400])),
],
),
],
],
),
),
],
),
),
);
},
);
},
);
}
}

class HomeFeedSection extends StatefulWidget {
  const HomeFeedSection({super.key});

  @override
  State<HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<HomeFeedSection>
    with SingleTickerProviderStateMixin {
late TabController _tabController;
int _currentTabIndex = 0;

@override
void initState() {
super.initState();
_tabController = TabController(length: 5, vsync: this);

_tabController.addListener(() {
if (!_tabController.indexIsChanging) {
setState(() => _currentTabIndex = _tabController.index);
}
});
}

@override
void dispose() {
_tabController.dispose();
super.dispose();
}

String get _todayDateKey {
final now = DateTime.now();
return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
Widget _buildMonthlyArea() {
final now = DateTime.now();
final theme = getCurrentMonthlyTheme(now);
if (!isMonthlyBestPeriod(now)) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
child: Row(
children: [
Text(theme.emoji, style: const TextStyle(fontSize: 24)),
const SizedBox(width: 8),
Expanded(
child: Text('今月のテーマ：${theme.title}',
style: const TextStyle(fontWeight: FontWeight.w600)),
),
_monthlyPostButton(theme.title),
],
),
);
} else {
return SizedBox(
height: 248,
child: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
child: Row(
children: [
Text(theme.emoji, style: const TextStyle(fontSize: 20)),
const SizedBox(width: 6),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('今月のベスト10',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
Text(theme.title,
style: TextStyle(fontSize: 11, color: Colors.grey[600])),
],
),
),
_monthlyPostButton(theme.title, small: true),
],
),
),
const Expanded(child: _MonthlyBestList()),
],
),
);
}
}

Widget _monthlyPostButton(String themeTitle, {bool small = false}) {
final myUid = FirebaseAuth.instance.currentUser?.uid;
final monthKey = getMonthlyThemeKey(DateTime.now());

return StreamBuilder<QuerySnapshot>(
stream: myUid == null
? null
: FirebaseFirestore.instance
.collection('petBrags')
.where('uid', isEqualTo: myUid)
.where('monthlyThemeKey', isEqualTo: monthKey)
.snapshots(),
builder: (context, snapshot) {
final checking = !snapshot.hasData;
final postedCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
final reachedLimit = postedCount >= 5;
return TextButton(
onPressed: checking || reachedLimit
? null
: () => _showMonthlyPostSheet(themeTitle),
child: Text(
reachedLimit ? '今月の投稿上限(5/5)' : '投稿する ($postedCount/5)',
style: TextStyle(
color: reachedLimit ? Colors.grey : const Color(0xFFE8845A),
fontWeight: FontWeight.bold,
fontSize: small ? 12 : 14),
),
);
},
);
}

void _showMonthlyPostSheet(String themeTitle) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _PostMonthlyBragSheet(
themeTitle: themeTitle,
onPosted: () => Navigator.pop(context),
),
),
);
}

void _showPostSheet(List<String> themes) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding:
EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: _PostBragSheet(
themes: themes,
dateKey: _todayDateKey,
onPosted: () {
Navigator.pop(context);
},
),
),
);
}
@override
Widget build(BuildContext context) {
final themes = getTodayThemes();

return Column(
children: [
_buildMonthlyArea(),
Padding(
padding: const EdgeInsets.all(16),
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFFE8845A), Color(0xFFFFCC80)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(20),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('今日のお題',
style: TextStyle(color: Colors.white70, fontSize: 12)),
const SizedBox(height: 8),
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: themes
      .map((t) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20)),
    child: Text(t,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13)),
  ))
      .toList(),
),
  const SizedBox(height: 16),
  StreamBuilder<QuerySnapshot>(
    stream: FirebaseAuth.instance.currentUser == null
        ? null
        : FirebaseFirestore.instance
        .collection('petBrags')
        .where('uid',
        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('dateKey', isEqualTo: _todayDateKey)
        .snapshots(),
    builder: (context, snapshot) {
      final checking = !snapshot.hasData;
      final postedToday =
          snapshot.hasData && snapshot.data!.docs.isNotEmpty;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: checking
              ? null
              : postedToday
              ? null
              : () => _showPostSheet(themes),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFE8845A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            disabledBackgroundColor: Colors.white.withOpacity(0.5),
          ),
          child: Text(
            postedToday ? '今日は投稿済みです ✓' : '投稿する 📸',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    },
  ),
],
),
),
),
  TabBar(
    controller: _tabController,
    labelColor: const Color(0xFFE8845A),
    unselectedLabelColor: Colors.grey,
    indicatorColor: const Color(0xFFE8845A),
    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    labelStyle: const TextStyle(fontSize: 12),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    tabs: const [
      Tab(text: 'おすすめ'),
      Tab(text: '新着'),
      Tab(text: '人気'),
      Tab(text: '週間ランキング'),
      Tab(text: 'マイ投稿'),
    ],
  ),

  if (_currentTabIndex != 4)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        _currentTabIndex == 0
            ? '※直近30日以内の投稿からランダムに表示されます'
            : _currentTabIndex == 3
            ? '※直近7日間の投稿が対象のランキングです'
            : '※直近30日以内の投稿が表示されます',
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
    ),
  Builder(
    builder: (context) {
      switch (_currentTabIndex) {
        case 0:
          return const _RecommendedList();
        case 1:
          return const _PetBragList(orderByField: 'createdAt');
        case 2:
          return const _PetBragList(orderByField: 'voteCount');
        case 3:
          return const _WeeklyRankingList();
        case 4:
          return const _MyPostsList();
        default:
          return const SizedBox();
      }
    },
  ),
],
);
}
}
