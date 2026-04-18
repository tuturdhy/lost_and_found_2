import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/item_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/matching_service.dart';
import '../services/notification_service.dart';
import '../models/item_model.dart';
import '../theme.dart';
import 'match_result_screen.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  
  final _itemService = ItemService();
  final _locationService = LocationService();
  final _authService = AuthService();
  final _matchingService = MatchingService();
  final _notifService = NotificationService();

  String _type = 'lost';
  String _category = 'autre';
  String _color = '';
  List<String> _selectedKeywords = [];
  File? _imageFile;
  bool _loading = false;
  bool _isAnalyzing = false;
  double? _lat;
  double? _lng;
  String _address = '';
  String _loadingMessage = 'Publication en cours...';

  final List<String> _categories = [
    'téléphone', 'sac', 'clé', 'portefeuille',
    'bijou', 'lunettes', 'vêtement', 'animal', 'autre'
  ];

  final List<String> _colors = [
    'Noir', 'Blanc', 'Rouge', 'Bleu', 'Vert',
    'Jaune', 'Marron', 'Gris', 'Rose', 'Orange'
  ];

  final List<String> _suggestedKeywords = [
    'Apple', 'Samsung', 'Nike', 'Adidas', 'Louis Vuitton',
    'cuir', 'tissu', 'métal', 'plastique', 'ancien', 'neuf',
    'petit', 'grand', 'moyen'
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
    
    // ✅ Demander le focus après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      final addr = await _locationService.getAddressFromCoordinates(
          pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _address = addr;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _publish() async {
    if (_titleController.text.isEmpty) {
      _showError('Ajoute un titre');
      return;
    }
    if (_imageFile == null) {
      _showError('Ajoute une photo');
      return;
    }
    if (_lat == null) {
      _showError('Position GPS non disponible');
      return;
    }

    setState(() {
      _loading = true;
      _loadingMessage = '📸 Upload de la photo...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await _authService.getUserProfile(user.uid);

      print('📤 Début publication pour ${user.uid}');

      // 1. Upload photo
      final photoUrl = await _itemService.uploadPhoto(_imageFile!, user.uid);
      print('📸 Photo uploadée: ${photoUrl ?? "null"}');

      setState(() => _loadingMessage = '💾 Sauvegarde dans Firestore...');

      // 2. Construire les keywords
      final keywords = [
        _category,
        if (_color.isNotEmpty) _color.toLowerCase(),
        ..._selectedKeywords,
      ];
      print('🏷️ Keywords: $keywords');

      // 3. Publier l'objet
      final itemId = await _itemService.publishItem(
        userId: user.uid,
        userName: profile?.name ?? user.displayName ?? 'Utilisateur',
        userAvatar: profile?.avatarUrl ?? '',
        type: _type,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        photoUrl: photoUrl,
        category: _category,
        keywords: keywords,
        color: _color.toLowerCase(),
        latitude: _lat!,
        longitude: _lng!,
        address: _address,
      );
      print('✅ Objet publié avec ID: $itemId');

      setState(() {
        _isAnalyzing = true;
        _loadingMessage = '🤖 Recherche de correspondances...';
      });

      // 4. Construire l'objet ItemModel pour le matching
      final publishedItem = ItemModel(
        id: itemId,
        userId: user.uid,
        userName: profile?.name ?? user.displayName ?? 'Utilisateur',
        userAvatar: profile?.avatarUrl ?? '',
        type: _type,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        photoUrl: photoUrl,
        category: _category,
        keywords: keywords,
        color: _color.toLowerCase(),
        latitude: _lat!,
        longitude: _lng!,
        address: _address,
        status: 'active',
        createdAt: DateTime.now(),
      );

      print('🔍 Lancement du matching pour: ${publishedItem.title}');
      print('   - Type: ${publishedItem.type}');
      print('   - Catégorie: ${publishedItem.category}');
      print('   - Couleur: ${publishedItem.color}');
      print('   - Keywords: ${publishedItem.keywords}');
      print('   - Position: ${publishedItem.latitude}, ${publishedItem.longitude}');

      // 5. Lancer le matching
      final matches = await _matchingService.findMatchesForItem(publishedItem);
      print('🎯 ${matches.length} correspondance(s) trouvée(s) !');

      // 6. Envoyer les notifications si des matchs trouvés
      if (matches.isNotEmpty) {
        for (final match in matches) {
          try {
            print('📊 Match trouvé: ${match.item.title} (score: ${match.score}%, distance: ${match.distance.toStringAsFixed(2)} km)');
            
            // Déterminer le type de match pour chaque utilisateur
            final isNewItemLost = publishedItem.type == 'lost';
            final matchTypeForPublisher = isNewItemLost ? 'trouvé' : 'perdu';
            final matchTypeForMatched = isNewItemLost ? 'perdu' : 'trouvé';
            
            print('📤 Envoi notification à ${publishedItem.userId} (matchType: $matchTypeForPublisher)...');
            await _notifService.notifyMatch(
              userId: publishedItem.userId,
              itemTitle: publishedItem.title,
              score: match.score,
              matchedItemId: match.item.id,
              matchedItemTitle: match.item.title,
              matchType: matchTypeForPublisher,
              distance: match.distance,
            );
            print('✅ Notification 1 envoyée');
            
            print('📤 Envoi notification à ${match.item.userId} (matchType: $matchTypeForMatched)...');
            await _notifService.notifyMatch(
              userId: match.item.userId,
              itemTitle: match.item.title,
              score: match.score,
              matchedItemId: publishedItem.id,
              matchedItemTitle: publishedItem.title,
              matchType: matchTypeForMatched,
              distance: match.distance,
            );
            print('✅ Notification 2 envoyée');
            
          } catch (e, stack) {
            print('❌ Erreur notification: $e');
            print('📋 Stack: $stack');
          }
        }
      } else {
        print('⚠️ Aucune correspondance trouvée');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchResultScreen(
              publishedItem: publishedItem,
              matches: matches,
            ),
          ),
        );
      }
    } catch (e, stack) {
      print('❌ Erreur publication: $e');
      print('📋 Stack: $stack');
      _showError('Erreur lors de la publication: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.lostColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier un objet'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publish,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.accent,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Publier',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _typeButton('lost', '🔴 Perdu', AppTheme.lostColor),
                      _typeButton('found', '🟢 Trouvé', AppTheme.foundColor),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Photo
                _sectionTitle('📸 Photo de l\'objet'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageFile != null
                            ? AppTheme.accent
                            : AppTheme.divider,
                        width: _imageFile != null ? 2 : 1,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded,
                                  color: AppTheme.textSecondary, size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                'Appuie pour ajouter une photo',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre - ✅ AVEC CORRECTIONS
                _sectionTitle('📝 Titre'),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Sac à dos noir Nike',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.accent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description - ✅ AVEC CORRECTIONS
                _sectionTitle('💬 Description'),
                const SizedBox(height: 10),
                TextField(
                  controller: _descController,
                  focusNode: _descFocus,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  maxLines: 5,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Décris l\'objet en détail...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.accent, width: 2),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Catégorie
                _sectionTitle('📦 Catégorie'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = _category == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppTheme.accent : AppTheme.divider,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Couleur
                _sectionTitle('🎨 Couleur principale'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((c) {
                    final selected = _color == c;
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.surface : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppTheme.accent : AppTheme.divider,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: selected ? AppTheme.accent : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Mots-clés
                _sectionTitle('🏷️ Mots-clés'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedKeywords.map((kw) {
                    final selected = _selectedKeywords.contains(kw);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedKeywords.remove(kw);
                          } else {
                            _selectedKeywords.add(kw);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent.withOpacity(0.2) : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppTheme.accent : AppTheme.divider,
                          ),
                        ),
                        child: Text(
                          kw,
                          style: TextStyle(
                            color: selected ? AppTheme.accent : AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Position GPS
                _sectionTitle('📍 Position GPS'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppTheme.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _address.isNotEmpty ? _address : 'Détection en cours...',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_lat == null)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton publier
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _type == 'lost'
                                ? '🔴 Publier + Chercher correspondances'
                                : '🟢 Publier + Chercher correspondances',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Hint matching
                const Center(
                  child: Text(
                    '🤖 L\'app cherchera automatiquement des correspondances',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Overlay loading avec message dynamique
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.accent),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isAnalyzing) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Analyse des objets similaires...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeButton(String value, String label, Color color) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}