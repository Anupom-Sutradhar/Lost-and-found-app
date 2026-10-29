import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Upload a post image to the post-images bucket.
  /// Path layout: `{userId}/{uuid}.jpg` — required by RLS policies.
  Future<String> uploadPostImage(File file, String userId) async {
    final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    final safeExt = (ext.isEmpty) ? 'jpg' : ext;
    final filename = '${_uuid.v4()}.$safeExt';
    final path = '$userId/$filename';

    await _client.storage.from(AppConstants.postImagesBucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: _mimeFor(safeExt),
            upsert: false,
          ),
        );

    return _client.storage
        .from(AppConstants.postImagesBucket)
        .getPublicUrl(path);
  }

  /// Upload (or overwrite) a profile image.
  /// Path: `{userId}.jpg` — one per user.
  Future<String> uploadProfileImage(File file, String userId) async {
    final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    final safeExt = (ext.isEmpty) ? 'jpg' : ext;
    final path = '$userId.$safeExt';

    await _client.storage.from(AppConstants.profileImagesBucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: _mimeFor(safeExt),
            upsert: true,
          ),
        );

    // Bust cache by appending a query param.
    final url = _client.storage
        .from(AppConstants.profileImagesBucket)
        .getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Best-effort delete by public URL.
  Future<void> deleteByUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Public URL format:
      //   {supabaseUrl}/storage/v1/object/public/{bucket}/{path}
      final segments = uri.pathSegments;
      final pubIndex = segments.indexOf('public');
      if (pubIndex == -1 || pubIndex + 2 > segments.length) return;
      final bucket = segments[pubIndex + 1];
      final path = segments.sublist(pubIndex + 2).join('/');
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {/* swallow */}
  }

  String _mimeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
