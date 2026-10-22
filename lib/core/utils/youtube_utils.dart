import '../constants/app_constants.dart';

abstract final class YoutubeUtils {
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Extracts the 11-char id from `youtube.com/watch?v=`, `youtu.be/`,
  /// `youtube.com/shorts/` and `youtube.com/embed/` links. Returns null if
  /// the link is not a recognised YouTube video URL.
  static String? extractVideoId(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null) return null;

    final host = uri.host.toLowerCase().replaceFirst('www.', '').replaceFirst('m.', '');
    String? id;
    if (host == 'youtu.be') {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (host == 'youtube.com' || host == 'music.youtube.com') {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty && segs.first == 'watch') {
        id = uri.queryParameters['v'];
      } else if (segs.length >= 2 && (segs.first == 'shorts' || segs.first == 'embed' || segs.first == 'live')) {
        id = segs[1];
      }
    }
    return (id != null && _id.hasMatch(id)) ? id : null;
  }

  static String thumbnailUrl(String videoId) => AppConstants.youtubeThumbnail.replaceFirst('{id}', videoId);

  static String watchUrl(String videoId) => AppConstants.youtubeWatch.replaceFirst('{id}', videoId);
}
