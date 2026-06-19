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

## Historique de développement (résumé)

### Étape 2 — Implémentation des fonctionnalités principales

- **Mise en place Firebase**
  - Configuration Firebase via `firebase_options.dart` et initialisation dans `lib/main.dart`.
  - Activation des services nécessaires : **Authentication**, **Cloud Firestore**, **Firebase Cloud Messaging (FCM)** et (pour les médias/stockage) **Firebase Storage**.

- **Authentification utilisateur (Firebase Auth)**
  - Développement des écrans de **connexion** (`login_screen.dart`) et **inscription** (`register_screen.dart`).
  - Utilisation des identifiants Firebase pour identifier l’utilisateur courant dans les appels Firestore.

- **Gestion des trajets (Cloud Firestore)**
  - Création et exploitation de la collection **`rides`**.
  - Implémentation de la récupération des trajets (filtres, ordre par date, statut `open`) via `FirestoreService`.
  - Ajout d’un mécanisme de parcours/itinéraire via **URL Google Maps** (liens stockés/produits dans le modèle de trajet).

- **Écrans et navigation (UI Flutter)**
  - `home_screen.dart` : écran principal avec navigation.
  - `service_screen.dart` : liste des trajets disponibles + filtres.
  - `offer_ride_screen.dart` : formulaire pour proposer un trajet.
  - `profil_screen.dart` : informations utilisateur.
  - `notification_screen.dart` : lecture/affichage côté UI (selon intégration).

- **Notifications (FCM + notifications locales)**
  - Abonnement au topic **`trajets`** au démarrage via `NotificationService`.
  - Traitement des messages FCM en **avant-plan** : affichage via `flutter_local_notifications`.
  - Configuration du channel Android et permissions nécessaires (Android 13+ / iOS).
  - (Traitement en arrière-plan) handler FCM fourni pour les cas où l’app n’est pas au premier plan.

- **Gestion des demandes de trajet (extension du modèle)**
  - Ajout d’une collection **`ride_requests`** pour représenter les demandes (ex. `pending`, `accepted`, `rejected`).
  - Mise en place du flux : envoi d’une demande depuis le passager vers le conducteur, puis mise à jour du statut côté conducteur.

### Étape 3 — Déploiement (mise en production)

- **Préparation des builds de déploiement Flutter**
  - Génération de l’APK/AAB pour Android via les commandes Flutter en mode `release`.
  - Utilisation des configurations Android/Gradle du projet (notamment l’intégration Firebase/Google Services).

- **Déploiement côté distribution**
  - Transmission du build généré vers une plateforme de distribution (ex. installation interne, canal de test, ou publication store selon le processus du projet).
  - Vérification des prérequis Firebase (Auth/Firestore/FCM) pour que les fonctionnalités de notifications et de données soient opérationnelles une fois installée sur appareil réel.

---

## Auteur

- Projet : **app_gostudy** (à compléter si besoin)

---


