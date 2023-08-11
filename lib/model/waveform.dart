class Waveform {
  final List<int> waveformData;
  final List<int> amplitudesForFirstSecond;
  final Duration duration;
  final String source;

  const Waveform({
    required this.waveformData,
    required this.amplitudesForFirstSecond,
    required this.duration,
    required this.source,
  });

  factory Waveform.fromMap(Map<String, dynamic> map) {
    return Waveform(
      waveformData: List<int>.from(map["amplitudesData"] ?? <int>[]),
      amplitudesForFirstSecond:
          List<int>.from(map["amplitudesForFirstSecond"] ?? <int>[]),
      duration: Duration(milliseconds: map["duration"] as int? ?? 0),
      source: map["source"] as String? ?? '',
    );
  }
}
