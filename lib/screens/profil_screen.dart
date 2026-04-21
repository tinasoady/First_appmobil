import 'package:flutter/material.dart';


class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Profil', style: TextStyle(fontSize: 24)),
            Text('Détails du profil utilisateur'),
          ],
        ),
      ),
    );
  }
}