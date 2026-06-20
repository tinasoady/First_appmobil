import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 💡 Ajouté pour récupérer les détails du trajet
import '../services/firestore_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Notifications', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue.shade600,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.download_rounded), text: "Demandes reçues"),
              Tab(icon: Icon(Icons.upload_rounded), text: "Mes retours"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet 1 : Demandes reçues (Tu es conducteur)
            _buildRequestsList(_firestoreService.getIncomingRequestsStream(), isIncoming: true),
            
            // Onglet 2 : Retours de tes demandes (Tu es passager)
            _buildRequestsList(_firestoreService.getSentRequestsStream(), isIncoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(Stream<List<Map<String, dynamic>>> stream, {required bool isIncoming}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune notification pour le moment',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final String requestId = request['id'];
            final String rideId = request['rideId'] ?? '';
            final String status = request['status'] ?? 'pending';

            Color statusColor = Colors.orange;
            String statusText = "En attente";
            if (status == 'accepted') {
              statusColor = Colors.green;
              statusText = "Accepté";
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusText = "Refusé";
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isIncoming ? Icons.person : Icons.directions_car, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              isIncoming ? "Demande de covoiturage" : "Statut de votre demande",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIncoming
                          ? "Un étudiant souhaite réserver une place dans votre véhicule pour votre trajet."
                          : "Le conducteur a mis à jour le statut de votre demande de réservation.",
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),

                    // 💡 BLOC INTÉGRÉ : Affichage du numéro du conducteur si la demande est acceptée (Mes retours)
                    if (!isIncoming && status == 'accepted') ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('rides').doc(rideId).get(),
                        builder: (context, rideSnapshot) {
                          if (rideSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                                ),
                              ),
                            );
                          }

                          if (rideSnapshot.hasData && rideSnapshot.data!.exists) {
                            final rideData = rideSnapshot.data!.data() as Map<String, dynamic>;
                            final phoneNumber = rideData['phoneNumber'] ?? 'Non renseigné';

                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.green, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Contact du conducteur :',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          phoneNumber,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Impossible de charger le numéro du conducteur.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ],
                    
                    // Actions disponibles uniquement pour les demandes reçues en attente
                    if (isIncoming && status == 'pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await _firestoreService.updateRequestStatus(requestId, 'rejected');
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Refuser"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                // Exécute l'acceptation sécurisée et décrémente la place
                                await _firestoreService.acceptRideRequest(requestId, rideId);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Demande acceptée !')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Accepter"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}