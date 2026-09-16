import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pet_brag_page.dart';


class PetDetailPage extends StatefulWidget {
  final String uid;
  final String petId;
  final String petName;
  final String petType;
  final String petAge;
  final String petBio;
  final List<String> petTags;
  final String? petImageUrl;

  const PetDetailPage({
    super.key,
    required this.uid,
    required this.petId,
    required this.petName,
    required this.petType,
    required this.petAge,
    required this.petBio,
    required this.petTags,
    this.petImageUrl,
  });

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
String get _todayKey {
final now = DateTime.now();
return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

void _showAddTaskSheet() {
final nameCtrl = TextEditingController();
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('お世話タスクを追加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
TextField(
controller: nameCtrl,
decoration: InputDecoration(
hintText: '例：ごはん、お薬、散歩',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
),
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () async {
if (nameCtrl.text.trim().isEmpty) return;
await FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.collection('pets')
.doc(widget.petId)
.collection('tasks')
.add({
'name': nameCtrl.text.trim(),
'createdAt': FieldValue.serverTimestamp(),
});
if (context.mounted) Navigator.pop(context);
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFE8845A),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
padding: const EdgeInsets.symmetric(vertical: 14),
),
child: const Text('追加する', style: TextStyle(fontWeight: FontWeight.bold)),
),
),
const SizedBox(height: 20),
],
),
),
);
}

Future<void> _toggleTaskDone(String taskId, bool currentlyDone) async {
final ref = FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.collection('pets')
.doc(widget.petId)
.collection('tasks')
.doc(taskId)
.collection('logs')
.doc(_todayKey);

if (currentlyDone) {
await ref.delete();
} else {
await ref.set({'doneAt': FieldValue.serverTimestamp()});
}
}

Future<void> _deleteTask(String taskId) async {
await FirebaseFirestore.instance
.collection('users')
.doc(widget.uid)
.collection('pets')
.doc(widget.petId)
.collection('tasks')
.doc(taskId)
.delete();
}
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFFFF8F5),
appBar: AppBar(
title: Text('${widget.petName} のページ 🐾',
style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
backgroundColor: const Color(0xFFFFF8F5),
elevation: 0,
),
body: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(24),
decoration: const BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
child: Column(
children: [
Container(
width: 100, height: 100,
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.15),
shape: BoxShape.circle),
child: widget.petImageUrl != null && widget.petImageUrl!.isNotEmpty
? ClipOval(
child: Image.network(widget.petImageUrl!,
width: 100, height: 100, fit: BoxFit.cover))
: const Center(child: Text('🐾', style: TextStyle(fontSize: 44))),
),
const SizedBox(height: 12),
Text(widget.petName,
style: const TextStyle(
fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
const SizedBox(height: 4),
Text('${widget.petType}${widget.petAge.isNotEmpty ? ' ・ ${widget.petAge}' : ''}',
style: TextStyle(fontSize: 13, color: Colors.grey[600])),
if (widget.petBio.isNotEmpty) ...[
const SizedBox(height: 10),
Text(widget.petBio,
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 14, height: 1.5)),
],
if (widget.petTags.isNotEmpty) ...[
const SizedBox(height: 12),
Wrap(
spacing: 8, runSpacing: 8,
alignment: WrapAlignment.center,
children: widget.petTags.map((tag) => Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: const Color(0xFFE8845A).withOpacity(0.1),
borderRadius: BorderRadius.circular(12)),
child: Text(tag,
style: const TextStyle(fontSize: 11, color: Color(0xFFE8845A))),
)).toList(),
),
],
],
),
),
  Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF2D6A4F).withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('今日のお世話',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
              ],
            ),
            GestureDetector(
              onTap: _showAddTaskSheet,
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFE8845A)),
                  SizedBox(width: 4),
                  Text('追加', style: TextStyle(fontSize: 12, color: Color(0xFFE8845A))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('pets')
              .doc(widget.petId)
              .collection('tasks')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: Color(0xFFE8845A)),
              );
            }
            final tasks = snapshot.data!.docs;
            if (tasks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('ごはんやお薬など、お世話のタスクを登録できます',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              );
            }
            return Column(
              children: tasks.map((task) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: task.reference.collection('logs').doc(_todayKey).snapshots(),
                  builder: (context, logSnap) {
                    final done = logSnap.hasData && logSnap.data!.exists;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleTaskDone(task.id, done),
                            child: Icon(
                              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: done ? const Color(0xFF2D6A4F) : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (task.data() as Map<String, dynamic>)['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  color: done ? Colors.grey[500] : const Color(0xFF3D2B1F)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _deleteTask(task.id),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  ),

  Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text('これまでの投稿',
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
  ),
  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('petBrags')
        .where('uid', isEqualTo: widget.uid)
        .where('petName', isEqualTo: widget.petName)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text('投稿を読み込めませんでした\n${snapshot.error}',
              style: TextStyle(color: Colors.red[300], fontSize: 12)),
        );
      }
      if (!snapshot.hasData) {

        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
        );
      }
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text('まだ${widget.petName}の投稿はありません',
                  style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                  label: const Text('ペット自慢を投稿する',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          final imageUrl = data['imageUrl'] as String?;
          return GestureDetector(
            onTap: () {
              if (imageUrl == null || imageUrl.isEmpty) return;
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.95,
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                  color: Colors.orange[50],
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 32)))),
            ),
          );
        },
      );


    },
  ),
  const SizedBox(height: 24),
],
),
),
);
}
}
