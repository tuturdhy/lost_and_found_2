/// Service de recherche intelligente (AI fake)
/// Analyse le texte de recherche et le transforme en filtres intelligents
import '../models/item_model.dart';
class SearchService {
  // Dictionnaire de synonymes et associations
  static const Map<String, List<String>> _synonyms = {
    'téléphone': ['phone', 'mobile', 'iphone', 'samsung', 'smartphone', 'gsm', 'portable'],
    'sac': ['bag', 'sacoche', 'sac à dos', 'backpack', 'valise', 'cartable'],
    'clé': ['key', 'clef', 'trousseau', 'keys'],
    'portefeuille': ['wallet', 'porte-monnaie', 'carte', 'billets'],
    'bijou': ['bague', 'collier', 'bracelet', 'montre', 'ring', 'necklace'],
    'lunettes': ['glasses', 'soleil', 'vue', 'optique'],
    'animal': ['chat', 'chien', 'cat', 'dog', 'pet', 'perdu'],
    'vêtement': ['habit', 'manteau', 'veste', 'pantalon', 'chemise'],
  };

  static const Map<String, String> _colorMap = {
    'noir': 'noir', 'black': 'noir', 'noire': 'noir',
    'blanc': 'blanc', 'white': 'blanc', 'blanche': 'blanc',
    'rouge': 'rouge', 'red': 'rouge',
    'bleu': 'bleu', 'blue': 'bleu', 'bleue': 'bleu',
    'vert': 'vert', 'green': 'vert', 'verte': 'vert',
    'jaune': 'jaune', 'yellow': 'jaune',
    'gris': 'gris', 'gray': 'gris', 'grey': 'gris', 'grise': 'gris',
    'marron': 'marron', 'brown': 'marron',
    'rose': 'rose', 'pink': 'rose',
    'orange': 'orange',
  };

  static const Map<String, String> _brandKeywords = {
    'apple': 'Apple', 'iphone': 'Apple', 'ipad': 'Apple', 'macbook': 'Apple',
    'samsung': 'Samsung', 'galaxy': 'Samsung',
    'nike': 'Nike', 'adidas': 'Adidas', 'puma': 'Puma',
    'louis vuitton': 'Louis Vuitton', 'lv': 'Louis Vuitton',
    'gucci': 'Gucci', 'zara': 'Zara', 'h&m': 'H&M',
  };

  /// Résultat d'une analyse de recherche
  SearchQuery analyzeQuery(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    final words = query.split(RegExp(r'\s+'));

    String? detectedCategory;
    String? detectedColor;
    String? detectedType; // 'lost' or 'found'
    final List<String> extractedKeywords = [];
    final List<String> brands = [];

    // 1. Détecter le type (perdu/trouvé)
    if (_containsAny(query, ['perdu', 'lost', 'cherche', 'search', 'disparu'])) {
      detectedType = 'lost';
    } else if (_containsAny(query, ['trouvé', 'found', 'trouvé', 'récupéré'])) {
      detectedType = 'found';
    }

    // 2. Détecter la catégorie via synonymes
    for (final entry in _synonyms.entries) {
      if (query.contains(entry.key) ||
          entry.value.any((syn) => query.contains(syn))) {
        detectedCategory = entry.key;
        break;
      }
    }

    // 3. Détecter la couleur
    for (final entry in _colorMap.entries) {
      if (words.contains(entry.key)) {
        detectedColor = entry.value;
        break;
      }
    }

    // 4. Détecter les marques
    for (final entry in _brandKeywords.entries) {
      if (query.contains(entry.key)) {
        brands.add(entry.value);
        extractedKeywords.add(entry.value);
      }
    }

    // 5. Extraire les mots significatifs comme keywords
    for (final word in words) {
      if (word.length > 3 &&
          !_isStopWord(word) &&
          !extractedKeywords.contains(word)) {
        extractedKeywords.add(word);
      }
    }

    return SearchQuery(
      rawQuery: rawQuery,
      detectedCategory: detectedCategory,
      detectedColor: detectedColor,
      detectedType: detectedType,
      keywords: extractedKeywords,
      brands: brands,
    );
  }

  /// Scorer un item par rapport à une SearchQuery
  int scoreItem(ItemModel item, SearchQuery query) {
    int score = 0;

    // Type correspond
    if (query.detectedType != null && item.type == query.detectedType) {
      score += 20;
    }

    // Catégorie correspond
    if (query.detectedCategory != null &&
        item.category == query.detectedCategory) {
      score += 35;
    }

    // Couleur correspond
    if (query.detectedColor != null &&
        item.color.toLowerCase() == query.detectedColor) {
      score += 20;
    }

    // Keywords dans le titre ou description
    for (final kw in query.keywords) {
      if (item.title.toLowerCase().contains(kw)) score += 10;
      if (item.description.toLowerCase().contains(kw)) score += 5;
      if (item.keywords.any((k) => k.toLowerCase().contains(kw))) score += 8;
    }

    // Marques correspondent
    for (final brand in query.brands) {
      if (item.keywords.any((k) => k.toLowerCase() == brand.toLowerCase())) {
        score += 15;
      }
    }

    return score.clamp(0, 100);
  }

  /// Trier les items par pertinence
  List<ItemModel> smartSort(List<ItemModel> items, String rawQuery) {
    if (rawQuery.trim().isEmpty) return items;

    final query = analyzeQuery(rawQuery);
    final scored = items.map((item) {
      return _ScoredItem(item: item, score: scoreItem(item, query));
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.item).toList();
  }

  bool _containsAny(String text, List<String> words) {
    return words.any((w) => text.contains(w));
  }

  bool _isStopWord(String word) {
    const stopWords = [
      'le', 'la', 'les', 'un', 'une', 'des', 'de', 'du', 'en',
      'et', 'ou', 'est', 'que', 'qui', 'avec', 'pour', 'dans',
      'mon', 'ma', 'mes', 'ton', 'ta', 'ses', 'son', 'this', 'the',
    ];
    return stopWords.contains(word);
  }
}

class SearchQuery {
  final String rawQuery;
  final String? detectedCategory;
  final String? detectedColor;
  final String? detectedType;
  final List<String> keywords;
  final List<String> brands;

  SearchQuery({
    required this.rawQuery,
    this.detectedCategory,
    this.detectedColor,
    this.detectedType,
    required this.keywords,
    required this.brands,
  });

  bool get hasIntelligentFilters =>
      detectedCategory != null || detectedColor != null || brands.isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (detectedType != null) {
      parts.add(detectedType == 'lost' ? '🔴 Perdus' : '🟢 Trouvés');
    }
    if (detectedCategory != null) parts.add('📦 $detectedCategory');
    if (detectedColor != null) parts.add('🎨 $detectedColor');
    if (brands.isNotEmpty) parts.add('🏷️ ${brands.join(', ')}');
    return parts.join(' · ');
  }
}

class _ScoredItem {
  final ItemModel item;
  final int score;
  _ScoredItem({required this.item, required this.score});
}

// Import nécessaire

