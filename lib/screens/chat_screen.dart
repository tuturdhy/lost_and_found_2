import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';  // ✅ Importer depuis models/
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar; // ✅ NOUVEAU
  final String itemId;
  final String itemTitle;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar = '', // ✅ Valeur par défaut
    required this.itemId,
    required this.itemTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _chatService = ChatService();
  final _scrollController = ScrollController();
  late String _chatId;
  late String _currentUserId;
  late String _currentUserName;
  bool _isOtherUserOnline = false; // ✅ Statut en ligne (optionnel)

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _currentUserId = user.uid;
    _currentUserName = user.displayName ?? 'Utilisateur';
    _chatId = _chatService.getChatId(_currentUserId, widget.otherUserId);
    
    // ✅ Marquer les messages comme lus quand on ouvre la conversation
    _markMessagesAsRead();
    
    // ✅ Écouter le statut en ligne de l'autre utilisateur (optionnel)
    _listenToOnlineStatus();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ Marquer tous les messages non-lus comme lus
  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(
      chatId: _chatId,
      userId: _currentUserId,
    );
  }

  /// ✅ Écouter si l'autre utilisateur est en ligne (optionnel)
  void _listenToOnlineStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            final lastSeen = snap.data()?['lastSeen'] as Timestamp?;
            if (lastSeen != null) {
              final diff = DateTime.now().difference(lastSeen.toDate());
              setState(() {
                _isOtherUserOnline = diff.inMinutes < 2; // En ligne si vu il y a <2min
              });
            }
          }
        });
  }

  Future<void> _sendMessage() async {
  final text = _msgController.text.trim();
  
  // Debug : vérifier l'état
  print('📤 _sendMessage appelé - text: "$text" - chatId: $_chatId');
  
  if (text.isEmpty) {
    print('⚠️ Message vide, annulation');
    return;
  }
  
  try {
    final messageText = _msgController.text;
    _msgController.clear();
    
    print('📡 Appel sendMessage...');
    
    await _chatService.sendMessage(
      chatId: _chatId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderAvatar: FirebaseAuth.instance.currentUser?.photoURL ?? '',
      text: messageText,
      itemId: widget.itemId,
      itemTitle: widget.itemTitle,  // ✅ Requis
      participants: [_currentUserId, widget.otherUserId],
    );
    
    print('✅ Message envoyé avec succès');
    
    // Scroll vers le bas
    if (mounted && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  } catch (e, stack) {
    print('❌ Erreur envoi message: $e');
    print('📋 Stack: $stack');
    // Afficher l'erreur à l'utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // ✅ Avatar de l'autre personne
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surface,
                  backgroundImage: widget.otherUserAvatar.isNotEmpty
                      ? NetworkImage(widget.otherUserAvatar)
                      : null,
                  child: widget.otherUserAvatar.isEmpty
                      ? Text(
                          widget.otherUserName.isNotEmpty
                              ? widget.otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                // ✅ Point vert si en ligne (optionnel)
                if (_isOtherUserOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ED573),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // ✅ Nom de l'autre personne + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName, // ✅ Affiche le VRAI nom (pas "Conversation")
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _isOtherUserOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOtherUserOnline
                        ? const Color(0xFF2ED573)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bouton info conversation (optionnel)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showChatInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Bande info de l'objet concerné
          if (widget.itemTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.surface,
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'À propos de : ${widget.itemTitle}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Naviguer vers l'objet
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: widget.itemId)));
                    },
                    child: const Text('Voir',
                        style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                  ),
                ],
              ),
            ),

          // ✅ Liste des messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💬', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Commence la conversation !',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sois poli et respectueux 👋',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _currentUserId;
                    return _buildMessage(msg, isMe);
                  },
                );
              },
            ),
          ),

          // ✅ Zone de saisie du message
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton pièce jointe (optionnel)
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded,
                        color: AppTheme.textSecondary),
                    onPressed: () {
                      // TODO: Ouvrir le picker d'images
                      // _pickAndSendImage();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton envoyer
                 // Bouton envoyer — toujours actif visuellement
GestureDetector(
  onTap: () {
    print('👆 Bouton envoyé cliqué');
    _sendMessage();
  },
  child: Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppTheme.accent,  // ✅ Toujours la couleur active
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(
      Icons.send_rounded,
      color: Colors.white,  // ✅ Toujours blanc
      size: 20,
    ),
  ),
),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Widget pour afficher un message (bulle de chat)
  Widget _buildMessage(MessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar de l'expéditeur (si ce n'est pas moi)
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surface,
              backgroundImage: msg.senderAvatar?.isNotEmpty == true
                  ? NetworkImage(msg.senderAvatar!)
                  : null,
              child: msg.senderAvatar?.isEmpty != false
                  ? Text(
                      msg.senderName.isNotEmpty
                          ? msg.senderName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Nom de l'expéditeur (pour les messages reçus)
                if (!isMe && msg.senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.senderName,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Bulle de message
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.accent : AppTheme.cardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Heure + statut de lecture
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.readBy?.contains(widget.otherUserId) == true
                             ? Icons.done_all_rounded 
                              : Icons.check_rounded,
                          color: msg.readBy?.contains(widget.otherUserId) == true
                              ? const Color(0xFF2ED573) // Vert si lu
                              : AppTheme.textSecondary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Espace pour aligner les messages envoyés
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// ✅ Menu info de la conversation (optionnel)
  void _showChatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.surface,
                    child: Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isOtherUserOnline)
                    const Text(
                      'En ligne',
                      style: TextStyle(
                        color: Color(0xFF2ED573),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.red),
              title: const Text('Bloquer cet utilisateur',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter le blocage
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter la suppression
              },
            ),
          ],
        ),
      ),
    );
  }
}