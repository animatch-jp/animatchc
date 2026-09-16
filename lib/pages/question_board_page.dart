import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

const List<Map<String, String>> questionCategories = [
  {'key': 'hospital', 'label': '病院・健康', 'emoji': '🏥'},
  {'key': 'training', 'label': 'しつけ・行動', 'emoji': '🐾'},
  {'key': 'adoption', 'label': '里親・保護活動', 'emoji': '🏠'},
  {'key': 'care', 'label': 'エサ・お世話', 'emoji': '🍚'},
  {'key': 'other', 'label': 'その他', 'emoji': '💬'},
];

String categoryLabel(String key) {
  final match = questionCategories.firstWhere(
        (c) => c['key'] == key,
    orElse: () => {'label': 'その他', 'emoji': '💬'},
  );
  return '${match['emoji']} ${match['label']}';
}

class QuestionBoardPage extends StatefulWidget {
  const QuestionBoardPage({super.key});

  @override
  State<QuestionBoardPage> createState() => _QuestionBoardPageState();
}

class _QuestionBoardPageState extends State<QuestionBoardPage> {
  final Set<String> _selectedCategories = {};
  bool _onlyUnsolved = false;

void _showPostSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
child: const _PostQuestionSheet(),
),
);
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF8F5),
    appBar: AppBar(
      title: const Text('質問掲示板 💬',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
      backgroundColor: const Color(0xFFFFF8F5),
      elevation: 0,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('ちょっとした困りごと、みんなに聞いてみよう',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip('すべて', null),
                ...questionCategories.map((c) => _categoryChip('${c['emoji']} ${c['label']}', c['key'])),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Checkbox(
                value: _onlyUnsolved,
                onChanged: (v) => setState(() => _onlyUnsolved = v ?? false),
                activeColor: const Color(0xFFE8845A),
              ),
              const Text('未解決の質問のみ表示', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: _QuestionList(categories: _selectedCategories, onlyUnsolved: _onlyUnsolved),
        ),

      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showPostSheet,
      backgroundColor: const Color(0xFFE8845A),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('質問する', style: TextStyle(color: Colors.white)),
    ),
  );
}

  Widget _categoryChip(String label, String? key) {
    final sel = key == null ? _selectedCategories.isEmpty : _selectedCategories.contains(key);
    return GestureDetector(
      onTap: () => setState(() {
        if (key == null) {
          _selectedCategories.clear();
        } else if (_selectedCategories.contains(key)) {
          _selectedCategories.remove(key);
        } else {
          _selectedCategories.add(key);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFFE8845A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: sel ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

}
class _QuestionList extends StatelessWidget {
  final Set<String> categories;
  final bool onlyUnsolved;
  const _QuestionList({required this.categories, required this.onlyUnsolved});

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = (timestamp as Timestamp).toDate();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8845A)));
        }
        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (categories.isNotEmpty && !categories.contains(data['category'])) return false;
          if (onlyUnsolved && data['solved'] == true) return false;
          return true;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('質問がまだありません。最初の質問をしてみましょう', style: TextStyle(color: Colors.grey[500])),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final questionId = docs[i].id;
            final solved = data['solved'] == true;

            return GestureDetector(
              onTap: () => showQuestionDetail(context, questionId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((data['imageUrl'] ?? '').toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(data['imageUrl'], width: 40, height: 40, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE8845A).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(categoryLabel(data['category'] ?? 'other'),
                                        style: const TextStyle(fontSize: 10, color: Color(0xFFE8845A))),
                                  ),
                                  const Spacer(),
                                  if (solved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(8)),
                                      child: const Text('解決済み', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(data['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3D2B1F))),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(data['body'] ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(_timeAgo(data['createdAt']), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        const Spacer(),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('questions')
                              .doc(questionId)
                              .collection('answers')
                              .snapshots(),
                          builder: (context, answerSnap) {
                            final count = answerSnap.hasData ? answerSnap.data!.docs.length : 0;
                            return Text('💬 $count件の回答', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                          },
                        ),
                      ],
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
class _PostQuestionSheet extends StatefulWidget {
  const _PostQuestionSheet();

  @override
  State<_PostQuestionSheet> createState() => _PostQuestionSheetState();
}

class _PostQuestionSheetState extends State<_PostQuestionSheet> {
final _titleCtrl = TextEditingController();
final _bodyCtrl = TextEditingController();
String? _selectedCategory;
String? _imageUrl;
bool _isUploading = false;
bool _isPosting = false;

Future<void> _pickImage() async {
setState(() => _isUploading = true);
final url = await CloudinaryService.pickAndUploadImage();
setState(() {
if (url != null) _imageUrl = url;
_isUploading = false;
});
}

Future<void> _submit() async {
if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty || _selectedCategory == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('タイトル・内容・カテゴリを入力してください'), backgroundColor: Colors.red),
);
return;
}

final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) return;

setState(() => _isPosting = true);

final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
final myName = userDoc.data()?['name'] as String? ?? '名無しさん';

await FirebaseFirestore.instance.collection('questions').add({
'uid': myUid,
'name': myName,
'title': _titleCtrl.text.trim(),
'body': _bodyCtrl.text.trim(),
'category': _selectedCategory,
'imageUrl': _imageUrl ?? '',
'solved': false,
'createdAt': FieldValue.serverTimestamp(),
});

if (mounted) {
Navigator.pop(context);
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
        const Text('質問する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: questionCategories.map((c) {
            final sel = _selectedCategory == c['key'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = c['key']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE8845A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${c['emoji']} ${c['label']}',
                    style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'タイトル（例：夜間、猫が急に元気がない）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        TextField(
          controller: _bodyCtrl,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: '詳しい内容',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(14),
              image: _imageUrl != null ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover) : null,
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845A)))
                : (_imageUrl == null
                ? const Center(child: Text('📷 写真を追加（任意）', style: TextStyle(color: Colors.grey)))
                : null),
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
                : const Text('質問を投稿する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
}
void showQuestionDetail(BuildContext context, String questionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('questions').doc(questionId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('この質問は削除されました', style: TextStyle(color: Colors.grey))),
            );
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          final isMine = data['uid'] == myUid;
          final solved = data['solved'] == true;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE8845A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(categoryLabel(data['category'] ?? 'other'),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFE8845A))),
                            ),
                            const Spacer(),
                            if (solved)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(10)),
                                child: const Text('解決済み', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(data['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 8),
                        Text(data['name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        if ((data['imageUrl'] ?? '').toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(data['imageUrl'], width: double.infinity, height: 240, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text(data['body'] ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
                        const SizedBox(height: 16),
                        if (isMine && !solved)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('questions').doc(questionId).update({'solved': true});
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F), side: const BorderSide(color: Color(0xFF2D6A4F))),
                              child: const Text('解決済みにする'),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Text('回答', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _AnswerList(questionId: questionId, questionOwnerUid: data['uid'] ?? ''),
                      ],
                    ),
                  ),
                ),
                _AnswerInputBar(
                  questionId: questionId,
                  questionOwnerUid: data['uid'] ?? '',
                  questionTitle: data['title'] ?? '',
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
class _AnswerList extends StatelessWidget {
  final String questionId;
  final String questionOwnerUid;
  const _AnswerList({required this.questionId, required this.questionOwnerUid});

  Future<void> _toggleHelpful(String answerId, List<dynamic> helpfulBy, String myUid) async {
    final ref = FirebaseFirestore.instance
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .doc(answerId);
    if (helpfulBy.contains(myUid)) {
      await ref.update({'helpfulBy': FieldValue.arrayRemove([myUid])});
    } else {
      await ref.update({'helpfulBy': FieldValue.arrayUnion([myUid])});
    }
  }

  Future<void> _deleteAnswer(String answerId) async {
    await FirebaseFirestore.instance
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .doc(answerId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .collection('answers')
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
            child: Text('まだ回答がありません。最初に答えてみましょう', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isMine = data['uid'] == myUid;
            final helpfulBy = List<dynamic>.from(data['helpfulBy'] ?? []);
            final isHelpful = myUid != null && helpfulBy.contains(myUid);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(data['text'] ?? '', style: const TextStyle(fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                      if (isMine)
                        GestureDetector(
                          onTap: () => _deleteAnswer(doc.id),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: myUid == null ? null : () => _toggleHelpful(doc.id, helpfulBy, myUid),
                    child: Row(
                      children: [
                        Icon(
                          isHelpful ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                          size: 14,
                          color: isHelpful ? const Color(0xFFE8845A) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('役に立った${helpfulBy.isNotEmpty ? ' (${helpfulBy.length})' : ''}',
                            style: TextStyle(fontSize: 11, color: isHelpful ? const Color(0xFFE8845A) : Colors.grey)),
                      ],
                    ),
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
class _AnswerInputBar extends StatefulWidget {
  final String questionId;
  final String questionOwnerUid;
  final String questionTitle;
  const _AnswerInputBar({
    required this.questionId,
    required this.questionOwnerUid,
    required this.questionTitle,
  });

  @override
  State<_AnswerInputBar> createState() => _AnswerInputBarState();
}

class _AnswerInputBarState extends State<_AnswerInputBar> {
  final _answerCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _isSending = true);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final myName = userDoc.data()?['name'] as String? ?? '名無しさん';

    await FirebaseFirestore.instance
        .collection('questions')
        .doc(widget.questionId)
        .collection('answers')
        .add({
      'uid': myUid,
      'name': myName,
      'text': text,
      'helpfulBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (widget.questionOwnerUid != myUid) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.questionOwnerUid)
          .collection('items')
          .add({
        'type': 'chat',
        'emoji': '💬',
        'title': '質問に回答がつきました',
        'desc': '「${widget.questionTitle}」に $myName さんが回答しました',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _answerCtrl.clear();
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
                controller: _answerCtrl,
                decoration: InputDecoration(
                  hintText: '回答する',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _sendAnswer,
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
