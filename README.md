# app_gostudy (Flutter + Firebase)

Application mobile **Flutter** pour le **covoiturage étudiant** (Mahajanga / ISSTM & universités partenaires). 
Elle permet aux utilisateurs de **se connecter**, **proposer** un trajet, **consulter** les trajets disponibles, et de recevoir des **notifications** quand de nouveaux trajets/demandes sont publiés.

---

## Fonctionnalités

- Authentification **Firebase Authentication**
  - Connexion (login)
  - Inscription (register)
- Gestion des trajets
  - Liste des trajets depuis **Cloud Firestore**
  - Filtrage par université (dans l’écran Services)
  - Proposer un trajet via un formulaire
  - Ouverture de l’itinéraire (Google Maps via URL)
- Notifications
  - Utilisation de **Firebase Cloud Messaging (FCM)**
  - Notifications **locales** via `flutter_local_notifications`
  - Abonnement au topic : **`trajets`**

---

## Technologies utilisées

- **Flutter**
- **Firebase**
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_messaging`
- **Notifications locales**
  - `flutter_local_notifications`
- **Navigation**
  - `MaterialApp` routes : `/login`, `/register`, `/home`

---

## Prérequis

- Flutter installé et configuré
- Un projet Firebase avec :
  - Authentication activée
  - Firestore activé
  - Cloud Messaging (FCM) configuré

---

## Installation et lancement

1) Ouvrir le projet :

```bash
cd app_gostudy
```

2) Récupérer les dépendances :

```bash
flutter pub get
```

3) Configurer Firebase

- Vérifier que `google-services.json` est présent côté Android (dans le projet Flutter)
- Vérifier la configuration de `lib/firebase_options.dart` (générée via `flutterfire configure`)
- (Optionnel) Ajuster la config selon `app_gostudy/firebase.json`

4) Lancer l’application :

```bash
flutter run
```

---

## Notes sur la configuration Firebase

- Les options Firebase sont chargées via : `lib/firebase_options.dart`
- Les notifications reposent sur le topic **`trajets`** (abonnement fait au démarrage dans `NotificationService`).

---

## Structure (principaux écrans)

- `lib/screens/login_screen.dart` : écran de connexion
- `lib/screens/register_screen.dart` : écran d’inscription
- `lib/screens/home_screen.dart` : écran principal avec navigation (BottomNavigationBar)
- `lib/screens/service_screen.dart` : liste des trajets + filtre + bouton “Proposer trajet”
- `lib/screens/offer_ride_screen.dart` : formulaire pour proposer un trajet
- `lib/screens/notification_screen.dart` : affichage/gestion côté UI (selon implémentation)
- `lib/screens/profil_screen.dart` : profil utilisateur

---

## Auteur

- Projet : **app_gostudy** (à compléter si besoin)

---

Si tu veux, je peux aussi ajouter une section “Auteurs / Contributeurs” et un lien vers la maquette/cahier de charge selon ton document.
