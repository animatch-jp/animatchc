import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'organization_profile_page.dart';
import 'lost_pet_page.dart';
import 'volunteer_page.dart';
import 'hospital_tags.dart';
import 'prefectures.dart';
import 'adoption_page.dart';



class AnimalMapPage extends StatefulWidget {
  const AnimalMapPage({super.key});

  @override
  State<AnimalMapPage> createState() => _AnimalMapPageState();
}

class _AnimalMapPageState extends State<AnimalMapPage> {
String _category = 'all';
String? _hospitalAnimalFilter;
String? _hospitalAreaFilter;
final Set<String> _hospitalFacilityFilters = {};

Widget _categoryChip(String value, String label) {
final sel = _category == value;
return GestureDetector(
onTap: () => setState(() => _category = value),
child: Container(
margin: const EdgeInsets.only(right: 8),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: sel ? const Color(0xFF2D6A4F) : Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: sel
? []
: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
child: Text(label,
style: TextStyle(
fontSize: 13,
color: sel ? Colors.white : Colors.grey[700],
fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
),
);
}

Widget _subChip(String label, bool selected, VoidCallback onTap, {bool facility = false}) {
return GestureDetector(
onTap: onTap,
child: Container(
margin: const EdgeInsets.only(right: 6),
padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
decoration: BoxDecoration(
color: selected
? (facility ? const Color(0xFF2D6A4F) : const Color(0xFF4DA8DA))
: (facility ? const Color(0xFF2D6A4F).withOpacity(0.08) : Colors.grey[100]),
borderRadius: BorderRadius.circular(14)),
child: Text(label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: selected
? Colors.white
: (facility ? const Color(0xFF2D6A4F) : Colors.grey[700]))),
),
);
}

Widget _summaryItem(String label, Stream<QuerySnapshot> stream) {
return Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: stream,
builder: (context, snapshot) {
final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
return Container(
margin: const EdgeInsets.symmetric(horizontal: 3),
padding: const EdgeInsets.symmetric(vertical: 10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)]),
child: Column(
children: [
Text('$count',
style: const TextStyle(
fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE8845A))),
const SizedBox(height: 2),
Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
],
),
);
},
),
);
}

