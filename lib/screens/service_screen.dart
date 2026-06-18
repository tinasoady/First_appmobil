import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importé pour récupérer l'ID utilisateur unique
import '../models/ride.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'offer_ride_screen.dart';
import '../widgets/profile_avatar.dart';

class ServiceScreen extends StatefulWidget {
  final bool showSuccess;
  const ServiceScreen({super.key, this.showSuccess = false});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _firestoreService = FirestoreService();
  final _notificationService = NotificationService();
  final _searchController = TextEditingController();
  String? _filterUniv;

  @override
  void initState() {
    super.initState();
    if (widget.showSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trajet ajouté avec succès!')),
          );
        }
      });
    }
    _firestoreService.addDemoRides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _proposeRide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfferRideScreen()),
    );
  }

  void _launchMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupération dynamique de l'ID de l'utilisateur connecté
    // (Si pas encore de système de login actif, remplace par une String fixe pour tester, ex: "test_user_123")
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // En-tête (Header) avec le Logo de GoStudy et l'Avatar de profil
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Ligne supérieure : Logo à gauche, Profil à droite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logoGostudy.png', 
                    height: 60, // Ajusté légèrement pour s'aligner joliment avec l'avatar
                    fit: BoxFit.contain,
                  ),
                  
                  // Section Avatar connectée à Firestore
                  if (userId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('utilisateur').doc(userId).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          );
                        }

                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          photoUrl = data?['photoUrl'];
                        }

                        // On applique un léger scale pour l'intégrer discrètement dans la barre supérieure
                        return Transform.scale(
                          scale: 0.85,
                          child: ProfileAvatar(
                            userId: userId,
                            initialPhotoUrl: photoUrl,
                          ),
                        );
                      },
                    )
                  else
                    // Fallback visuel si l'utilisateur n'est pas détecté/connecté
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Proposez ou trouvez un trajet', 
                style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        // Boutons d'action (Proposer / Tout afficher)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proposeRide,
                  icon: const Icon(Icons.add),
                  label: const Text('Proposer trajet'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterUniv = null;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tout afficher'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        
        // Champ de saisie pour la recherche / filtrage
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Filtrer par université (Ex: ISSTM)',
              prefixIcon: const Icon(Icons.filter_list),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear), 
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filterUniv = null;
                  });
                }
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _filterUniv = value.trim().isEmpty ? null : value.trim()),
          ),
        ),
        const SizedBox(height: 16),
        
        // Liste des trajets alimentée par Firestore et filtrée localement
        Expanded(
          child: StreamBuilder<List<Ride>>(
            stream: _firestoreService.getRidesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Erreur système Firestore :\n${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun trajet disponible en base.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final allRides = snapshot.data!;
              
              final rides = allRides.where((ride) {
                if (_filterUniv == null || _filterUniv!.isEmpty) return true;
                
                final query = _filterUniv!.toLowerCase();
                final origin = ride.originUniv.toLowerCase();
                final dest = ride.destUniv.toLowerCase();
                
                return origin.contains(query) || dest.contains(query);
              }).toList();

              if (rides.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun trajet ne correspond à votre recherche.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${ride.originUniv} → ${ride.destUniv}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                                )
                              ),
                              Text('${ride.price.toStringAsFixed(0)} Ar', style: const TextStyle(fontSize: 18, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Expanded(child: Text(ride.departurePoint)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 4),
                              Expanded(child: Text(ride.departureTime.toString().substring(0, 16))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.event_seat, size: 16),
                              const SizedBox(width: 4),
                              Text('${ride.seats} places disponibles'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _launchMaps(ride.googleMapsLink ?? ride.generateMapsLink()),
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('Itinéraire'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _firestoreService.sendRideRequest(ride.id, ride.driverId);
                                    
                                    await _notificationService.showLocalNotification(
                                      title: 'Demande envoyée ! 🚗',
                                      body: 'Votre demande pour le trajet vers ${ride.destUniv} a bien été transmise.',
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Demande envoyée au conducteur avec succès !'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur : ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.thumb_up, size: 16),
                                label: const Text('Rejoindre'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}