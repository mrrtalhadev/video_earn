/// Result of the admin "Load & verify" step: metadata read from the player.
class VideoVerifyResult {
  const VideoVerifyResult({required this.durationSeconds, required this.title});

  final int durationSeconds;
  final String title;
}
