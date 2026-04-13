import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../domain/scene_model.dart';
import '../domain/story_model.dart';

class StoryExportService {
  Future<String?> exportStory({
    required StoryModel story,
    required List<SceneModel> scenes,
  }) async {
    try {
      if (scenes.isEmpty) return null;

      final Directory tempDir = await getTemporaryDirectory();
      final Directory exportDir = Directory('${tempDir.path}/story_export');

      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      await exportDir.create(recursive: true);

      final List<File> segmentFiles = <File>[];

      for (int i = 0; i < scenes.length; i++) {
        final SceneModel scene = scenes[i];

        final File? imageFile = await _prepareFile(
          source: scene.imageUrl.trim().isNotEmpty
              ? scene.imageUrl.trim()
              : scene.imagePath.trim(),
          exportDir: exportDir,
          fileName: 'scene_${i.toString().padLeft(2, '0')}',
          defaultExtension: '.jpg',
        );

        if (imageFile == null || !await imageFile.exists()) {
          continue;
        }

        final File? audioFile = await _prepareFile(
          source: scene.narrationAudioUrl.trim().isNotEmpty
              ? scene.narrationAudioUrl.trim()
              : scene.narrationAudioPath.trim(),
          exportDir: exportDir,
          fileName: 'audio_${i.toString().padLeft(2, '0')}',
          defaultExtension: '.mp3',
        );

        final double durationSeconds = _sceneDuration(scene);
        final File segmentFile =
        File('${exportDir.path}/segment_${i.toString().padLeft(2, '0')}.mp4');

        final String command = audioFile != null && await audioFile.exists()
            ? _buildImageAndAudioSegmentCommand(
          imagePath: imageFile.path,
          audioPath: audioFile.path,
          outputPath: segmentFile.path,
        )
            : _buildImageWithSilentAudioSegmentCommand(
          imagePath: imageFile.path,
          outputPath: segmentFile.path,
          durationSeconds: durationSeconds,
        );

        await FFmpegKit.execute(command);

        if (await segmentFile.exists()) {
          segmentFiles.add(segmentFile);
        }
      }

      if (segmentFiles.isEmpty) {
        return null;
      }

      final File concatFile = File('${exportDir.path}/segments.txt');
      final StringBuffer concatBuffer = StringBuffer();

      for (final File file in segmentFiles) {
        final String safePath = file.path.replaceAll("'", r"'\''");
        concatBuffer.writeln("file '$safePath'");
      }

      await concatFile.writeAsString(concatBuffer.toString());

      final String outputPath =
          '${exportDir.path}/${_safeFileName(story.title)}.mp4';

      final String finalCommand =
          '-f concat -safe 0 -i "${concatFile.path}" '
          '-c:v libx264 -c:a aac -pix_fmt yuv420p -movflags +faststart '
          '-y "$outputPath"';

      await FFmpegKit.execute(finalCommand);

      final File outputFile = File(outputPath);
      if (await outputFile.exists()) {
        return outputPath;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  double _sceneDuration(SceneModel scene) {
    if (scene.audioDurationMs > 0) {
      return scene.audioDurationMs / 1000.0;
    }
    if (scene.durationSeconds > 0) {
      return scene.durationSeconds.toDouble();
    }
    return 4.0;
  }

  String _buildImageAndAudioSegmentCommand({
    required String imagePath,
    required String audioPath,
    required String outputPath,
  }) {
    return '-y '
        '-loop 1 -i "$imagePath" '
        '-i "$audioPath" '
        '-shortest '
        '-vf "scale=720:1280:force_original_aspect_ratio=decrease,'
        'pad=720:1280:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-r 30 '
        '-c:v libx264 '
        '-c:a aac '
        '-b:a 128k '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '"$outputPath"';
  }

  String _buildImageWithSilentAudioSegmentCommand({
    required String imagePath,
    required String outputPath,
    required double durationSeconds,
  }) {
    return '-y '
        '-loop 1 -t $durationSeconds -i "$imagePath" '
        '-f lavfi -t $durationSeconds -i anullsrc=channel_layout=stereo:sample_rate=44100 '
        '-shortest '
        '-vf "scale=720:1280:force_original_aspect_ratio=decrease,'
        'pad=720:1280:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
        '-r 30 '
        '-c:v libx264 '
        '-c:a aac '
        '-b:a 128k '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '"$outputPath"';
  }

  Future<File?> _prepareFile({
    required String source,
    required Directory exportDir,
    required String fileName,
    required String defaultExtension,
  }) async {
    try {
      if (source.trim().isEmpty) return null;

      if (_isHttpUrl(source)) {
        final Uri uri = Uri.parse(source);
        final http.Response response = await http.get(uri);
        if (response.statusCode != 200) return null;

        final String extension = _inferExtension(source, defaultExtension);
        final File file = File('${exportDir.path}/$fileName$extension');
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      }

      final File localFile = File(source);
      if (await localFile.exists()) {
        return localFile;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isHttpUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _inferExtension(String source, String fallback) {
    final String lower = source.toLowerCase();

    if (lower.contains('.png')) return '.png';
    if (lower.contains('.jpg')) return '.jpg';
    if (lower.contains('.jpeg')) return '.jpeg';
    if (lower.contains('.webp')) return '.webp';
    if (lower.contains('.mp3')) return '.mp3';
    if (lower.contains('.m4a')) return '.m4a';
    if (lower.contains('.aac')) return '.aac';
    if (lower.contains('.wav')) return '.wav';
    if (lower.contains('.ogg')) return '.ogg';

    return fallback;
  }

  String _safeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}