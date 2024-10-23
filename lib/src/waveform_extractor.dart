import 'dart:math' as math;

import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/model/waveform_progress.dart';

import 'waveform_extractor_platform_interface.dart';

class WaveformExtractor {
  /// {@template waveform_extraction}
  /// - Extracts waveform data for a given audio source.
  /// - Source could be a path to a file or a network url.
  /// - Estimated extraction time:
  ///   - 1 second for a 3min 20s audio.
  ///   - 20 seconds for a 1 hour audio.
  /// - Using onProgress will provide you detailed progress about:
  ///   - percentage.
  ///   - ProgressOperation (`processing`, `decoding`, `downloading`).
  ///   - EventType (`start`, `progress`, `stop`, `done`).
  /// - Example usage:
  ///   ```dart
  ///   final waveformExtractor = WaveformExtractor();
  ///   final audioFile = File(audioPath);
  ///   final waveform = await waveformExtractor.extractWaveform(audioFile.path, onProgress: (progress) => print('Progress: $progress'));
  ///   print("Waveform Data: $waveform");
  ///   ```
  /// {@endtemplate}
  Future<Waveform> extractWaveform(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    return WaveformExtractorPlatform.instance.extractWaveform(
      source,
      useCache: useCache,
      cacheKey: cacheKey,
      samplePerSecond: samplePerSecond,
      onProgress: onProgress,
    );
  }

  /// {@macro waveform_extraction}
  Future<List<int>> extractWaveformDataOnly(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    return WaveformExtractorPlatform.instance.extractWaveformDataOnly(
      source,
      useCache: useCache,
      cacheKey: cacheKey,
      samplePerSecond: samplePerSecond,
      onProgress: onProgress,
    );
  }

  /// Clears cached waveform file for a given [audioPath] or [cacheKey].
  Future<void> clearCache({String? audioPath, String? cacheKey}) async {
    return WaveformExtractorPlatform.instance
        .clearCache(audioPath: audioPath, cacheKey: cacheKey);
  }

  /// Clears all cached waveform files.
  Future<void> clearAllWaveformCache() async {
    return WaveformExtractorPlatform.instance.clearAllWaveformCache();
  }

  /// Returns sampleRate inversily propotional with audio duration.
  ///
  /// for example, with a [scaleFactor] == 0.4:
  /// - 1 minute audio => 314 samples.
  /// - 2 minute audio => 247 samples.
  /// - 10 minute audio => 36 samples.
  ///
  /// Maximum value is [maxSampleRate] while minimum is 1.
  ///
  /// Increasing [scaleFactor] means quickly approach minimum sampleRate.
  static int getSampleRateFromDuration({
    required Duration audioDuration,
    int maxSampleRate = 400,
    double scaleFactor = 0.4,
  }) {
    final durInSeconds = audioDuration.inSeconds;
    final scaledDuration = scaleFactor * durInSeconds;
    final scaledSampleRate = maxSampleRate * (math.exp(-scaledDuration / 100));
    final samplePerSecond = scaledSampleRate.clamp(1, maxSampleRate).round();
    return samplePerSecond;
  }
}
