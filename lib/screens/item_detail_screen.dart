import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'lost';
    final statusColor = isLost ? AppTheme.lostColor : AppTheme.foundColor;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = item.userId == currentUserId;
    final itemService = ItemService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Photo en haut
          // ... dans ItemDetailScreen.build() ...

SliverAppBar(
  expandedHeight: 300,
  pinned: true,
  backgroundColor: AppTheme.primary,
  leading: GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
    ),
  ),
  flexibleSpace: FlexibleSpaceBar(
    background: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: item.photoUrl!,  // ✅ Null-aware access
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppTheme.surface,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.surface,
              child: const Icon(Icons.image_not_supported_rounded,
                  color: AppTheme.textSecondary, size: 60),
            ),
          )
        : Container(
            color: AppTheme.surface,
            child: const Icon(Icons.image_rounded,
                color: AppTheme.textSecondary, size: 60),
          ),
  ),
),

// ... reste du fichier inchangé ...
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLost
                                  ? Icons.search_rounded
                                  : Icons.check_circle_rounded,
                              color: statusColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLost ? 'OBJET PERDU' : 'OBJET TROUVÉ',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy').format(item.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : 'Aucune description',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Infos
                  _infoCard(Icons.category_rounded, 'Catégorie',
                      item.category),
                  const SizedBox(height: 8),
                  _infoCard(Icons.palette_rounded, 'Couleur',
                      item.color.isNotEmpty ? item.color : 'Non précisée'),
                  const SizedBox(height: 8),
                  _infoCard(Icons.location_on_rounded, 'Endroit',
                      item.address.isNotEmpty ? item.address : 'Non précisé'),
                  const SizedBox(height: 20),

                  // Mots-clés
                  if (item.keywords.isNotEmpty) ...[
                    const Text(
                      '🏷️ Mots-clés',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.keywords.map((k) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            k,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Publié par
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.surface,
                          backgroundImage: item.userAvatar.isNotEmpty
                              ? NetworkImage(item.userAvatar)
                              : null,
                          child: item.userAvatar.isEmpty
                              ? Text(
                                  item.userName.isNotEmpty
                                      ? item.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Publié par',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.userName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boutons d'action
                  if (!isOwner && item.status == 'active')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: item.userId,
                              otherUserName: item.userName,
                              itemId: item.id,
                              itemTitle: item.title,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: Text(
                          isLost
                              ? "J'ai trouvé cet objet !"
                              : "C'est mon objet !",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  if (isOwner && item.status == 'active') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await itemService.markAsResolved(
                              item.id, item.userId);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('🎉 Objet marqué comme retrouvé !'),
                                backgroundColor: AppTheme.foundColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.foundColor,
                        ),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Marquer comme retrouvé ✅',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],

                  if (item.status == 'resolved')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.foundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.foundColor),
                      ),
                      child: const Center(
                        child: Text(
                          '✅ Cet objet a été retrouvé !',
                          style: TextStyle(
                            color: AppTheme.foundColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
