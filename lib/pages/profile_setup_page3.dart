import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import 'root_page.dart';

class _PetDraft {
  String name;
  String type;
  String age;
  String bio;
  List<String> tags;
  String? imageUrl;

  _PetDraft({
    required this.name,
    required this.type,
    this.age = '',
    this.bio = '',
    this.tags = const [],
    this.imageUrl,
  });
}

class ProfileSetupPage3 extends StatefulWidget {
  const ProfileSetupPage3({super.key});

  @override
  State<ProfileSetupPage3> createState() => _ProfileSetupPage3State();
}

class _ProfileSetupPage3State extends State<ProfileSetupPage3> {
  final List<_PetDraft> _pets = [];
  bool _isLoading = false;

  static const _main = Color(0xFFE8845A);
  static const _bg = Color(0xFFFFF8F5);

  void _skip() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootPage()),
          (route) => false,
    );
  }

  void _openAddPetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PetFormSheet(
          onSave: (draft) {
            setState(() => _pets.add(draft));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _removePet(int index) {
    setState(() => _pets.removeAt(index));
  }

  Future<void> _saveAndStart() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      for (final pet in _pets) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('pets')
            .add({
          'name': pet.name,
          'type': pet.type,
          'age': pet.age,
          'bio': pet.bio,
          'tags': pet.tags,
          'imageUrl': pet.imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'STEP 3 / 3',
          style: TextStyle(
              color: Color(0xFF3D2B1F), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('スキップ',
                style: TextStyle(color: Color(0xFF888888))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ペットを登録しよう🐾',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '何匹でも追加できます。あとから変更もOK！',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 24),

                  // 追加済みペット一覧
                  ..._pets.asMap().entries.map((entry) {
                    final i = entry.key;
                    final pet = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: pet.imageUrl != null &&
                                pet.imageUrl!.isNotEmpty
                                ? Image.network(pet.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover)
                                : Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFFFE0D0),
                                child: const Center(
                                    child: Text('🐾',
                                        style: TextStyle(
                                            fontSize: 28)))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${pet.name}（${pet.type}）',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D2B1F)),
                                ),
                                if (pet.age.isNotEmpty)
                                  Text(pet.age,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                if (pet.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    children: pet.tags
                                        .map((tag) => Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 8,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _main
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(
                                            8),
                                      ),
                                      child: Text(tag,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: _main)),
                                    ))
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removePet(i),
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.red, size: 20),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ペット追加ボタン
                  GestureDetector(
                    onTap: _openAddPetSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _main.withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_rounded,
                              color: Color(0xFFE8845A)),
                          SizedBox(width: 8),
                          Text('ペットを追加する',
                              style: TextStyle(
                                  color: Color(0xFFE8845A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 下部ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _pets.isEmpty ? _skip : _saveAndStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _main,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                child: Text(
                  _pets.isEmpty
                      ? 'スキップしてはじめる'
                      : '${_pets.length}匹登録してはじめる🐾',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _PetFormSheet extends StatefulWidget {
  final Function(_PetDraft) onSave;
  const _PetFormSheet({required this.onSave});

  @override
  State<_PetFormSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends State<_PetFormSheet> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  List<String> _selectedTags = [];
  String? _imageUrl;
  bool _isUploading = false;

  static const _main = Color(0xFFE8845A);
  static const _green = Color(0xFF2D6A4F);

  final List<String> _animalTypes = [
    '犬', '猫', 'ハムスター', 'うさぎ', '爬虫類', '鳥', 'シマリス', 'モルモット', 'その他'
  ];

  final List<String> _tagOptions = [
    '元気', '人懐っこい', 'おっとり', 'やんちゃ', '甘えん坊',
    '独立心強い', '賢い', '遊び好き', '食いしん坊', 'ビビリ',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画像のアップロードに失敗しました。もう一度お試しください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ペットを追加',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 写真
          Center(
            child: GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0D0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isUploading
                        ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFE8845A)))
                        : _imageUrl != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_imageUrl!,
                            width: 80, height: 80, fit: BoxFit.cover))
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            color: Color(0xFFE8845A), size: 24),
                        Text('写真',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE8845A))),
                      ],
                    ),
                  ),
                  if (_imageUrl != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8845A),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 名前
          TextField(
              controller: _nameCtrl, decoration: _dec('ペットの名前 *')),
          const SizedBox(height: 12),

          // 動物の種類
          Autocomplete<String>(
            optionsBuilder: (value) {
              if (value.text.isEmpty) return const [];
              return _animalTypes.where((t) => t.contains(value.text));
            },
            onSelected: (value) => _typeCtrl.text = value,
            fieldViewBuilder: (context, controller, focusNode, _) {
              controller.text = _typeCtrl.text;
              controller
                  .addListener(() => _typeCtrl.text = controller.text);
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: _dec('動物の種類 *（例：猫・ヒョウモントカゲモドキ）'),
              );
            },
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(options.elementAt(i)),
                      onTap: () => onSelected(options.elementAt(i)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 年齢
          TextField(
              controller: _ageCtrl,
              decoration: _dec('年齢（例：2歳・生後3ヶ月）')),
          const SizedBox(height: 12),

          // 一言紹介
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 100,
            decoration: _dec('一言紹介'),
          ),
          const SizedBox(height: 8),

          // タグ
          const Text('性格タグ（複数選択OK）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagOptions.map((tag) {
              final sel = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selectedTags.remove(tag)
                    : _selectedTags.add(tag)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? _green : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                          sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 追加ボタン
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty ||
                    _typeCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('名前と動物の種類は必須です')),
                  );
                  return;
                }
                widget.onSave(_PetDraft(
                  name: _nameCtrl.text.trim(),
                  type: _typeCtrl.text.trim(),
                  age: _ageCtrl.text.trim(),
                  bio: _bioCtrl.text.trim(),
                  tags: List.from(_selectedTags),
                  imageUrl: _imageUrl,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _main,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('追加する',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8845A))),
  );
}
