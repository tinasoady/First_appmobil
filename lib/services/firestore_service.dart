import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ridesCollection = 'rides';

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
}

