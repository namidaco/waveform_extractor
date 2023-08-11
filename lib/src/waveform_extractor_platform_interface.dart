import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/model/waveform_progress.dart';

import 'waveform_extractor_method_channel.dart';

abstract class WaveformExtractorPlatform extends PlatformInterface {
  /// Constructs a WaveformExtractorPlatform.
  WaveformExtractorPlatform() : super(token: _token);

  static final Object _token = Object();

  static WaveformExtractorPlatform _instance = MethodChannelWaveformExtractor();

  /// The default instance of [WaveformExtractorPlatform] to use.
  ///
  /// Defaults to [MethodChannelWaveformExtractor].
  static WaveformExtractorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WaveformExtractorPlatform] when
  /// they register themselves.
  static set instance(WaveformExtractorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Waveform> extractWaveform(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    throw UnimplementedError('extractWaveform() has not been implemented.');
  }

  Future<List<int>> extractWaveformDataOnly(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    throw UnimplementedError(
        'extractWaveformDataOnly() has not been implemented.');
  }

  Future<void> clearCache({String? audioPath, String? cacheKey}) async {
    throw UnimplementedError('clearCache() has not been implemented.');
  }

  Future<void> clearAllWaveformCache() async {
    throw UnimplementedError(
        'clearAllWaveformCache() has not been implemented.');
  }
}
