import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StoryImageUploadResult {
  const StoryImageUploadResult({
    required this.path,
    required this.url,
  });

  final String path;
  final String url;
}

class StoryStorageService {
  StoryStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<StoryImageUploadResult> uploadSceneImage({
    required String uid,
    required String storyId,
    required String sceneId,
    required File file,
  }) async {
    final String extension = _fileExtension(file.path);
    final String path =
        'user_stories/$uid/$storyId/scenes/$sceneId$extension';

    final Reference ref = _storage.ref(path);
    await ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(extension),
        customMetadata: <String, String>{
          'uid': uid,
          'storyId': storyId,
          'sceneId': sceneId,
        },
      ),
    );

    final String url = await ref.getDownloadURL();
    return StoryImageUploadResult(path: path, url: url);
  }

  Future<void> deleteByPath(String path) async {
    if (path.trim().isEmpty) return;
    await _storage.ref(path).delete();
  }

  String _fileExtension(String inputPath) {
    final int dotIndex = inputPath.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    final String ext = inputPath.substring(dotIndex).toLowerCase();
    switch (ext) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
        return ext;
      default:
        return '.jpg';
    }
  }

  String _contentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
