import 'package:cloudinary_public/cloudinary_public.dart';

/// Service for uploading images to Cloudinary.
///
/// Uses unsigned uploads with a public preset — no API key/secret exposed.
class CloudinaryService {
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dotkgmg0a',
    'second_mart_upload',
    cache: false,
  );

  /// Uploads a single image file and returns its secure URL.
  ///
  /// [filePath] — absolute path to the image on disk.
  /// [onProgress] — optional callback for upload progress (0.0 → 1.0).
  static Future<String> uploadImage(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'second_mart',
          resourceType: CloudinaryResourceType.Image,
        ),
        onProgress: onProgress != null
            ? (count, total) => onProgress(count / total)
            : null,
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      throw Exception('Cloudinary upload failed: ${e.message}');
    }
  }

  /// Uploads multiple image files and returns a list of secure URLs.
  ///
  /// Images are uploaded sequentially so progress can be tracked per-image.
  /// [filePaths] — list of absolute paths.
  /// [onImageUploaded] — called after each image with (index, totalCount, url).
  static Future<List<String>> uploadMultipleImages(
    List<String> filePaths, {
    void Function(int index, int total, String url)? onImageUploaded,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < filePaths.length; i++) {
      final url = await uploadImage(filePaths[i]);
      urls.add(url);
      onImageUploaded?.call(i + 1, filePaths.length, url);
    }

    return urls;
  }
}
