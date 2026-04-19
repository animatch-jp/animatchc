import 'package:flutter/material.dart';

class PetCarousel extends StatelessWidget {
  final List<String> photoPaths;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const PetCarousel({
    super.key,
    required this.photoPaths,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(photoPaths.length, (index) {
        final isSelected = index == selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF8FB1) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.asset(
                    photoPaths[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}