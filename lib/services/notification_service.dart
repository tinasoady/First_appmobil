import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pas de print en production.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _passengerRequestsSubscription;

  static const String channelId = 'trajets_channel';
  static const String channelName = 'Nouveaux Trajets';
  static const String channelDescription =
      'Notifications pour les nouveaux trajets publiés';

  Future<void> initNotifications() async {
    // 1) Permission FCM
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

    // 5) Foreground: notification locale si un message FCM arrive
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

    // 7) Topic global
    await _firebaseMessaging.subscribeToTopic('trajets');
    
    // 8) Lancer automatiquement l'écoute si l'utilisateur est déjà connecté au démarrage
    listenToRequestUpdates();
  }

  // === ÉCOUTER LE RETOUR CONDUCTEUR (MÉTHODE 1) ===
  void listenToRequestUpdates() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _passengerRequestsSubscription?.cancel();

    _passengerRequestsSubscription = FirebaseFirestore.instance
        .collection('ride_requests')
        .where('passengerId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // Déclenché uniquement lors d'une MODIFICATION du document en base
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) return;

          final String status = data['status'] ?? 'pending';

          if (status == 'accepted') {
            showLocalNotification(
              title: 'Trajet accepté ! 🎉',
              body: 'Le conducteur a validé votre demande. Bon voyage !',
            );
          } else if (status == 'rejected') {
            showLocalNotification(
              title: 'Trajet décliné 😕',
              body: 'Le conducteur a refusé votre demande pour ce trajet.',
            );
          }
        }
      }
    });
  }

  void stopListeningToRequestUpdates() {
    _passengerRequestsSubscription?.cancel();
    _passengerRequestsSubscription = null;
  }

  // === MÉTHODE POUR AFFICHAGE LOCAL ===
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
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