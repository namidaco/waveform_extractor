import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/model/waveform_progress.dart';

import 'waveform_extractor_platform_interface.dart';

/// An implementation of [WaveformExtractorPlatform] that uses method channels.
class MethodChannelWaveformExtractor extends WaveformExtractorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('waveform_extractor');

  final eventChannel = const EventChannel('waveform_extractor/stream');

  @override
  Future<Waveform> extractWaveform(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    final shouldPostStream = onProgress != null;
    Map<Object?, Object?>? finalWaveform;

    final waveform = await methodChannel.invokeMethod(
      'extractWaveform',
      {
        "path": source,
        "useCache": useCache,
        "cacheKey": cacheKey,
        "samplePerSecond": samplePerSecond,
        "postProgress": shouldPostStream,
      },
    );
    // ------------------------------------
    if (shouldPostStream) {
      final completer = Completer<Map<Object?, Object?>?>();
      eventChannel.receiveBroadcastStream().listen(
        (event) {
          final prog = event is Map<Object?, Object?>
              ? event.cast<String, Object>()
              : null;
          if (prog != null) {
            final waveform = prog["amplitudesData"];
            final waveprog = WaveformProgress.fromMap(prog);
            if (waveprog.source == source && waveform is List<Object?>) {
              onProgress(
                WaveformProgress(
                  source: source,
                  type: EventType.done,
                  operation: null,
                  percentage: 100,
                ),
              );
              completer.complete(prog);
            } else {
              onProgress(waveprog);
            }
          }
        },
      );

      finalWaveform = await completer.future;
    } else {
      finalWaveform = waveform;
    }
    // ------------------------------------

    if (finalWaveform == null) {
      throw Exception('Error Extracting Waveform');
    }
    final map = finalWaveform.cast<String, Object>();
    return Waveform.fromMap(map);
  }

  @override
  Future<List<int>> extractWaveformDataOnly(
    String source, {
    bool useCache = true,
    String? cacheKey,
    int? samplePerSecond,
    void Function(WaveformProgress progress)? onProgress,
  }) async {
    final shouldPostStream = onProgress != null;
    List<Object?>? finalWaveform;

    final waveform = await methodChannel.invokeMethod(
      'extractWaveformDataOnly',
      {
        "path": source,
        "useCache": useCache,
        "cacheKey": cacheKey,
        "samplePerSecond": samplePerSecond,
        "postProgress": shouldPostStream,
      },
    );

    // ------------------------------------
    if (shouldPostStream) {
      final completer = Completer<List<Object?>?>();
      eventChannel.receiveBroadcastStream().listen(
        (event) {
          final prog = event is Map<Object?, Object?>
              ? event.cast<String, Object>()
              : null;
          if (prog != null) {
            final waveform = prog["waveform"];
            final waveprog = WaveformProgress.fromMap(prog);
            if (waveprog.source == source && waveform is List<Object?>) {
              onProgress(
                WaveformProgress(
                  source: source,
                  type: EventType.done,
                  operation: null,
                  percentage: 100,
                ),
              );
              completer.complete(waveform);
            } else {
              onProgress(waveprog);
            }
          }
        },
      );

      finalWaveform = await completer.future;
    } else {
      finalWaveform = waveform;
    }
    // ------------------------------------

    if (finalWaveform == null) {
      throw Exception('Error Extracting Waveform');
    }
    return finalWaveform.cast<int>();
  }

  @override
  Future<void> clearCache({String? audioPath, String? cacheKey}) async {
    assert(audioPath != null || cacheKey != null,
        'audioPath or cacheKey should be provided');

    await methodChannel.invokeMethod('clearCache', {
      "audioPath": audioPath,
      "cacheKey": cacheKey,
    });
  }

  @override
  Future<void> clearAllWaveformCache() async {
    await methodChannel.invokeMethod('clearAllWaveformCache');
  }
}
