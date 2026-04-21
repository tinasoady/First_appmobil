import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';
import '../services/firestore_service.dart';
import 'service_screen.dart';

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _departurePointController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();

  String? _originUniv;
  String? _destUniv;
  TimeOfDay? _departureTime;

  final List<String> _universities = [
    'ISSTM',
    'Université de Mahajanga',
    'ENI Mahajanga',
    'ESTIM Mahajanga',
  ];

  @override
  void initState() {
    super.initState();
    _initDemoRides();
  }

  Future<void> _initDemoRides() async {
    await _firestoreService.addDemoRides();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _departureTime = time);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final departureDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _departureTime!.hour,
        _departureTime!.minute,
      ).add(const Duration(hours: 1)); // Min 1h future

      final user = FirebaseAuth.instance.currentUser;
      final ride = Ride(
        id: '',
        driverId: user?.uid ?? '',
        departurePoint: _departurePointController.text,
        originUniv: _originUniv!,
        destUniv: _destUniv!,
        departureTime: departureDateTime,
        seats: int.parse(_seatsController.text),
        price: double.parse(_priceController.text),
        googleMapsLink: Ride(id: '', driverId: '', departurePoint: '', originUniv: _originUniv!, destUniv: _destUniv!, departureTime: departureDateTime, seats: 0, price: 0).generateMapsLink(),
      );

      await _firestoreService.addRide(ride);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ServiceScreen(showSuccess: true)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposer un Trajet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _departurePointController,
                decoration: const InputDecoration(
                  labelText: 'Point de départ',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _originUniv,
                decoration: const InputDecoration(
                  labelText: 'Université de départ',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                items: _universities.map((univ) => DropdownMenuItem(
                  value: univ,
                  child: Text(univ),
                )).toList(),
                onChanged: (value) => setState(() => _originUniv = value),
                validator: (value) => value == null ? 'Sélectionnez' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _destUniv,
                decoration: const InputDecoration(
                  labelText: 'Université d\'arrivée',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                items: _universities.map((univ) => DropdownMenuItem(
                  value: univ,
                  child: Text(univ),
                )).toList(),
                onChanged: (value) => setState(() => _destUniv = value),
                validator: (value) => value == null ? 'Sélectionnez' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Heure de départ',
                  prefixIcon: const Icon(Icons.access_time),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: _pickTime,
                  ),
                ),
                onTap: _pickTime,
                controller: TextEditingController(
                  text: _departureTime?.format(context) ?? '',
                ),
                validator: (value) => _departureTime == null ? 'Sélectionnez' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Places disponibles',
                  prefixIcon: Icon(Icons.event_seat),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => int.tryParse(value ?? '') == null ? 'Nombre valide' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix par passager (Ar)',
                  prefixIcon: Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => double.tryParse(value ?? '') == null ? 'Nombre valide' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('Proposer le trajet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

