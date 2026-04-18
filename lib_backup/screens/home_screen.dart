import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/item_service.dart';
import '../services/notification_service.dart';
import '../services/search_service.dart';
import '../models/item_model.dart';
import '../theme.dart';
import '../widgets/item_card.dart';
import 'publish_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'chats_list_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _filter = 'all';
  final ItemService _itemService = ItemService();
  final NotificationService _notifService = NotificationService();
  final SearchService _searchService = SearchService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SearchQuery? _parsedQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildFeed(),
          const MapScreen(),
          const SizedBox(),
          const ChatsListScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PublishScreen()),
              ),
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Publier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
          onTap: (i) {
            if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PublishScreen()),
              );
            } else {
              setState(() => _currentIndex = i);
            }
          },
          backgroundColor: AppTheme.primary,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Carte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded),
              label: 'Publier',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
Widget _buildFeed() {
  // ✅ Récupérer l'ID de l'utilisateur connecté
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  return SafeArea(
    child: Column(
      children: [
        // 🔔 Header avec notification badge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonjour 👋',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName
                            ?.split(' ')
                            .first ??
                        'Utilisateur',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 🔔 Cloche avec badge de notifications
              StreamBuilder<int>(
                stream: _notifService.getUnreadCount(currentUserId),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: count > 0
                                  ? AppTheme.accent.withOpacity(0.5)
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Icon(
                            count > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_rounded,
                            color: count > 0
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                            size: 22,
                          ),
                        ),
                        // Badge rouge
                        if (count > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 🔍 Smart Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
                _parsedQuery = v.isNotEmpty
                    ? _searchService.analyzeQuery(v)
                    : null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Ex: "sac noir Nike perdu"...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _parsedQuery = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),

        // 🤖 Afficher les filtres détectés par l'IA
        if (_parsedQuery != null && _parsedQuery!.hasIntelligentFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.accent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '🤖 ${_parsedQuery!.summary}',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Filter tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _filterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _filterChip('Perdus 🔴', 'lost'),
              const SizedBox(width: 8),
              _filterChip('Trouvés 🟢', 'found'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ✅ LISTE DES OBJETS — Utilise getActiveItemsFromOthers()
        Expanded(
          child: StreamBuilder<List<ItemModel>>(
            // ✅ CHANGEMENT : utilise la méthode filtrée
            stream: _itemService.getActiveItemsFromOthers(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📭', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Aucun objet publié par d\'autres utilisateurs',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16),
                      ),
                      Text(
                        'Explore la carte ou publie le tien !',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              var items = snapshot.data!;

              // Filtrer par type (lost/found)
              if (_filter != 'all') {
                items = items.where((i) => i.type == _filter).toList();
              }

              // 🤖 Smart search
              if (_searchQuery.isNotEmpty) {
                items = _searchService.smartSort(items, _searchQuery);
                // Filtrer les non pertinents si query longue
                if (_searchQuery.split(' ').length > 1) {
                  items = items.where((i) {
                    final q = _searchQuery.toLowerCase();
                    return i.title.toLowerCase().contains(q) ||
                        i.description.toLowerCase().contains(q) ||
                        i.category.toLowerCase().contains(q) ||
                        i.keywords.any((k) =>
                            k.toLowerCase().contains(q)) ||
                        i.color.toLowerCase().contains(q);
                  }).toList();
                }
              }

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun résultat pour ce filtre',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16),
                      ),
                      if (_parsedQuery != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Essaie avec d\'autres mots-clés',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (_, i) => ItemCard(item: items[i]),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