Widget _impactStat(String emoji, String count, String label) {
  return Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    ],
  );
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFFFF8F5),
appBar: AppBar(
title: const Text('どうぶつマップ 🐾',
style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
backgroundColor: const Color(0xFFFFF8F5),
elevation: 0,
),
body: Column(
children: [
const Padding(
padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
child: Text('団体・迷子情報・ボランティア・病院をまとめて探せます',
style: TextStyle(fontSize: 12, color: Colors.grey)),
),
if (_category == 'all')
Padding(
padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
child: Row(
children: [
_summaryItem('団体', FirebaseFirestore.instance.collection('organizations').where('status', isEqualTo: 'approved').snapshots()),
_summaryItem('迷子情報', FirebaseFirestore.instance.collection('lostPets').where('status', isEqualTo: 'lost').snapshots()),
_summaryItem('ボランティア', FirebaseFirestore.instance.collection('volunteers').where('status', isEqualTo: 'open').snapshots()),
_summaryItem('病院', FirebaseFirestore.instance.collection('hospitals').where('status', isEqualTo: 'approved').snapshots()),
],
),
),
  if (_category == 'all')
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐾 AniMatchのこれまで',
                style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('adoptions')
                      .where('status', isEqualTo: 'adopted')
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return _impactStat('🏠', '$count', '里親決定');
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lostPets')
                      .where('status', isEqualTo: 'resolved')
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return _impactStat('🔍', '$count', '再会できた');
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('interested')
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return _impactStat('🤝', '$count', 'ボランティア興味');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),

Padding(
padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
child: SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
  children: [
    _categoryChip('all', 'すべて'),
    _categoryChip('org', '🏠 団体'),
    _categoryChip('adoption', '🐾 里親'),
    _categoryChip('lost', '🔍 迷子情報'),
    _categoryChip('volunteer', '🤝 ボランティア'),
    _categoryChip('hospital', '🏥 動物病院'),
  ],

),
),
),
if (_category == 'hospital')
Container(
margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('都道府県', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('すべて', _hospitalAreaFilter == null, () => setState(() => _hospitalAreaFilter = null)),
...prefectures.map((p) => _subChip(p, _hospitalAreaFilter == p, () => setState(() => _hospitalAreaFilter = _hospitalAreaFilter == p ? null : p))),
],
),
),
const SizedBox(height: 10),
Text('対応動物', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('すべての動物', _hospitalAnimalFilter == null, () => setState(() => _hospitalAnimalFilter = null)),
...hospitalAnimalTags.map((t) => _subChip(t, _hospitalAnimalFilter == t, () => setState(() => _hospitalAnimalFilter = _hospitalAnimalFilter == t ? null : t))),
],
),
),
const SizedBox(height: 10),
Text('診療体制', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('✅ 新規受付中', _hospitalFacilityFilters.contains('acceptingNew'), () => setState(() => _hospitalFacilityFilters.contains('acceptingNew') ? _hospitalFacilityFilters.remove('acceptingNew') : _hospitalFacilityFilters.add('acceptingNew')), facility: true),
_subChip('🏨 入院あり', _hospitalFacilityFilters.contains('hasInpatient'), () => setState(() => _hospitalFacilityFilters.contains('hasInpatient') ? _hospitalFacilityFilters.remove('hasInpatient') : _hospitalFacilityFilters.add('hasInpatient')), facility: true),
_subChip('🔬 CT設備', _hospitalFacilityFilters.contains('hasCT'), () => setState(() => _hospitalFacilityFilters.contains('hasCT') ? _hospitalFacilityFilters.remove('hasCT') : _hospitalFacilityFilters.add('hasCT')), facility: true),
_subChip('🌙 夜間対応', _hospitalFacilityFilters.contains('hasNightCare'), () => setState(() => _hospitalFacilityFilters.contains('hasNightCare') ? _hospitalFacilityFilters.remove('hasNightCare') : _hospitalFacilityFilters.add('hasNightCare')), facility: true),
],
),
),
],
),
),
  Expanded(
    child: _category == 'all'
        ? const _TimelineList()
        : ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (_category == 'org') const _OrgList(),
        if (_category == 'adoption') const _AdoptionList(),
        if (_category == 'lost') const _LostList(),
        if (_category == 'volunteer') const _VolunteerList(),
        if (_category == 'hospital')
          _HospitalList(
            animalFilter: _hospitalAnimalFilter,
            areaFilter: _hospitalAreaFilter,
            facilityFilters: _hospitalFacilityFilters,
          ),
      ],

    ),
  ),
],
),
  floatingActionButton: _category == 'lost'
      ? FloatingActionButton.extended(
    onPressed: () => showLostPetPostSheet(context),
    backgroundColor: const Color(0xFF3498DB),
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text('投稿する', style: TextStyle(color: Colors.white)),
  )
      : null,

);
}
}
class _TimelineList extends StatelessWidget {

