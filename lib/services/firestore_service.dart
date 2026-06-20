import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Noms des collections Firestore
  final String _ridesCollection = 'rides';
  final String _requestsCollection = 'requests';

  // 1. AJOUTER UN TRAJET
  Future<void> addRide(Ride ride) async {
    await _firestore.collection(_ridesCollection).add(ride.toFirestore());
  }

  // 2. ÉCOUTER TOUS LES TRAJETS (Utilisé dans service_screen.dart)
  Stream<List<Ride>> getRidesStream() {
    return _firestore
        .collection(_ridesCollection)
        .orderBy('departureTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ride.fromFirestore(doc))
            .toList());
  }

  // 3. ÉCOUTER LES TRAJETS RÉCENTS (Utilisé dans home_screen.dart)
  Stream<List<Ride>> getRecentRidesStream() {
    return _firestore
        .collection(_ridesCollection)
        .orderBy('departureTime', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ride.fromFirestore(doc))
            .toList());
  }

  // 4. ÉCOUTER LE STATUT D'UNE DEMANDE UNIQUE (Pour le bouton et le numéro de téléphone)
  Stream<String> getRequestStatusStream(String rideId) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value('none');

    return _firestore
        .collection(_requestsCollection)
        .where('rideId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 'none';
          return snapshot.docs.first.data()['status'] ?? 'pending';
        });
  }

  // 5. ENVOYER UNE DEMANDE DE RÉSERVATION (Rejoindre le trajet)
  Future<void> sendRideRequest(String rideId, String driverId) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection(_requestsCollection).add({
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': userId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 6. ÉCOUTER LES DEMANDES REÇUES (Conducteur - Utilisé dans notification_screen.dart)
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_requestsCollection)
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // 7. ÉCOUTER LES DEMANDES ENVOYÉES (Passager - Utilisé dans notification_screen.dart)
  Stream<List<Map<String, dynamic>>> getSentRequestsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_requestsCollection)
        .where('passengerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // 8. ACCEPTER UNE DEMANDE DE TRAJET (Appelée par notification_screen.dart)
  Future<void> acceptRideRequest(String requestId, String rideId) async {
    // Passer le statut de la requête à 'accepted'
    await _firestore
        .collection(_requestsCollection)
        .doc(requestId)
        .update({'status': 'accepted'});

    // Décrémenter automatiquement le nombre de places disponibles (-1)
    await _firestore
        .collection(_ridesCollection)
        .doc(rideId)
        .update({'seats': FieldValue.increment(-1)});
  }

  // 9. REFUSER UNE DEMANDE DE TRAJET (Si utilisée par notification_screen.dart)
  Future<void> rejectRideRequest(String requestId) async {
    await _firestore
        .collection(_requestsCollection)
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // 10. METTRE À JOUR LE STATUT D'UNE DEMANDE (Générique)
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore
        .collection(_requestsCollection)
        .doc(requestId)
        .update({'status': status});
  }

  // 11. AJOUTER DES TRAJETS DE TEST (Utilisé dans service_screen.dart)
  Future<void> addDemoRides() async {
    final List<Map<String, dynamic>> demo = [
      {
        'driverId': 'demo_driver_1',
        'departurePoint': 'Analakely',
        'destUniv': 'Université de Mahajanga',
        'departureTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'seats': 3,
        'phoneNumber': '0341122233',
      },
      {
        'driverId': 'demo_driver_2',
        'departurePoint': 'Sotema',
        'destUniv': 'Université de Mahajanga',
        'departureTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 4))),
        'seats': 4,
        'phoneNumber': '0324455566',
      }
    ];

    for (var rideData in demo) {
      await _firestore.collection(_ridesCollection).add(rideData);
    }
  }
}