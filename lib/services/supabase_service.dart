import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'item-images';

  static Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final filePath = '$userId/$fileName';

      await _client.storage
          .from(_bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      rethrow;
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _client.storage.from(_bucketName).remove([filePath]);
      }
    } catch (e) {
      print('Error deleting image from Supabase: $e');
    }
  }

  static Future<String> updateImage(
    File newImageFile,
    String? oldImageUrl,
    String userId,
  ) async {
    try {
      if (oldImageUrl != null &&
          oldImageUrl.isNotEmpty &&
          !oldImageUrl.contains('placeholder')) {
        await deleteImage(oldImageUrl);
      }

      // Upload new image
      return await uploadImage(newImageFile, userId);
    } catch (e) {
      print('Error updating image: $e');
      rethrow;
    }
  }
}
