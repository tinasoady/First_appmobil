import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- AJOUTÉ pour récupérer l'ID de l'utilisateur connecté
import '../models/ride.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ridesCollection = 'rides';
  final String _requestsCollection = 'ride_requests'; // <-- AJOUTÉ : Nouvelle collection pour les demandes

  // Stream all/open rides (oldest first)
  Stream<List<Ride>> getRidesStream() {
    return _firestore
        .collection(_ridesCollection)
        .where('status', isEqualTo: 'open')
        .orderBy('departureTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList());
  }

  // Stream recent/open rides (newest first)
  Stream<List<Ride>> getRecentRidesStream() {
    return _firestore
        .collection(_ridesCollection)
        .where('status', isEqualTo: 'open')
        .orderBy('departureTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList());
  }

  // Query rides by univ or time
  Stream<List<Ride>> getFilteredRidesStream({
    String? originUniv,
    String? destUniv,
    DateTime? afterTime,
  }) {
    Query query = _firestore.collection(_ridesCollection).where('status', isEqualTo: 'open');
    
    if (originUniv != null) query = query.where('originUniv', isEqualTo: originUniv);
    if (destUniv != null) query = query.where('destUniv', isEqualTo: destUniv);
    if (afterTime != null) query = query.where('departureTime', isGreaterThan: Timestamp.fromDate(afterTime));

    return query.orderBy('departureTime').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addRide(Ride ride) async {
    await _firestore
        .collection(_ridesCollection)
        .add(ride.toFirestore());
  }

  Future<void> updateRide(String rideId, Ride ride) async {
    await _firestore
        .collection(_ridesCollection)
        .doc(rideId)
        .update(ride.toFirestore());
  }

  Future<void> deleteRide(String rideId) async {
    await _firestore.collection(_ridesCollection).doc(rideId).delete();
  }

  // ==========================================
  // NOUVELLE FONCTION : ENVOYER UNE DEMANDE
  // ==========================================
  Future<void> sendRideRequest(String rideId, String driverId) async {
    // 1. Récupérer l'ID du passager actuellement connecté
    final String? passengerId = FirebaseAuth.instance.currentUser?.uid;

    if (passengerId == null) {
      throw Exception("Utilisateur non connecté. Impossible de rejoindre le trajet.");
    }

    // 2. Ajouter la demande dans la collection 'ride_requests'
    await _firestore.collection(_requestsCollection).add({
      'rideId': rideId,
      'passengerId': passengerId,
      'driverId': driverId,
      'status': 'pending', // Statut initial : en attente ('pending', 'accepted', 'rejected')
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Add sample demo rides if collection empty (for testing)
  Future<void> addDemoRides() async {
    final snapshot = await _firestore.collection(_ridesCollection).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final demoRides = [
        Ride(
          id: '',
          driverId: 'demo_user',
          departurePoint: 'Cité Ampasy',
          originUniv: 'ISSTM',
          destUniv: 'Université de Mahajanga',
          departureTime: DateTime.now().add(const Duration(hours: 2)),
          seats: 4,
          price: 5000,
        ),
        Ride(
          id: '',
          driverId: 'demo_user2',
          departurePoint: 'Marche Antsiranana',
          originUniv: 'Université de Mahajanga',
          destUniv: 'ENI Mahajanga',
          departureTime: DateTime.now().add(const Duration(hours: 4)),
          seats: 3,
          price: 3000,
        ),
      ];
      for (final ride in demoRides) {
        final rideWithLink = Ride(
          id: ride.id,
          driverId: ride.driverId,
          departurePoint: ride.departurePoint,
          originUniv: ride.originUniv,
          destUniv: ride.destUniv,
          departureTime: ride.departureTime,
          seats: ride.seats,
          price: ride.price,
          googleMapsLink: ride.generateMapsLink(),
        );
        await addRide(rideWithLink);
      }
    }
  }

  // =========================================================================
  // ÉCOUTER LES NOTIFICATIONS (DEMANDES REÇUES EN TANT QUE CONDUCTEUR)
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      return Stream.value([]);
    }

    // On récupère les demandes où l'utilisateur connecté est le conducteur (driverId)
    return _firestore
        .collection(_requestsCollection)
        .where('driverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id, // On garde l'ID du document pour pouvoir l'accepter/refuser
                ...data,
              };
            }).toList());
  }

  // =========================================================================
  // ACCEPTER OU REFUSER UNE DEMANDE
  // =========================================================================
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    await _firestore
        .collection(_requestsCollection)
        .doc(requestId)
        .update({
      'status': newStatus, // 'accepted' ou 'rejected'
    });
  }

}