import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final SupabaseClient _supabase;

  NotificationService(this._supabase)
      : _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Écouter les nouvelles notifications en temps réel
    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      final userId = _supabase.auth.currentUser?.id;
      final filtered = data.where((notif) {
        return notif['utilisateur_id'] == userId && notif['est_lue'] == false;
      }).toList();

      if (filtered.isNotEmpty) {
        _handleNewNotification(filtered);
      }
    });
  }

  void _handleNewNotification(List<Map<String, dynamic>> data) {
    for (var notif in data) {
      _showLocalNotification(
        id: notif['id'].hashCode,
        title: notif['titre'],
        body: notif['message'],
        urgence: notif['urgence'],
      );
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String urgence,
  }) async {
    final priority = urgence == 'Critique'
        ? Priority.high
        : urgence == 'Moyen'
            ? Priority.defaultPriority
            : Priority.low;

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'agronet_channel',
          'AgroNet Notifications',
          importance: urgence == 'Critique'
              ? Importance.high
              : Importance.defaultImportance,
          priority: priority,
        ),
      ),
    );
  }

  // Marquer comme lue
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'est_lue': true}).eq('id', notificationId);
  }

  // Récupérer notifications non lues
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    return await _supabase
        .from('notifications')
        .select()
        .eq('utilisateur_id', _supabase.auth.currentUser?.id ?? '')
        .eq('est_lue', false)
        .order('date_emission', ascending: false);
  }
}
