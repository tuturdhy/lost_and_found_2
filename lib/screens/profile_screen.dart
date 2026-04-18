import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../theme.dart';
import '../widgets/item_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authService = AuthService();
    final itemService = ItemService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: authService.getUserStream(currentUserId),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header profil
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardBg,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.divider),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.accent,
                        backgroundImage: user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(user!.avatarUrl)
                            : null,
                        child: user?.avatarUrl.isEmpty != false
                            ? Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Chargement...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem(
                            '${user?.itemsPublished ?? 0}',
                            'Publiés',
                            Icons.upload_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.divider,
                          ),
                          _statItem(
                            '${user?.itemsResolved ?? 0}',
                            'Résolus',
                            Icons.check_circle_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.divider,
                          ),
                          _statItem(
                            '${user?.reputationScore.toStringAsFixed(0) ?? 0}',
                            'Réputation',
                            Icons.star_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Mes objets
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes objets publiés',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<ItemModel>>(
                        stream: itemService.getUserItems(currentUserId),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.accent),
                            );
                          }
                          final items = snap.data ?? [];
                          if (items.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Text('📭',
                                        style: TextStyle(fontSize: 36)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Aucun objet publié',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (_, i) =>
                                ItemCard(item: items[i]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accent, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
