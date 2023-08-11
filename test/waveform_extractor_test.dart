import 'package:flutter_test/flutter_test.dart';
import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/model/waveform_progress.dart';
import 'package:waveform_extractor/src/waveform_extractor_method_channel.dart';
import 'package:waveform_extractor/src/waveform_extractor_platform_interface.dart';
import 'package:waveform_extractor/waveform_extractor.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWaveformExtractorPlatform
    with MockPlatformInterfaceMixin
    implements WaveformExtractorPlatform {
  @override
  Future<Waveform> extractWaveform(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> extractWaveformDataOnly(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearCache({String? audioPath, String? cacheKey}) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearAllWaveformCache() {
    throw UnimplementedError();
  }
}

void main() {
  final WaveformExtractorPlatform initialPlatform =
      WaveformExtractorPlatform.instance;

  test('$MethodChannelWaveformExtractor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWaveformExtractor>());
  });

  test('extractWaveform', () async {
    WaveformExtractor waveformExtractorPlugin = WaveformExtractor();
    MockWaveformExtractorPlatform fakePlatform =
        MockWaveformExtractorPlatform();
    WaveformExtractorPlatform.instance = fakePlatform;

    expect(await waveformExtractorPlugin.extractWaveform(''), {});
  });
}
