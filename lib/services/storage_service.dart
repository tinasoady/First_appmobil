import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// 1. Permet à l'utilisateur de choisir une image dans sa galerie
  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compresse l'image à 50% pour économiser la bande passante et le stockage
      maxWidth: 400,    // Redimensionne la largeur max (suffisant pour un avatar)
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null; // L'utilisateur a annulé la sélection
  }

  /// 2. Upload l'image sur Firebase Storage et met à jour l'URL dans Firestore
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Définition de l'emplacement sur Storage : dossier 'profiles' / nom du fichier 'userId.jpg'
      // Utiliser le userId écrase automatiquement l'ancienne photo, évitant les fichiers orphelins
      Reference ref = _storage.ref().child('profiles').child('$userId.jpg');

      // Envoi du fichier binaire
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Récupération de l'URL publique générée par Firebase
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Mise à jour du document de l'utilisateur dans Firestore avec le nouveau lien
      await _firestore.collection('utilisateur').doc(userId).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print("Erreur lors de l'upload de l'image : $e");
      return null;
    }
  }
}