  const _TimelineList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lostPets')
          .where('status', isEqualTo: 'lost')
          .orderBy('createdAt', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, lostSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('volunteers')
              .where('status', isEqualTo: 'open')
              .orderBy('createdAt', descending: true)
              .limit(15)
              .snapshots(),
          builder: (context, volSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('organizations')
                  .where('status', isEqualTo: 'approved')
                  .orderBy('createdAt', descending: true)
                  .limit(15)
                  .snapshots(),
              builder: (context, orgSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hospitals')
                      .where('status', isEqualTo: 'approved')
                      .orderBy('createdAt', descending: true)
                      .limit(15)
                      .snapshots(),
                  builder: (context, hospSnap) {
                    if (!lostSnap.hasData || !volSnap.hasData || !orgSnap.hasData || !hospSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8845A)));
                    }

                    final items = <_TimelineItem>[];

                    for (final d in lostSnap.data!.docs) {
                      final data = d.data() as Map<String, dynamic>;
                      items.add(_TimelineItem('lost', '🔍', const Color(0xFF3498DB),
                          data['petName'] ?? '', data['createdAt'], d.id, data));
                    }
                    for (final d in volSnap.data!.docs) {
                      final data = d.data() as Map<String, dynamic>;
                      items.add(_TimelineItem('volunteer', '🤝', const Color(0xFFE8845A),
                          data['title'] ?? '', data['createdAt'], d.id, data));
                    }
                    for (final d in orgSnap.data!.docs) {
                      final data = d.data() as Map<String, dynamic>;
                      items.add(_TimelineItem('org', '🏠', const Color(0xFF2D6A4F),
                          '${data['name'] ?? ''} が登録されました', data['createdAt'], d.id, data));
                    }
                    for (final d in hospSnap.data!.docs) {
                      final data = d.data() as Map<String, dynamic>;
                      items.add(_TimelineItem('hospital', '🏥', const Color(0xFF4DA8DA),
                          '${data['name'] ?? ''} が登録されました', data['createdAt'], d.id, data));
                    }

                    items.sort((a, b) {
                      final at = a.createdAt as Timestamp?;
                      final bt = b.createdAt as Timestamp?;
                      if (at == null || bt == null) return 0;
                      return bt.compareTo(at);
                    });

                    final topItems = items.take(30).toList();

                    if (topItems.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('まだ投稿がありません', style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: topItems.length,
                      itemBuilder: (_, i) {
                        final item = topItems[i];
                        return _TimelineCard(item: item);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimelineItem {
  final String type;
  final String emoji;
  final Color color;
  final String title;
  final dynamic createdAt;
  final String id;
  final Map<String, dynamic> data;

  _TimelineItem(this.type, this.emoji, this.color, this.title, this.createdAt, this.id, this.data);
}
class _TimelineCard extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineCard({required this.item});

  String _timeAgo(dynamic createdAt) {
    if (createdAt is! Timestamp) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${createdAt.toDate().month}月${createdAt.toDate().day}日';
  }

  void _handleTap(BuildContext context) {
    switch (item.type) {
      case 'lost':
        showLostPetDetail(context, item.data, item.id);
        break;
      case 'volunteer':
        VolunteerPage.showDetail(context, item.id, item.data);
        break;
      case 'org':
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrganizationProfilePage(orgId: item.id)));
        break;
      case 'hospital':
        showHospitalDetail(context, item.id, item.data);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = item.type == 'lost' && item.data['urgent'] == true;
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isUrgent ? Border.all(color: Colors.red[300]!) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUrgent)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                            child: const Text('緊急', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        Expanded(
                          child: Text('${item.emoji} ${item.title}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_timeAgo(item.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showHospitalDetail(BuildContext context, String hospitalId, Map<String, dynamic> data) {

  final animalTags = List<String>.from(data['animalTags'] ?? []);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((data['imageUrl'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['imageUrl'], width: double.infinity, height: 160, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(data['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            if ((data['address'] ?? '').toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(data['address'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            if ((data['businessHours'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(data['businessHours'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ],
            if ((data['contactInfo'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(data['contactInfo'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('対応動物（自己申告）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: animalTags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF4DA8DA).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF4DA8DA), fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('診療体制', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data['acceptingNew'] == true) hospitalBadge('新規受付中'),
                if (data['hasInpatient'] == true) hospitalBadge('入院施設あり'),
                if (data['hasCT'] == true) hospitalBadge('CT設備あり'),
                if (data['hasMRI'] == true) hospitalBadge('MRI設備あり'),
                if (data['hasNightCare'] == true) hospitalBadge('夜間・救急対応'),

              ],
            ),
            const SizedBox(height: 16),
            const Text('実際に診てもらえた動物（利用者による確認）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).collection('tagVotes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final counts = <String, int>{};
                for (final doc in snapshot.data!.docs) {
                  final tags = List<String>.from((doc.data() as Map<String, dynamic>)['verifiedAnimalTags'] ?? []);
                  for (final t in tags) {
                    counts[t] = (counts[t] ?? 0) + 1;
                  }
                }
                if (counts.isEmpty) {
                  return Text('まだ確認はありません', style: TextStyle(color: Colors.grey[500], fontSize: 12));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(10)),
                    child: Text('✓ ${e.key} (${e.value}人)', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('みんなの一言', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).collection('tagVotes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final counts = <String, int>{};
                for (final doc in snapshot.data!.docs) {
                  final tags = List<String>.from((doc.data() as Map<String, dynamic>)['commentTags'] ?? []);
                  for (final t in tags) {
                    counts[t] = (counts[t] ?? 0) + 1;
                  }
                }
                if (counts.isEmpty) {
                  return Text('まだタグが付いていません', style: TextStyle(color: Colors.grey[500], fontSize: 12));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12, color: Color(0xFF3D2B1F))),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showTagSelectSheet(context, hospitalId, animalTags);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DA8DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('この病院にタグを付ける', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget hospitalBadge(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
  );
}

void showTagSelectSheet(BuildContext context, String hospitalId, List<String> hospitalAnimalTagsList) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _HospitalTagSelectSheet(hospitalId: hospitalId, hospitalAnimalTags: hospitalAnimalTagsList),
    ),
  );
}

class _HospitalList extends StatelessWidget {
final String? animalFilter;
final String? areaFilter;
final Set<String> facilityFilters;
const _HospitalList({this.animalFilter, this.areaFilter, this.facilityFilters = const {}});

@override
Widget build(BuildContext context) {
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('hospitals')
.where('status', isEqualTo: 'approved')
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Padding(
padding: EdgeInsets.symmetric(vertical: 20),
child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
);
}
final docs = snapshot.data!.docs.where((doc) {
final data = doc.data() as Map<String, dynamic>;
if (data['isPaused'] == true) return false;
if (areaFilter != null && data['area'] != areaFilter) return false;
if (animalFilter != null) {
final tags = List<String>.from(data['animalTags'] ?? []);
if (!tags.contains(animalFilter)) return false;
}
for (final f in facilityFilters) {
if (data[f] != true) return false;
}
return true;
}).toList();

if (docs.isEmpty) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 20),
child: Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
child: Column(
children: [
const Text('🔍', style: TextStyle(fontSize: 26)),
const SizedBox(height: 8),
Text(
areaFilter != null
? '$areaFilter では、条件に合う病院がまだ登録されていません。\n都道府県の条件を外して、全国から探してみてください。'
: '条件に合う病院がまだ登録されていません。',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.6),
),
],
),
),
);
}
return Column(
children: docs.map((doc) {
final data = doc.data() as Map<String, dynamic>;
final animalTags = List<String>.from(data['animalTags'] ?? []);
return GestureDetector(
  onTap: () => showHospitalDetail(context, doc.id, data),

child: Container(
margin: const EdgeInsets.only(bottom: 10),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: const Color(0xFF4DA8DA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
child: const Center(child: Text('🏥', style: TextStyle(fontSize: 19))),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
if (animalTags.isNotEmpty) ...[
const SizedBox(height: 4),
Wrap(
spacing: 4,
children: animalTags.take(2).map((t) => Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: const Color(0xFF4DA8DA).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
child: Text(t, style: const TextStyle(fontSize: 9, color: Color(0xFF4DA8DA))),
)).toList(),
),
],
const SizedBox(height: 4),
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance.collection('hospitals').doc(doc.id).collection('tagVotes').snapshots(),
builder: (context, voteSnap) {
if (!voteSnap.hasData) return const SizedBox();
final verifiedCount = voteSnap.data!.docs.where((v) {
final vd = v.data() as Map<String, dynamic>;
final verified = List<String>.from(vd['verifiedAnimalTags'] ?? []);
return verified.isNotEmpty;
}).length;
if (verifiedCount == 0) return const SizedBox();
return Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(6)),
child: Text('✓ 実際に診てもらえた $verifiedCount人', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
);
},
),
],
),
),
const Icon(Icons.chevron_right_rounded, color: Colors.grey),
],
),
),
);
}).toList(),
);
},
);
}



}
class _HospitalTagSelectSheet extends StatefulWidget {
  final String hospitalId;
  final List<String> hospitalAnimalTags;
  const _HospitalTagSelectSheet({required this.hospitalId, required this.hospitalAnimalTags});

