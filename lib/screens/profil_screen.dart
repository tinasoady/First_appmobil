import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
 
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 40),
        // Profile Header
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green,
            child: CircleAvatar(
              radius: 58,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
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
        // User Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.email, 'Email', user.email ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.account_box, 'Nom d\'utilisateur', user.displayName ?? user.email?.split('@')[0]?.toUpperCase() ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.key, 'UID', user.uid),
                if (user.emailVerified) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.verified, 'Email vérifié', 'Oui'),
                ] else ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.warning, 'Email vérifié', 'Non'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Logout Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ),
      ],
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
