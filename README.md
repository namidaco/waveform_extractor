# waveform_extractor
![waveform](https://github.com/namidaco/waveform_extractor/assets/85245079/64939e23-35d7-49c9-823b-b9b9ee043c0c)

A Lightweight dart library for extracting waveform data from audio streams using Amplituda.


### Platforms Support:
- Android: ✅

## Installation
1. Add as dependency
2. in `android/build.gradle`:
```
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' } // <-- add this
    }
}
allprojects {
    repositories {
        google()
        jcenter()
        mavenCentral()
        maven { url 'https://jitpack.io' } // <-- add this
    }
}
```

## Usage
- Basic Usage:
```dart
final waveformExtractor = WaveformExtractor();
final audioSourceFile = audioPath; // source could be a path to local file
final audioSourceNetwork = audioUrl; // or a network url
final result = await waveformExtractor.extractWaveform(audioSourceFile);
print("Waveform: $result");

```
- Available Data:
```dart
final result = await waveformExtractor.extractWaveform(audioFile.path);
final List<int> waveformData = result.waveformData;
final List<int> amplitudesForFirstSecond = result.amplitudesForFirstSecond;
final Duration duration = result.duration;
print("Waveform Data: $waveform");
print("Waveform Data (first second): $amplitudesForFirstSecond");
print("Waveform Audio Duration: $duration");
```

- With Progress:
```dart
waveformExtractor.extractWaveform(
    source,
    onProgress: (progress) {
       final percentage = progress.percentage; // current percentage (0-100)
       final operation = progress.operation; // the type of operation (processing, decoding, downloading)
       final source = progress.source; // the current source being extracted.
       final type = progress.type; // the type of event (start, progress, stop, done)
       print("Progress $progress");
     },
    );
```

- Caching:

```dart
// Caching is useful to avoid unnecessary re-extractions. 
_waveformExtractor.extractWaveform(
    source,
    useCache: true, // caching is enabled by default.
    cacheKey: 'my_unique_key', // optional cache key used for storing output data, defaulted to hashcode of source path.
    );

// Clearing cache key:
_waveformExtractor.clearCache(
  audioPath: audioPath, // audio source if you have't specied cacheKey before
  cacheKey: cacheKey, // clears specific cache key
);

// Clearing all cache:
_waveformExtractor.clearAllWaveformCache();

```
- Compressing:
```dart
// Compressing is a good choice for long audios, as the resulted data would be huge; causing, possibly, memory overload or jank
final staticSamples = 4; // use default sample for all audios
final dynamicSamples = _waveformExtractor.getSampleRateFromDuration(audioDuration: audioDuration); // or dynamically change depending on audio duration
_waveformExtractor.extractWaveform(
    source,
    samplesPerSecond: dynamicSamples,
    );
```

## Benchmarks
- waveform_extractor is extremely fast, thanks to the inlying ffmpeg implementations made by Amplituda
- Estimated extraction time:
  - 1 second for a 3min 20s audio.
  - 20 seconds for a 1 hour audio.
- For more details and real-time testing, check out the [full example](https://github.com/namidaco/waveform_extractor/tree/main/example)

### Special thanks
[@lincollincol](https://github.com/lincollincol) for providing [Amplituda](https://github.com/lincollincol/Amplituda) Library based on FFMPEG.