  @override
  State<_HospitalTagSelectSheet> createState() => _HospitalTagSelectSheetState();
}

class _HospitalTagSelectSheetState extends State<_HospitalTagSelectSheet> {
List<String> _selectedCommentTags = [];
List<String> _selectedVerifiedTags = [];
bool _isSaving = false;
bool _alreadyVoted = false;
bool _isChecking = true;

@override
void initState() {
super.initState();
_checkAlreadyVoted();
}

Future<void> _checkAlreadyVoted() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) {
setState(() => _isChecking = false);
return;
}
final doc = await FirebaseFirestore.instance
.collection('hospitals')
.doc(widget.hospitalId)
.collection('tagVotes')
.doc(myUid)
.get();
setState(() {
_alreadyVoted = doc.exists;
_isChecking = false;
});
}

Future<void> _submit() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null || (_selectedCommentTags.isEmpty && _selectedVerifiedTags.isEmpty)) return;

setState(() => _isSaving = true);

await FirebaseFirestore.instance
.collection('hospitals')
.doc(widget.hospitalId)
.collection('tagVotes')
.doc(myUid)
.set({
'commentTags': _selectedCommentTags,
'verifiedAnimalTags': _selectedVerifiedTags,
'createdAt': FieldValue.serverTimestamp(),
});

