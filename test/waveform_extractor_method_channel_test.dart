import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveform_extractor/src/waveform_extractor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWaveformExtractor platform = MethodChannelWaveformExtractor();
  const MethodChannel channel = MethodChannel('waveform_extractor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('extractWaveform', () async {
    expect(await platform.extractWaveform(''), {});
  });
}
