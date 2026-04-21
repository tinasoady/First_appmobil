import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride.dart';
import '../services/firestore_service.dart';
import 'offer_ride_screen.dart';

class ServiceScreen extends StatefulWidget {
  final bool showSuccess;
  const ServiceScreen({super.key, this.showSuccess = false});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _firestoreService = FirestoreService();
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
    _firestoreService.addDemoRides(); // Ensure demos
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
        // Buttons
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
                  onPressed: () => _filterUniv = null, // TODO: Search screen
                  icon: const Icon(Icons.search),
                  label: const Text('Chercher'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        // Search/Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Filtrer par université',
              prefixIcon: const Icon(Icons.filter_list),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _filterUniv = value.isEmpty ? null : value),
          ),
        ),
        const SizedBox(height: 16),
        // Rides List
        Expanded(
          child: StreamBuilder<List<Ride>>(
            stream: _filterUniv != null
                ? _firestoreService.getFilteredRidesStream(originUniv: _filterUniv)
                : _firestoreService.getRidesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucun trajet disponible'));
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
                              Expanded(child: Text('${ride.originUniv} → ${ride.destUniv}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                              Text('${ride.price.toStringAsFixed(0)} Ar', style: const TextStyle(fontSize: 18, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              Expanded(child: Text(ride.departurePoint)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              Expanded(child: Text(ride.departureTime.toString().substring(0, 16))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.event_seat, size: 16),
                              Text('${ride.seats} places'),
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
                                onPressed: () {
                                  // TODO: Join ride
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

