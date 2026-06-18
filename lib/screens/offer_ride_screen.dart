import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart'; // Importation de l'accueil indispensable pour la redirection

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
  final _timeController = TextEditingController();

  String? _destUniv;
  TimeOfDay? _departureTime;

  // Corrigé : Utilisation de '=' au lieu de ':'
  bool _isLoading = false;

  final List<String> _universities = [
    'ISSTM',
    'Université de Mahajanga',
    'ENI Mahajanga',
    'ESTIM Mahajanga',
  ];

  @override
  void dispose() {
    _departurePointController.dispose();
    _seatsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _departureTime = time;
        _timeController.text = time.format(context);
      });
    }
  }

  Future<void> _submit() async {
    // Bloque instantanément si un envoi est déjà en cours
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      // On passe en mode chargement et on met à jour l'interface
      setState(() => _isLoading = true);

      try {
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
          departurePoint: _departurePointController.text.trim(),
          originUniv: '', 
          destUniv: _destUniv!,
          departureTime: departureDateTime,
          seats: int.parse(_seatsController.text),
          price: 0.0, // Gratuit
          googleMapsLink: Ride(
            id: '', 
            driverId: '', 
            departurePoint: _departurePointController.text.trim(), 
            originUniv: '', 
            destUniv: _destUniv!, 
            departureTime: departureDateTime, 
            seats: 0, 
            price: 0,
          ).generateMapsLink(),
        );

        // 1. Sauvegarde dans Firestore (attend la confirmation du serveur)
        await _firestoreService.addRide(ride);
        
        // 2. Redirection sécurisée si le widget est toujours actif
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            // Corrigé : Utilisation de HomeScreen() en accord avec ton import
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false, // Supprime tout l'historique pour éviter les retours en arrière
          );
          
          // 3. Message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trajet proposé avec succès ! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (error) {
        // En cas d'erreur serveur, on réactive le bouton et on alerte l'utilisateur
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la publication : $error'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
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
              // Point de départ
              TextFormField(
                controller: _departurePointController,
                decoration: const InputDecoration(
                  labelText: 'Point de départ',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Université d'arrivée
              DropdownButtonFormField<String>(
                initialValue: _destUniv,
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
                validator: (value) => value == null ? 'Sélectionnez l\'université' : null,
              ),
              const SizedBox(height: 16),

              // Heure de départ
              TextFormField(
                controller: _timeController,
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
                validator: (value) => _departureTime == null ? 'Sélectionnez l\'heure' : null,
              ),
              const SizedBox(height: 16),

              // Places disponibles
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Places disponibles',
                  prefixIcon: Icon(Icons.event_seat),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => int.tryParse(value ?? '') == null ? 'Nombre valide requis' : null,
              ),
              const SizedBox(height: 24),

              // Badge Covoiturage Gratuit
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volunteer_activism, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'COVOITURAGE 100% GRATUIT',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Soumettre dynamique
              ElevatedButton.icon(
                // Si _isLoading est vrai, onPressed reçoit 'null', ce qui désactive le clic
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Création en cours...' : 'Proposer le trajet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}