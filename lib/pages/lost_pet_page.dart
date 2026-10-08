import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import 'prefectures.dart';

Future<void> showLostPetPostSheet(BuildContext context) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;
  final mySnapshot = await FirebaseFirestore.instance
      .collection('lostPets')
      .where('uid', isEqualTo: myUid)
      .where('status', isEqualTo: 'lost')
      .get();
  if (mySnapshot.docs.length >= 5) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('公開できる投稿は5件までです。「見つかりました」にするか削除してから投稿してください。'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const _LostPetPostSheet(),
    ),
  );
}

Future<void> _reportLostPost(BuildContext context, String postId, String targetUid) async {
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
          ...['虚偽の情報', '不適切なコンテンツ', 'スパム', 'その他'].map((r) =>
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
    'type': 'lostPet',
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

void showLostPetDetail(BuildContext context, Map<String, dynamic> data, String postId) {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final isMine = myUid == data['uid'];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
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
                color: const Color(0xFF3498DB).withOpacity(0.1),
                child: Center(child: Text(data['emoji'] ?? '🐾', style: const TextStyle(fontSize: 60))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isMine)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(10)),
                          child: const Text('自分の投稿',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (data['urgent'] == true)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: const Text('緊急',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (data['isOrganization'] == true)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(10)),
                          child: const Text('団体',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),

                      _StatusBadge(status: data['status'] ?? 'lost'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(data['petName'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 4),
                  Text(data['animalType'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const Divider(height: 32),
                  _InfoRow(Icons.location_on_rounded, data['location'] ?? ''),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.calendar_today_rounded, data['date'] ?? ''),
                  if ((data['reward'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(Icons.card_giftcard_rounded, 'お礼：${data['reward']}'),
                  ],
                  const SizedBox(height: 20),
                  if ((data['description'] ?? '').toString().isNotEmpty) ...[
                    const Text('詳細', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(data['description'], style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF3498DB).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('連絡先', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                            (data['contact'] ?? '').toString().isNotEmpty
                                ? data['contact']
                                : '投稿者：${data['posterName'] ?? ''}',
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final newStatus = data['status'] == 'resolved' ? 'lost' : 'resolved';
                          await FirebaseFirestore.instance
                              .collection('lostPets')
                              .doc(postId)
                              .update({'status': newStatus});
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF2D6A4F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(
                            data['status'] == 'resolved' ? '「未解決」に戻す' : '「見つかりました」にする',
                            style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: const Text('削除'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance.collection('lostPets').doc(postId).delete();
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        label: const Text('削除する', style: TextStyle(color: Colors.red)),

                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _reportLostPost(context, postId, data['uid'] ?? '');
                        },
                        icon: const Icon(Icons.flag_outlined, color: Colors.grey, size: 18),
                        label: const Text('この投稿を通報する', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LostPetPage extends StatefulWidget {
  final String? initialPostId;
  const LostPetPage({super.key, this.initialPostId});

  @override
  State<LostPetPage> createState() => _LostPetPageState();
}

class _LostPetPageState extends State<LostPetPage> {
  String _filter = 'all';
  bool _hasOpenedInitial = false;

  Future<void> _openInitialPost() async {
    if (widget.initialPostId == null || _hasOpenedInitial) return;
    _hasOpenedInitial = true;
    final doc = await FirebaseFirestore.instance
        .collection('lostPets')
        .doc(widget.initialPostId)
        .get();
    if (doc.exists && mounted) {
      showLostPetDetail(context, doc.data() as Map<String, dynamic>, doc.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialPost());
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(

        title: const Text('迷子情報 🔍',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => showLostPetPostSheet(context),
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF3498DB), size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'すべて', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  _FilterChip(label: '迷子中', value: 'lost', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  _FilterChip(label: '見つかりました', value: 'resolved', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  _FilterChip(label: '緊急', value: 'urgent', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  _FilterChip(label: 'マイ投稿', value: 'mine', selected: _filter, onTap: (v) => setState(() => _filter = v)),

                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lostPets')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3498DB)));
                }
                final myUid = FirebaseAuth.instance.currentUser?.uid;
                var docs = snapshot.data!.docs;
                if (_filter == 'urgent') {
                  docs = docs.where((d) => (d.data() as Map<String, dynamic>)['urgent'] == true).toList();
                } else if (_filter == 'mine') {
                  docs = docs.where((d) => (d.data() as Map<String, dynamic>)['uid'] == myUid).toList();
                } else if (_filter != 'all') {
                  docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == _filter).toList();
                }

                if (docs.isEmpty) {

                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('該当する投稿はありません', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final postId = docs[i].id;
                    final isMinePost = data['uid'] == myUid;
                    return GestureDetector(
                      onTap: () => showLostPetDetail(context, data, postId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isMinePost ? const Color(0xFF3498DB).withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: isMinePost
                              ? Border.all(color: const Color(0xFF3498DB), width: 1.5)
                              : data['urgent'] == true ? Border.all(color: Colors.red[300]!) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
                                    ? Image.network(data['imageUrl'] as String, width: 80, height: 80, fit: BoxFit.cover)
                                    : Container(
                                  width: 80, height: 80,
                                  color: const Color(0xFF3498DB).withOpacity(0.1),
                                  child: Center(child: Text(data['emoji'] ?? '🐾', style: const TextStyle(fontSize: 32))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isMinePost)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('自分の投稿', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        if (data['isOrganization'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('団体', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),

                                        if (data['urgent'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                            child: const Text('緊急', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        _StatusBadge(status: data['status'] ?? 'lost'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(data['petName'] ?? '',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(data['location'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFF3498DB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? const Color(0xFF3498DB) : Colors.grey[300]!)),
        child: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: isResolved ? const Color(0xFF2D6A4F) : const Color(0xFF3498DB),
          borderRadius: BorderRadius.circular(8)),
      child: Text(isResolved ? '見つかりました' : '迷子中',
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3498DB)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
      ],
    );
  }
}
class _LostPetPostSheet extends StatefulWidget {
  const _LostPetPostSheet();

  @override
  State<_LostPetPostSheet> createState() => _LostPetPostSheetState();
}

class _LostPetPostSheetState extends State<_LostPetPostSheet> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isPosting = false;
  final _petNameCtrl = TextEditingController();
  final _animalTypeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  bool _urgent = false;
  String? _selectedArea;


  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _submit() async {
    if (_petNameCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ペットの名前・特徴・場所・都道府県は必須です')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final orgDoc = await FirebaseFirestore.instance.collection('organizations').doc(user.uid).get();
    final isOrg = orgDoc.exists;
    final myName = isOrg
        ? (orgDoc.data()?['name'] as String? ?? '団体')
        : (userDoc.data()?['name'] as String? ?? '名無しさん');

    await FirebaseFirestore.instance.collection('lostPets').add({
      'uid': user.uid,
      'posterName': myName,
      'isOrganization': isOrg,
      'petName': _petNameCtrl.text.trim(),
      'animalType': _animalTypeCtrl.text.trim(),
      'emoji': '🐾',
      'location': _locationCtrl.text.trim(),
      'area': _selectedArea ?? '',
      'date': _dateCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
      'reward': _rewardCtrl.text.trim(),
      'imageUrl': _imageUrl ?? '',
      'status': 'lost',
      'urgent': _urgent,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('迷子・保護情報を投稿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(color: const Color(0xFF3498DB).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3498DB)))
                  : _imageUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_imageUrl!, width: double.infinity, fit: BoxFit.cover))
                  : const Center(child: Text('📸 写真を選ぶ', style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _petNameCtrl, maxLength: 20, decoration: InputDecoration(labelText: 'ペットの名前・特徴 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _animalTypeCtrl, maxLength: 30, decoration: InputDecoration(labelText: '動物の種類（犬・猫など）', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _locationCtrl, maxLength: 50, decoration: InputDecoration(labelText: '場所 *', hintText: '例：京都市左京区 周辺', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          const Text('都道府県（どうぶつマップに表示されます） *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefectures.map((pref) {
              final sel = _selectedArea == pref;
              return GestureDetector(
                onTap: () => setState(() => _selectedArea = pref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF3498DB) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref,
                      style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(controller: _dateCtrl, maxLength: 30, decoration: InputDecoration(labelText: '日時', hintText: '例：2026年7月20日 午前中', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _descriptionCtrl, maxLines: 4, maxLength: 500, decoration: InputDecoration(labelText: '詳細（特徴・状況など）', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _contactCtrl, maxLength: 100, decoration: InputDecoration(labelText: '連絡先', hintText: '電話番号・SNSアカウントなど', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _rewardCtrl, maxLength: 30, decoration: InputDecoration(labelText: 'お礼（任意）', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(value: _urgent, activeColor: Colors.red, onChanged: (v) => setState(() => _urgent = v ?? false)),
              const Text('緊急（至急探しています）'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
            child: const Text('⚠️ 個人情報の取り扱いにはご注意ください。連絡先は必要な範囲でご記入ください。',
                style: TextStyle(fontSize: 12, color: Colors.orange)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
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