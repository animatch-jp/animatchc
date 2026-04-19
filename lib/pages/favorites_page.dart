import 'package:flutter/material.dart';
import '../models/pet.dart';

class FavoritesPage extends StatelessWidget {
  final List<Pet> allPets;
  final Set<String> favIds;
  final void Function(String) onToggle;

  const FavoritesPage({
    super.key,
    required this.allPets,
    required this.favIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final favPets = allPets.where((p) => favIds.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('お気に入り（${favPets.length}件）'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: favPets.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⭐', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('お気に入りがありません',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text('スワイプ中に☆を押して追加しよう',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: favPets.length,
        itemBuilder: (_, i) {
          final pet = favPets[i];
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
            trailing: IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () => onToggle(pet.id),
            ),
          );
        },
      ),
    );
  }
}
