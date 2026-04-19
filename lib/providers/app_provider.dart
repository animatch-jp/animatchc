import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../models/match.dart';

const stampSets = [
  {'name': 'わんこセット', 'unlockAt': 50, 'rarity': '⭐ ノーマル', 'emojis': ['🐕','🐶','🦴','🐾','❤️']},
  {'name': 'にゃんこセット', 'unlockAt': 150, 'rarity': '⭐ ノーマル', 'emojis': ['🐱','😺','🐟','🐾','💕']},
  {'name': 'うさぎセット', 'unlockAt': 300, 'rarity': '⭐⭐ レア', 'emojis': ['🐰','🥕','🌸','💗','🌿']},
  {'name': 'ハムスターセット', 'unlockAt': 500, 'rarity': '⭐⭐ レア', 'emojis': ['🐹','🌰','🧡','🏠','✨']},
  {'name': 'とりセット', 'unlockAt': 800, 'rarity': '⭐⭐⭐ スーパーレア', 'emojis': ['🐦','🦜','🥚','🌤️','💙']},
  {'name': '水族館セット', 'unlockAt': 1200, 'rarity': '⭐⭐⭐ スーパーレア', 'emojis': ['🐠','🐬','🦈','🐙','🌊']},
  {'name': '動物園セット', 'unlockAt': 1800, 'rarity': '👑 レジェンド', 'emojis': ['🦁','🐘','🦒','🐼','🦓']},
  {'name': 'レアセット', 'unlockAt': 2500, 'rarity': '👑 レジェンド', 'emojis': ['✨','🦄','🌈','💎','🔮']},
  {'name': '伝説セット', 'unlockAt': 3500, 'rarity': '👑 レジェンド', 'emojis': ['👑','🏆','🌟','💫','🎖️']},
  {'name': 'プレミアムセット', 'unlockAt': 5000, 'rarity': '👑 レジェンド', 'emojis': ['🌟','💝','🎊','🎉','🥇']},
];

const titleSets = [
  {'title': 'ビギナー🐾', 'unlockAt': 0},
  {'title': 'ペット好き🐶', 'unlockAt': 50},
  {'title': 'ペット通🐱', 'unlockAt': 150},
  {'title': 'アニマルラバー🐰', 'unlockAt': 300},
  {'title': 'ペットマスター⭐', 'unlockAt': 500},
  {'title': 'アニマルヒーロー🦁', 'unlockAt': 800},
  {'title': '動物博士🔬', 'unlockAt': 1200},
  {'title': 'レジェンド👑', 'unlockAt': 2500},
  {'title': 'ゴッド🌟', 'unlockAt': 5000},
];

class AppProvider extends ChangeNotifier {
  final Set<String> _favIds = {};
  final Set<String> _likedIds = {};
  final List<Match> _matches = [];
  int _swipeCount = 0;
  String? _newlyUnlockedStamp;
  String? _newlyUnlockedTitle;

  Set<String> get favIds => _favIds;
  Set<String> get likedIds => _likedIds;
  List<Match> get matches => _matches;
  int get swipeCount => _swipeCount;
  String? get newlyUnlockedStamp => _newlyUnlockedStamp;
  String? get newlyUnlockedTitle => _newlyUnlockedTitle;

  bool isFav(String id) => _favIds.contains(id);
  bool isLiked(String id) => _likedIds.contains(id);
  // バッジ獲得条件
  List<Map<String, String>> get earnedBadges {
    final badges = <Map<String, String>>[];
    badges.add({'emoji': '🐾', 'label': '飼い主認定'});
    if (_swipeCount >= 50)
      badges.add({'emoji': '🏆', 'label': 'アクティブ勢'});
    if (_swipeCount >= 300)
      badges.add({'emoji': '🌟', 'label': 'ベテラン'});
    if (_swipeCount >= 1000)
      badges.add({'emoji': '👑', 'label': 'レジェンド'});
    if (_supportCount > 0)
      badges.add({'emoji': '❤️', 'label': '支援者'});
    return badges;
  }

  int _supportCount = 0;

  void addSupport() {
    _supportCount++;
    notifyListeners();
  }


  void clearNewStamp() => _newlyUnlockedStamp = null;
  void clearNewTitle() => _newlyUnlockedTitle = null;

  String get currentTitle {
    String title = 'ビギナー🐾';
    for (final t in titleSets) {
      if (_swipeCount >= (t['unlockAt'] as int)) {
        title = t['title'] as String;
      }
    }
    return title;
  }

  void toggleFav(String id) {
    _favIds.contains(id) ? _favIds.remove(id) : _favIds.add(id);
    _incrementSwipe();
    notifyListeners();
  }

  void like(Pet pet) {
    _likedIds.add(pet.id);
    _incrementSwipe();
    notifyListeners();
  }

  void skip() {
    _incrementSwipe();
    notifyListeners();
  }

  void _incrementSwipe() {
    if (_swipeCount >= 5000) return;
    final before = _swipeCount;
    _swipeCount++;

    for (final s in stampSets) {
      final unlockAt = s['unlockAt'] as int;
      if (before < unlockAt && _swipeCount >= unlockAt) {
        _newlyUnlockedStamp = s['name'] as String;
        break;
      }
    }

    for (final t in titleSets) {
      final unlockAt = t['unlockAt'] as int;
      if (unlockAt > 0 && before < unlockAt && _swipeCount >= unlockAt) {
        _newlyUnlockedTitle = t['title'] as String;
        break;
      }
    }
  }

  int get nextStampAt {
    for (final s in stampSets) {
      if (_swipeCount < (s['unlockAt'] as int)) {
        return s['unlockAt'] as int;
      }
    }
    return 5000;
  }

  List<Map<String, dynamic>> get unlockedStamps {
    return stampSets
        .where((s) => (s['unlockAt'] as int) <= _swipeCount)
        .toList();
  }

  List<Map<String, dynamic>> get unlockedTitles {
    return titleSets
        .where((t) => (t['unlockAt'] as int) <= _swipeCount)
        .toList();
  }
}

final globalProvider = AppProvider();
