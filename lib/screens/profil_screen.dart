import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../widgets/profile_avatar.dart'; // Importation de ton composant d'avatar interactif

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  // Fonction pour afficher l'alerte de confirmation de déconnexion
  void _afficherDialogueDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit obligatoirement choisir une option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Déconnexion'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter de GoStudy ?'),
          actions: [
            // Bouton Annuler
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ferme uniquement la boîte d'alerte
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            // Bouton Confirmer la déconnexion
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // 1. Ferme l'alerte graphique
                await FirebaseAuth.instance.signOut(); // 2. Coupe la session Firebase Auth
                
                if (!mounted) return;
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login'); // 3. Redirige vers la connexion
                }
              },
              child: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Le FutureBuilder va chercher le document de l'utilisateur dans la collection "users"
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        String nomUtilisateur = "Chargement...";
        String numeroInscription = "Chargement...";
        String? photoUrl;

        // Si la récupération réussit et que le document existe
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            // Extraction du Nom et Prénom
            String nom = data['nom'] ?? '';
            String prenom = data['prenom'] ?? '';
            nomUtilisateur = '$nom $prenom'.trim();
            if (nomUtilisateur.isEmpty) nomUtilisateur = 'Non renseigné';

            // Extraction du numéro d'inscription universitaire
            numeroInscription = data['iduniv'] ?? data['numinscr'] ?? 'Non renseigné';

            // Extraction de l'URL de la photo depuis Firestore
            photoUrl = data['photoUrl'];
          } else {
            // Si le document n'existe pas encore dans Firestore
            nomUtilisateur = user.displayName ?? "Utilisateur GoStudy";
            numeroInscription = "Non disponible";
          }
        }

        // Si Firestore ne contient pas de photo, on utilise celle de Firebase Auth en repli
        photoUrl ??= user.photoURL;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 40),
            
            // ÉLÉMENT 1 : Avatar interactif connecté à ton système d'upload
            Center(
              child: ProfileAvatar(
                userId: user.uid,
                initialPhotoUrl: photoUrl,
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Profil',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 30),
            
            // ÉLÉMENT 2 : Carte des informations utilisateur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.email, 'Email', user.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(
                      Icons.account_box,
                      'Nom d\'utilisateur',
                      nomUtilisateur,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      Icons.numbers,
                      'Numéro d\'inscription',
                      numeroInscription,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(Icons.key, 'UID', user.uid),
                    const SizedBox(height: 12),
                    
                    if (user.emailVerified) ...[
                      _buildInfoRow(Icons.verified, 'Email vérifié', 'Oui'),
                    ] else ...[
                      _buildInfoRow(Icons.warning, 'Email vérifié', 'Non'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // ÉLÉMENT 3 : Bouton Déconnexion avec alerte
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _afficherDialogueDeconnexion(context), // Déclenche le pop-up
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget d'aide pour générer proprement les lignes d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}