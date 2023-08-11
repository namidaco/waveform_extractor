import 'package:flutter/material.dart';
import 'dart:async';

import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/model/waveform_progress.dart';
import 'package:waveform_extractor/waveform_extractor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Waveform? _currentWaveform;
  final List<double> _downscaledWaveformList = [];
  int _downscaledTargetSize = 100;

  Duration? _currentExtractionTime;
  Duration? _currentDownloadTime;
  int _currentIndex = 0;
  double _barWidth = 2;
  final horizontalPadding = 24.0;
  final _waveformExtractor = WaveformExtractor();
  final links = [
    "https://actions.google.com/sounds/v1/alarms/assorted_computer_sounds.ogg",
    "https://actions.google.com/sounds/v1/alarms/dosimeter_alarm.ogg",
    "https://actions.google.com/sounds/v1/alarms/phone_alerts_and_rings.ogg",
    "https://actions.google.com/sounds/v1/ambiences/ambient_hum_air_conditioner.ogg",
    "https://actions.google.com/sounds/v1/alarms/mechanical_clock_ring.ogg",
    "https://actions.google.com/sounds/v1/alarms/dinner_bell_triangle.ogg",
    "https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg",
    "https://actions.google.com/sounds/v1/ambiences/coffee_shop.ogg",
  ];

  @override
  void initState() {
    super.initState();
    generateWaveform((sources) => sources[_currentIndex]);
  }

  void _resetValues() {
    _downscaledWaveformList
      ..clear()
      ..addAll(List<double>.filled(_downscaledTargetSize, 0.1));
    _currentWaveform = null;
    _currentExtractionTime = null;
    _currentDownloadTime = null;
  }

  Future<void> generateWaveform(
      String Function(List<String> sources) source) async {
    _resetValues();
    setState(() {});
    final downloadStart = DateTime.now();
    DateTime? downloadEnd;
    final time = await executeWithTimeDifference(() async {
      _currentWaveform = await _waveformExtractor.extractWaveform(
        source(links),
        onProgress: (progress) {
          if (progress.operation != ProgressOperation.downloading) {
            downloadEnd = DateTime.now();
          }
        },
      );
    });
    _currentDownloadTime = downloadEnd?.difference(downloadStart);
    _currentExtractionTime = time - (_currentDownloadTime ?? Duration.zero);
    updateDownscaledList(_currentWaveform?.waveformData, _downscaledTargetSize);
    setState(() {});
  }

  void updateDownscaledList(List<int>? list, int targetSize) {
    final downscaled = list?.reduceListSize(targetSize: targetSize);
    _downscaledWaveformList
      ..clear()
      ..addAll(downscaled ?? []);
    _barWidth = (MediaQuery.of(context).size.width - horizontalPadding) /
        (downscaled?.length ?? 1) *
        0.45;
  }

  Future<Duration> executeWithTimeDifference<T>(
      FutureOr<T> Function() fn) async {
    final start = DateTime.now();
    await fn();
    final end = DateTime.now();
    return end.difference(start);
  }

  Widget getText(String title, dynamic subtitle) {
    return RichText(
      text: TextSpan(
        text: "$title: ",
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        children: [
          TextSpan(
            text: subtitle.toString(),
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _waveformExtractor.clearAllWaveformCache();
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WaveformExtractor Example App'),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ListView(
            children: [
              const SizedBox(height: 24.0),
              SizedBox(
                height: MediaQuery.of(context).size.width,
                child: PageView.builder(
                  itemCount: links.length,
                  onPageChanged: (value) async {
                    _currentIndex = value;
                    await generateWaveform((sources) => sources[value]);
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 40, 40, 40),
                          borderRadius: BorderRadius.circular(24.0)),
                      width: MediaQuery.of(context).size.width,
                      child: index == _currentIndex
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                ..._downscaledWaveformList
                                    .map((e) => AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          decoration: BoxDecoration(
                                              color: Colors.brown,
                                              borderRadius:
                                                  BorderRadius.circular(6.0)),
                                          height: (e * 12).clamp(
                                              1.0,
                                              MediaQuery.of(context)
                                                  .size
                                                  .width),
                                          width: _barWidth,
                                        )),
                              ],
                            )
                          : const SizedBox(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: links
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          radius: 6.0,
                          backgroundColor:
                              _currentIndex == e.key ? null : Colors.grey,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24.0),
              Slider.adaptive(
                min: 40,
                max: 400,
                divisions: 400 - 40,
                label: _downscaledTargetSize.toString(),
                value: _downscaledTargetSize.toDouble(),
                onChanged: (valueDouble) {
                  final value = valueDouble.toInt();
                  _downscaledTargetSize = value;
                  updateDownscaledList(
                      _currentWaveform?.waveformData ?? [], value);
                  setState(
                    () {},
                  );
                },
              ),
              getText("Source", _currentWaveform?.source),
              const SizedBox(height: 6.0),
              getText("Duration", _currentWaveform?.duration),
              const SizedBox(height: 6.0),
              getText(
                  "Waveform count", _currentWaveform?.waveformData.length ?? 0),
              const SizedBox(height: 6.0),
              getText("Download Time", _currentDownloadTime),
              const SizedBox(height: 6.0),
              getText("Extraction Time", _currentExtractionTime),
              const SizedBox(height: 6.0),
              getText(
                  "Total Time",
                  (_currentDownloadTime ?? Duration.zero) +
                      (_currentExtractionTime ?? Duration.zero)),
              const SizedBox(height: 12.0),
              ElevatedButton.icon(
                onPressed: () async =>
                    await generateWaveform((sources) => sources[_currentIndex]),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Re Extract'),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}

extension ListSize<N extends num> on List<N> {
  List<double> reduceListSize({
    required int targetSize,
  }) {
    if (length > targetSize) {
      final finalList = <double>[];
      final chunk = length / targetSize;
      final iterationsCount = targetSize;
      for (int i = 0; i < iterationsCount; i++) {
        final part = skip((chunk * i).floor()).take(chunk.floor());
        final sum = part.fold<double>(
            0, (previousValue, element) => previousValue + element);
        final peak = sum / part.length;
        finalList.add(peak);
      }
      return finalList;
    } else {
      return map((e) => e.toDouble()).toList();
    }
  }
}
