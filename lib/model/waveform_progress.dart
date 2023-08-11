class WaveformProgress {
  final String source;
  final EventType? type;
  final ProgressOperation? operation;
  final int? percentage;

  const WaveformProgress({
    required this.source,
    required this.type,
    required this.operation,
    required this.percentage,
  });

  factory WaveformProgress.fromMap(Map<String, dynamic> map) {
    return WaveformProgress(
      source: map["path"] as String? ?? '',
      type: _eventMap[map["event"]],
      operation: _operationMap[map["operation"]],
      percentage: map["progress"] as int?,
    );
  }

  @override
  String toString() {
    return "WaveformProgress(source: $source, type: $type, operation: $operation, percentage: $percentage)";
  }
}

final _eventMap = <String, EventType>{
  "start": EventType.start,
  "progress": EventType.progress,
  "stop": EventType.stop,
  "done": EventType.done,
};

final _operationMap = <String, ProgressOperation>{
  "PROCESSING": ProgressOperation.processing,
  "DECODING": ProgressOperation.decoding,
  "DOWNLOADING": ProgressOperation.downloading,
};

enum EventType {
  start,
  progress,
  stop,
  done,
}

enum ProgressOperation {
  processing,
  decoding,
  downloading,
}
