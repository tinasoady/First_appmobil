import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabContents = [
      // Home
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenue, ${user?.email ?? 'Utilisateur'}!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            const Text('Écran d\'accueil'),
          ],
        ),
      ),
      // Services
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Services', style: TextStyle(fontSize: 24)),
            Text('Liste des services disponibles'),
          ],
        ),
      ),
      // Profil
     
      // Notifications
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Notifications', style: TextStyle(fontSize: 24)),
            Text('Aucune notification pour le moment'),
          ],
        ),
      ),

       Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Profil', style: TextStyle(fontSize: 24)),
            Text('Email: ${user?.email ?? 'N/A'}'),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabContents,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedIconTheme: const IconThemeData(size: 30, color: Colors.blue),
        unselectedIconTheme: const IconThemeData(size: 24, color: Colors.grey),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          
        ],
      ),
    );
  }
}


