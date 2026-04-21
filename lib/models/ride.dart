import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String departurePoint; // e.g., "Porte d'Orléans"
  final String originUniv; // e.g., "Paris-Saclay"
  final String destUniv; // e.g., "Sorbonne"
  final DateTime departureTime;
  final int seats;
  final double price;
  final String status; // 'open', 'full', 'completed'
  final String? googleMapsLink;

  Ride({
    required this.id,
    required this.driverId,
    required this.departurePoint,
    required this.originUniv,
    required this.destUniv,
    required this.departureTime,
    required this.seats,
    required this.price,
    this.status = 'open',
    this.googleMapsLink,
  });

  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ride(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      departurePoint: data['departurePoint'] ?? '',
      originUniv: data['originUniv'] ?? '',
      destUniv: data['destUniv'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      seats: data['seats'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'open',
      googleMapsLink: data['googleMapsLink'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'departurePoint': departurePoint,
      'originUniv': originUniv,
      'destUniv': destUniv,
      'departureTime': Timestamp.fromDate(departureTime),
      'seats': seats,
      'price': price,
      'status': status,
      'googleMapsLink': googleMapsLink,
    };
  }

  // Generate Google Maps directions URL
  String generateMapsLink() {
    // Mock coords: Paris-Saclay (48.7175,2.2298), Sorbonne (48.8497,2.3508), etc.
    final coords = {
      'ISSTM': '-15.358,46.318',
      'Université de Mahajanga': '-15.350,46.320',
      'ENI Mahajanga': '-15.355,46.315',
      'ESTIM Mahajanga': '-15.352,46.317',
    };
    final origin = coords[originUniv] ?? '-15.358,46.318';
    final dest = coords[destUniv] ?? '-15.350,46.320';
    return 'https://www.google.com/maps/dir/?api=1&origin=$departurePoint+$originUniv&destination=$destUniv&travelmode=driving';
  }
}

