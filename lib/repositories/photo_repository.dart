import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Camera and photo library through image_picker. Photos are shrunk to
/// a small JPEG and kept as base64 on the user document, so no Cloud
/// Storage bucket (Blaze plan) is needed.
class PhotoRepository {
  PhotoRepository({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxBytes = 200 * 1024;

  /// Returns the photo as base64, or null when the user cancels.
  Future<String?> pick({required bool camera}) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );
    } on PlatformException catch (e) {
      throw StateError(switch (e.code) {
        'camera_access_denied' =>
          'Camera access is off. Allow it in Settings to take a photo.',
        'photo_access_denied' =>
          'Photo access is off. Allow it in Settings to choose a photo.',
        'no_available_camera' => 'No camera was found on this device.',
        _ => 'Could not open the ${camera ? 'camera' : 'photo library'}.',
      });
    }
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw StateError('That photo is too large. Try another one.');
    }
    return base64Encode(bytes);
  }
}
