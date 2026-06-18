import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ride.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'offer_ride_screen.dart';

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
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.car_rental, size: 64, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Covoiturage Mahajanga - ISSTM & Univ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text('Proposez ou trouvez un trajet', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
        
        // Buttons Action
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
                    // CORRECTION : Utilisation de setState pour réinitialiser le filtre et rafraîchir le flux
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
        
        // Search/Filter Input
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
        
        // Rides List Stream
        Expanded(
          child: StreamBuilder<List<Ride>>(
            stream: _filterUniv != null
                ? _firestoreService.getFilteredRidesStream(originUniv: _filterUniv)
                : _firestoreService.getRidesStream(),
            builder: (context, snapshot) {
              // DIAGNOSTIC TECHNIQUE : Capture l'erreur exacte renvoyée par le moteur Firestore
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
                    'Aucun trajet disponible.\nAssurez-vous que les données existent en base.',
                    textAlign: TextAlign.center,
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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