import 'package:flutter/material.dart';
import '../models/pet.dart';

class LikesPage extends StatelessWidget {
  final List<Pet> allPets;
  final Set<String> likedIds;

  const LikesPage({
    super.key,
    required this.allPets,
    required this.likedIds,
  });

  @override
  Widget build(BuildContext context) {
    final likedPets = allPets.where((p) => likedIds.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('いいね一覧（${likedPets.length}件）'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: likedPets.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('❤️', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('まだいいねがありません',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text('スワイプして右にいいねしよう！',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: likedPets.length,
        itemBuilder: (_, i) {
          final pet = likedPets[i];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(pet.avatarPath,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                      width: 52, height: 52, color: Colors.orange[50],
                      child: const Center(child: Text('🐾')))),
            ),
            title: Text(pet.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${pet.type}・${pet.age}歳・${pet.ownerCity}'),
            trailing: Text('${pet.owner}さん',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          );
        },
      ),
    );
  }
}
