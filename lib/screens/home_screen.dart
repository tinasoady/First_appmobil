import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/ride.dart';
import 'service_screen.dart';
import 'notification_screen.dart';
import 'profil_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<String> titles = ['Accueil', 'Services', 'Notifications', 'Profil'];
  final user = FirebaseAuth.instance.currentUser;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          StreamBuilder<List<Ride>>(
            stream: FirestoreService().getRecentRidesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.car_rental_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun trajet récent disponible'),
                      Text('Les trajets apparaîtront ici', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              final rides = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.car_rental, color: Colors.blue),
                      ),
                      title: Text('${ride.originUniv} → ${ride.destUniv}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${ride.departurePoint} • ${ride.departureTime.toString().substring(11, 16)}'),
                          Text('${ride.seats} places • ${ride.price.toStringAsFixed(0)} Ar'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ServiceScreen()),
                        ),
                        child: const Text('Voir'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const ServiceScreen(),
          const NotificationScreen(),
          const ProfilScreen(),
        ],
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
            icon: Icon(Icons.car_rental),
            label: 'Covoiturage',
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


