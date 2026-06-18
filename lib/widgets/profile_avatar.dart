import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ProfileAvatar extends StatefulWidget {
  final String userId;
  final String? initialPhotoUrl;

  const ProfileAvatar({
    super.key, 
    required this.userId, 
    this.initialPhotoUrl,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final StorageService _storageService = StorageService();
  String? _currentPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = widget.initialPhotoUrl;
  }

  Future<void> _changePhoto() async {
    // 1. Sélection de l'image
    final File? image = await _storageService.pickImage();
    if (image == null) return; // Annulé

    setState(() => _isLoading = true);

    // 2. Upload et récupération du lien
    final String? newUrl = await _storageService.uploadProfilePicture(widget.userId, image);

    if (newUrl != null) {
      setState(() {
        _currentPhotoUrl = newUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour !'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour de la photo.'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _changePhoto, // Désactivé pendant le chargement
      child: Stack(
        alignment: Alignment.center,
        children: [
          // L'avatar circulaire
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                ? NetworkImage(_currentPhotoUrl!)
                : null,
            child: _currentPhotoUrl == null || _currentPhotoUrl!.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          
          // Indicateur visuel pendant le téléversement
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            
          // Petit badge en forme d'appareil photo en bas à droite
          if (!_isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}