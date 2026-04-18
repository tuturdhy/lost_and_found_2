import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final notifService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllAsRead(userId),
            child: const Text(
              'Tout lire',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: notifService.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          final notifs = snapshot.data ?? [];

          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final notif = notifs[i];
              return GestureDetector(
                onTap: () => notifService.markAsRead(notif.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: notif.isRead
                        ? AppTheme.cardBg
                        : AppTheme.cardBg.withBlue(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notif.isRead
                          ? AppTheme.divider
                          : notif.color.withOpacity(0.4),
                      width: notif.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: notif.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(notif.icon, color: notif.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: notif.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: notif.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd/MM à HH:mm')
                                  .format(notif.createdAt),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
