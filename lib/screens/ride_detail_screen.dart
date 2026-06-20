import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';
import '../services/firestore_service.dart';

class RideDetailScreen extends StatelessWidget {
  final Ride ride;
  const RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isDriver = ride.driverId == currentUserId;
    final firestoreService = FirestoreService();

    // Formatage de la date et de l'heure du trajet
    final dateStr = "${ride.departureTime.day.toString().padLeft(2, '0')}/${ride.departureTime.month.toString().padLeft(2, '0')}/${ride.departureTime.year}";
    final timeStr = "${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Trajet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte contenant les informations principales du trajet
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: const Text('Point de départ'),
                      subtitle: Text(ride.departurePoint, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.school, color: Colors.orange),
                      title: const Text('Université d\'arrivée'),
                      subtitle: Text(ride.destUniv, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_month, color: Colors.green),
                            title: const Text('Date'),
                            subtitle: Text(dateStr),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: Colors.green),
                            title: const Text('Heure'),
                            subtitle: Text(timeStr),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.event_seat, color: Colors.purple),
                            title: const Text('Places'),
                            subtitle: Text('${ride.seats} disponibles'),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.volunteer_activism, color: Colors.green),
                            title: const Text('Prix'),
                            subtitle: const Text('Gratuit', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECTION DYNAMIQUE POUR LE NUMÉRO DE TÉLÉPHONE
            StreamBuilder<String>(
              stream: firestoreService.getRequestStatusStream(ride.id),
              builder: (context, snapshot) {
                final requestStatus = snapshot.data ?? 'none';
                
                // Le numéro s'affiche si l'utilisateur connecté est le conducteur 
                // OU si le statut de sa demande est 'accepted'
                final bool canSeePhone = isDriver || requestStatus == 'accepted';

                if (canSeePhone) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDriver ? 'Votre numéro (Conducteur) :' : 'Contact du conducteur :',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ride.phoneNumber.isEmpty ? 'Non renseigné' : ride.phoneNumber,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Message affiché lorsque le numéro est masqué (en attente ou pas de demande)
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Le numéro de téléphone du conducteur sera visible uniquement après acceptation de votre demande.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            const Spacer(),

            // BOUTON D'ACTION EN BAS DE L'ÉCRAN (REJOINDRE / STATUT)
            if (!isDriver) // Le bouton ne s'affiche pas si c'est le conducteur qui regarde son propre trajet
              StreamBuilder<String>(
                stream: firestoreService.getRequestStatusStream(ride.id),
                builder: (context, snapshot) {
                  final requestStatus = snapshot.data ?? 'none';

                  if (requestStatus == 'none') {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_car),
                        label: const Text('Rejoindre le trajet'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await firestoreService.sendRideRequest(ride.id, ride.driverId);
                        },
                      ),
                    );
                  } else if (requestStatus == 'pending') {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.hourglass_top),
                        label: const Text('Demande en attente de validation...'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: null, // Désactivé pendant l'attente
                      ),
                    );
                  } else if (requestStatus == 'accepted') {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Demande acceptée ! Bonne route.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Demande refusée.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}