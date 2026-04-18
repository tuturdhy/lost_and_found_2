import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Ton Cloud Name et Upload Preset
  static final cloudinary = CloudinaryPublic('dzxhiyrpi', 'lost_found_preset');

  /// Upload une image et retourne l'URL publique
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,  // ✅ MAJUSCULE : Image (pas image)
          folder: 'lost_and_found',
        ),
      );
      print('✅ Upload réussi: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('❌ Erreur upload Cloudinary: $e');
      return null;
    }
  }
}