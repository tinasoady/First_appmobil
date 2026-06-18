import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import indispensable pour lire la base de données

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

        // Si la récupération réussit et que le document existe
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            // Extraction du Nom et Prénom (plus besoin de découper l'email !)
            String nom = data['nom'] ?? '';
            String prenom = data['prenom'] ?? '';
            nomUtilisateur = '$nom $prenom'.trim();
            if (nomUtilisateur.isEmpty) nomUtilisateur = 'Non renseigné';

            // Extraction du numéro d'inscription universitaire
            numeroInscription = data['iduniv'] ?? data['numinscr'] ?? 'Non renseigné';
          } else {
            // Si le document n'existe pas encore dans Firestore
            nomUtilisateur = user.displayName ?? "Utilisateur GoStudy";
            numeroInscription = "Non disponible";
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 40),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green,
                child: CircleAvatar(
                  radius: 58,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.email, 'Email', user.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    
                    // Affichage du vrai Nom d'utilisateur issu de Firestore
                    _buildInfoRow(
                      Icons.account_box,
                      'Nom d\'utilisateur',
                      nomUtilisateur,
                    ),
                    const SizedBox(height: 12),

                    // Affichage du numéro d'inscription universitaire issu de Firestore
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
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
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