import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Gère les notifications reçues lorsque l'application est complètement fermée.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pas de print en production.
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'trajets_channel';
  static const String channelName = 'Nouveaux Trajets';
  static const String channelDescription =
      'Notifications pour les nouveaux trajets publiés';

  Future<void> initNotifications() async {
    // 1) Permission FCM (iOS + Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2) Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3) Initialisation local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Router ici si nécessaire.
      },
    );

    // 4) Création channel Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5) Foreground: affiche une notif locale si un message FCM arrive
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;

      final String? title =
          notification?.title ?? message.data['title']?.toString();
      final String? body =
          notification?.body ?? message.data['body']?.toString();

      if (title == null && body == null) return;

      showLocalNotification(
        title: title ?? 'Notification',
        body: body ?? '',
      );
    });

    // 6) Quand l'utilisateur tape sur une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Router ici si nécessaire.
    });

    // 7) Topic
    await _firebaseMessaging.subscribeToTopic('trajets');
  }

  // === MÉTHODE SÉPARÉE POUR LES NOTIFICATIONS LOCALES MANUELLES ===
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID unique
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
        ),
      ),
    );
  }
}