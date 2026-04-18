import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Bouton "Tout marquer comme lu"
          StreamBuilder<int>(
            stream: chatService.getUnreadChatsCount(currentUserId),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return count > 0
                  ? IconButton(
                      icon: const Icon(Icons.done_all_rounded),
                      tooltip: 'Tout marquer comme lu',
                      onPressed: () => chatService.markAllChatsAsRead(currentUserId),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Contacte quelqu\'un depuis un objet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppTheme.divider, height: 1),
            itemBuilder: (_, i) {
              final chat = chats[i];
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              
              // ✅ Récupérer le nom de l'autre personne (stocké dans le chat)
              final otherUserName = chat['otherUserName'] ?? 'Utilisateur';
              final otherUserAvatar = chat['otherUserAvatar'] ?? '';
              
              final lastMessage = chat['lastMessage'] ?? '';
              final lastMessageAt = chat['lastMessageAt'] as Timestamp?;
              
              // ✅ Compter les messages non-lus pour CETTE conversation
              final unreadCount = (chat['unreadCount'] as int?) ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.surface,
                      backgroundImage: otherUserAvatar.isNotEmpty
                          ? NetworkImage(otherUserAvatar)
                          : null,
                      child: otherUserAvatar.isEmpty
                          ? Text(
                              otherUserName.isNotEmpty
                                  ? otherUserName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    // ✅ Badge rouge de messages non-lus
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  // ✅ Afficher le NOM de l'autre personne (pas "Conversation")
                  otherUserName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  lastMessage,
                  style: TextStyle(
                    color: unreadCount > 0
                        ? AppTheme.textPrimary  // Gras si non-lu
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMessageAt != null)
                      Text(
                        DateFormat('HH:mm').format(lastMessageAt.toDate()),
                        style: TextStyle(
                          color: unreadCount > 0
                              ? AppTheme.accent  // Couleur accent si non-lu
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    if (chat['lastMessageFromMe'] == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.done_all_rounded,
                            color: AppTheme.accent, size: 16),
                      ),
                  ],
                ),
                onTap: () async {
                  // ✅ Marquer les messages comme lus AVANT de naviguer
                  await chatService.markMessagesAsRead(
                    chatId: chat['id'] ?? '',
                    userId: currentUserId,
                  );
                  
                  // Naviguer vers la conversation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,  // ✅ Nom correct
                        otherUserAvatar: otherUserAvatar,
                        itemId: chat['itemId'] ?? '',
                        itemTitle: chat['itemTitle'] ?? 'Objet',
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  // Optionnel : menu pour supprimer la conversation
                  _showChatOptions(context, chat['id'] ?? '');
                },
              );
            },
          );
        },
      ),
    );
  }

  // Menu options pour une conversation (optionnel)
  void _showChatOptions(BuildContext context, String chatId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Supprimer la conversation',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter la suppression dans ChatService
                // ChatService().deleteChat(chatId);
              },
            ),
          ],
        ),
      ),
    );
  }
}