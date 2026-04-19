class Pet {
  final String id;
  final String name;
  final String type;
  final int age;
  final String bio;
  final String avatarPath;
  final List<String> photos;
  final String owner;
  final String ownerCity;

  const Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.bio,
    required this.avatarPath,
    required this.photos,
    required this.owner,
    required this.ownerCity,
  });
}