if (mounted) Navigator.pop(context);
}
@override
Widget build(BuildContext context) {
  if (_isChecking) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA))),
    );
  }

  if (_alreadyVoted) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('すでにこの病院にタグを付けています', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('この病院にタグを付ける', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('当てはまるものをすべて選んでください（1病院につき1回まで）', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        if (widget.hospitalAnimalTags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: const Text('✓ 実際にこの動物を診てもらえましたか？',
                style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.hospitalAnimalTags.map((tag) {
              final sel = _selectedVerifiedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) {
                    _selectedVerifiedTags.remove(tag);
                  } else {
                    _selectedVerifiedTags.add(tag);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        const Text('一言（当てはまるものを選んでください）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hospitalCommentTags.map((tag) {
            final sel = _selectedCommentTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _selectedCommentTags.remove(tag);
                } else {
                  _selectedCommentTags.add(tag);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || (_selectedCommentTags.isEmpty && _selectedVerifiedTags.isEmpty) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DA8DA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('送信する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
}
class _OrgList extends StatelessWidget {
  const _OrgList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('団体が見つかりませんでした', style: TextStyle(color: Colors.grey[500])),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => OrganizationProfilePage(orgId: doc.id))),
              child: _MapCard(
                emoji: '🏠',
                color: const Color(0xFF2D6A4F),
                title: data['name'] ?? '',
                subtitle: '保護団体',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
class _AdoptionList extends StatelessWidget {
  const _AdoptionList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoptions')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('里親募集が見つかりませんでした', style: TextStyle(color: Colors.grey[500])),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => showAdoptionDetail(context, data),
              child: _MapCard(
                emoji: '🐾',
                color: Colors.orange,
                title: data['petName'] ?? '',
                subtitle: data['type'] ?? '',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LostList extends StatefulWidget {
  const _LostList();

  @override
  State<_LostList> createState() => _LostListState();
}

class _LostListState extends State<_LostList> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _LostFilterChip(label: 'すべて', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '迷子中', value: 'lost', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '見つかりました', value: 'resolved', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '緊急', value: 'urgent', selected: _filter, onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lostPets')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF3498DB))),
              );
            }
            var docs = snapshot.data!.docs;
            if (_filter == 'urgent') {
              docs = docs.where((d) => (d.data() as Map<String, dynamic>)['urgent'] == true).toList();
            } else if (_filter != 'all') {
              docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == _filter).toList();
            }
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('該当する投稿はありません', style: TextStyle(color: Colors.grey[500])),
              );
            }
            final myUid = FirebaseAuth.instance.currentUser?.uid;
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isMinePost = data['uid'] == myUid;
                return GestureDetector(
                  onTap: () => showLostPetDetail(context, data, doc.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMinePost ? const Color(0xFF3498DB).withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isMinePost
                          ? Border.all(color: const Color(0xFF3498DB), width: 1.2)
                          : data['urgent'] == true ? Border.all(color: Colors.red[300]!) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: const Color(0xFF3498DB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(data['emoji'] ?? '🔍', style: const TextStyle(fontSize: 19))),
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
                                  if (data['urgent'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('緊急', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  _LostStatusBadge(status: data['status'] ?? 'lost'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(data['petName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                              if ((data['location'] ?? '').toString().isNotEmpty)
                                Text(data['location'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
class _LostFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;
  const _LostFilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFF3498DB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? const Color(0xFF3498DB) : Colors.grey[300]!)),
        child: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
class _VolunteerList extends StatelessWidget {
  const _VolunteerList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteers')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('ボランティア募集が見つかりませんでした', style: TextStyle(color: Colors.grey[500])),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => VolunteerPage.showDetail(context, doc.id, data),

              child: _MapCard(
                emoji: '🤝',
                color: const Color(0xFFE8845A),
                title: data['title'] ?? '',
                subtitle: data['location'] ?? '',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
class _MapCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;

  const _MapCard({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 19))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}

class _LostStatusBadge extends StatelessWidget {
  final String status;
  const _LostStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: isResolved ? const Color(0xFF2D6A4F) : const Color(0xFF3498DB),
          borderRadius: BorderRadius.circular(6)),
      child: Text(isResolved ? '見つかりました' : '迷子中',
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
