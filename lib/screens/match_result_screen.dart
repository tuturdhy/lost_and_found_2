import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/matching_service.dart';
import '../models/item_model.dart';
import '../theme.dart';
import 'item_detail_screen.dart';
import 'chat_screen.dart';

class MatchResultScreen extends StatelessWidget {
  final ItemModel publishedItem;
  final List<MatchResult> matches;

  const MatchResultScreen({
    super.key,
    required this.publishedItem,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final hasMatches = matches.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du matching'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            // Pop jusqu'à home
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Column(
        children: [
          // Header résultat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasMatches
                    ? [
                        AppTheme.accent.withOpacity(0.2),
                        AppTheme.primary,
                      ]
                    : [
                        AppTheme.surface.withOpacity(0.3),
                        AppTheme.primary,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Icône animée
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: hasMatches
                        ? AppTheme.accent.withOpacity(0.15)
                        : AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          hasMatches ? AppTheme.accent : AppTheme.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    hasMatches
                        ? Icons.search_rounded
                        : Icons.search_off_rounded,
                    color: hasMatches
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasMatches
                      ? '🔥 ${matches.length} correspondance${matches.length > 1 ? 's' : ''} trouvée${matches.length > 1 ? 's' : ''} !'
                      : '📭 Aucune correspondance pour l\'instant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: hasMatches
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasMatches
                      ? 'Ton objet a été publié + des correspondances ont été détectées'
                      : 'Ton objet a été publié. Tu recevras une alerte dès qu\'une correspondance est trouvée.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Liste des matchs
          if (hasMatches)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                itemBuilder: (_, i) => _MatchCard(
                  match: matches[i],
                  publishedItem: publishedItem,
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'On surveille pour toi !',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dès qu\'un objet similaire est publié,\ntu recevras une notification.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            ),

          // Bouton retour en bas
          if (hasMatches)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchResult match;
  final ItemModel publishedItem;

  const _MatchCard({required this.match, required this.publishedItem});

  @override
  Widget build(BuildContext context) {
    final scoreColor = match.score >= 80
        ? AppTheme.foundColor
        : match.score >= 50
            ? const Color(0xFFFFA502)
            : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Score header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: scoreColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${match.score}% de correspondance',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    match.scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu de l'objet
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Photo
                // ... dans _MatchCard.build() ...

// Photo
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: (match.item.photoUrl != null && match.item.photoUrl!.isNotEmpty)
      ? CachedNetworkImage(
          imageUrl: match.item.photoUrl!,  // ✅ Null-aware access
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 72,
            height: 72,
            color: AppTheme.surface,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 72,
            height: 72,
            color: AppTheme.surface,
            child: const Icon(Icons.image_not_supported_rounded,
                color: AppTheme.textSecondary),
          ),
        )
      : Container(
          width: 72,
          height: 72,
          color: AppTheme.surface,
          child: const Icon(Icons.image_rounded,
              color: AppTheme.textSecondary),
        ),
),

// ... reste du fichier inchangé ...
                const SizedBox(width: 14),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.item.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppTheme.accent, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              match.item.address.isNotEmpty
                                  ? match.item.address
                                  : 'Position inconnue',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Raisons du match
                      Wrap(
                        spacing: 4,
                        children: [
                          if (match.sameCategory)
                            _reasonChip('Même catégorie', scoreColor),
                          if (match.sameColor)
                            _reasonChip('Même couleur', scoreColor),
                          ...match.matchedKeywords.take(2).map(
                                (kw) => _reasonChip(kw, scoreColor),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Boutons d'action
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ItemDetailScreen(item: match.item),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Voir'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: match.item.userId,
                          otherUserName: match.item.userName,
                          itemId: match.item.id,
                          itemTitle: match.item.title,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded,
                        color: Colors.white, size: 16),
                    label: const Text(
                      'Contacter',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
