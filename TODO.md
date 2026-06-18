# TODO - Notifications (FCM + Local)

- [x] Mettre à jour `lib/services/notification_service.dart` :
  - [x] Nettoyer la structure (suppression commentaire parasite)
  - [x] Gérer `message.notification == null` en fallback sur `message.data`
  - [x] Ajouter gestion du clic sur notification (`onMessageOpenedApp`)
  - [x] Initialiser local notifications proprement (iOS/Android) + settings & callbacks compatibles v17
  - [x] S’assurer channel Android cohérent et icône valide

- [ ] Mettre à jour `lib/main.dart` : initialisation propre du service

- [ ] Lancer : `flutter clean && flutter pub get && flutter analyze`


