package com.namidaco.waveform_extractor

import android.app.Activity
import android.util.Log
import androidx.lifecycle.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import linc.com.amplituda.Amplituda
import linc.com.amplituda.AmplitudaProgressListener
import linc.com.amplituda.AmplitudaResult
import linc.com.amplituda.Cache
import linc.com.amplituda.Compress
import linc.com.amplituda.ProgressOperation

/** WaveformExtractorPlugin */
class WaveformExtractorPlugin : FlutterPlugin, MethodCallHandler, Activity() {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private lateinit var amplituda: Amplituda
  private val mainScope = CoroutineScope(Dispatchers.IO)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val context = flutterPluginBinding.applicationContext
    amplituda = Amplituda(context)
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "waveform_extractor")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "waveform_extractor/stream")
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val path = call.argument<String>("path")
    val useCache = call.argument<Boolean>("useCache")
    val cacheKey = call.argument<String?>("cacheKey")
    val samplePerSecond = call.argument<Int?>("samplePerSecond")
    val postProgress = call.argument<Boolean?>("postProgress") ?: false
    when (call.method) {
      "extractWaveform" -> {
        if (path != null && useCache != null) {
          if (postProgress) {
            extractWaveformToStream(
                path,
                useCache,
                cacheKey,
                samplePerSecond,
            )
            result.success(null)
          } else {
            mainScope.launch {
              val waveform =
                  extractWaveform(
                      path,
                      useCache,
                      cacheKey,
                      samplePerSecond,
                      null,
                  )
              withContext(Dispatchers.Main) { result.success(waveform) }
            }
          }
        } else {
          result.error("Arguments Missing", "path & useCache should be provided", "")
        }
      }
      "extractWaveformDataOnly" -> {
        if (path != null && useCache != null) {
          if (postProgress) {
            extractWaveformDataOnlyToStream(
                path,
                useCache,
                cacheKey,
                samplePerSecond,
            )
            result.success(null)
          } else {
            mainScope.launch {
              val waveform =
                  extractWaveformDataOnly(
                      path,
                      useCache,
                      cacheKey,
                      samplePerSecond,
                  )
              withContext(Dispatchers.Main) { result.success(waveform) }
            }
          }
        } else {
          result.error("Arguments Missing", "path & useCache should be provided", "")
        }
      }
      "clearCache" -> {
        val audioPath = call.argument<String?>("audioPath")
        if (audioPath != null || cacheKey != null) {
          result.success(clearCache(cacheKey, audioPath))
        } else {
          result.error("Arguments Missing", "audioPath or cacheKey should be provided", "")
        }
      }
      "clearAllWaveformCache" -> {
        result.success(clearAllWaveformCache())
      }
      else -> result.notImplemented()
    }
  }

  private fun processAudio(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
      progressListener: AmplitudaProgressListener?,
  ): AmplitudaResult<String> {
    lateinit var ampres: AmplitudaResult<String>
    val cache = Cache.withParams(if (useCache) Cache.REUSE else Cache.REFRESH, cacheKey)
    (if (samplePerSecond != null)
            amplituda.processAudio(
                path,
                Compress.withParams(Compress.AVERAGE, samplePerSecond),
                cache,
                progressListener,
            )
        else
            amplituda.processAudio(
                path,
                cache,
                progressListener,
            ))
        .get({ result -> ampres = result }) { exception ->
          Log.d(this.javaClass.name, "Error Extracting Waveform Data", exception)
        }
    return ampres
  }

  private fun extractWaveform(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
      ampresult: AmplitudaResult<String>?
  ): HashMap<String, Any> {

    val result = ampresult ?: processAudio(path, useCache, cacheKey, samplePerSecond, null)
    val amplitudesData: List<Int> = result.amplitudesAsList()
    val amplitudesForFirstSecond: List<Int> = result.amplitudesForSecond(1)
    val duration: Long = result.getAudioDuration(AmplitudaResult.DurationUnit.MILLIS)
    val source: String = result.audioSource

    val waveformMap = HashMap<String, Any>()
    waveformMap["amplitudesData"] = amplitudesData
    waveformMap["amplitudesForFirstSecond"] = amplitudesForFirstSecond
    waveformMap["duration"] = duration
    waveformMap["source"] = source

    return waveformMap
  }

  private fun extractWaveformToStream(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
  ) {
    extractToStreamGeneral(path, useCache, cacheKey, samplePerSecond) { result ->
      extractWaveform(path, useCache, cacheKey, samplePerSecond, result)
    }
  }

  private fun extractWaveformDataOnly(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
  ): List<Int>? {
    val result = processAudio(path, useCache, cacheKey, samplePerSecond, null)
    val waveform = result.amplitudesAsList()
    return waveform
  }

  private fun extractWaveformDataOnlyToStream(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
  ) {
    extractToStreamGeneral(path, useCache, cacheKey, samplePerSecond) { result ->
      mapOf("waveform" to result.amplitudesAsList())
    }
  }

  private fun extractToStreamGeneral(
      path: String,
      useCache: Boolean,
      cacheKey: String?,
      samplePerSecond: Int?,
      resultCallback: (AmplitudaResult<String>) -> Map<String, Any>,
  ) {

    eventChannel?.setStreamHandler(
        object : EventChannel.StreamHandler {
          override fun onListen(args: Any?, events: EventChannel.EventSink) {
            mainScope.launch {
              val progressListener =
                  object : AmplitudaProgressListener() {

                    override fun onStartProgress() {
                      super.onStartProgress()
                      val eventData =
                          mapOf(
                              "path" to path,
                              "event" to "start",
                          )
                      runOnUiThread { events.success(eventData) }
                    }

                    override fun onStopProgress() {
                      super.onStopProgress()
                      val eventData =
                          mapOf(
                              "path" to path,
                              "event" to "stop",
                          )
                      runOnUiThread { events.success(eventData) }
                    }

                    override fun onProgress(operation: ProgressOperation, progress: Int) {
                      val currentOperation =
                          when (operation) {
                            ProgressOperation.PROCESSING -> "PROCESSING"
                            ProgressOperation.DECODING -> "DECODING"
                            ProgressOperation.DOWNLOADING -> "DOWNLOADING"
                          }
                      val eventData =
                          mapOf(
                              "path" to path,
                              "event" to "progress",
                              "operation" to currentOperation,
                              "progress" to progress
                          )
                      runOnUiThread { events.success(eventData) }
                    }
                  }

              val result =
                  processAudio(
                      path,
                      useCache,
                      cacheKey,
                      samplePerSecond,
                      progressListener,
                  )
              val eventData = HashMap<String, Any>()
              eventData["path"] = path
              eventData["event"] = "done"
              val additional = resultCallback(result)
              eventData.putAll(additional)

              withContext(Dispatchers.Main) { events.success(eventData) }
            }
          }

          override fun onCancel(args: Any?) {
            // eventChannel.setStreamHandler(null)
          }
        }
    )
  }

  private fun clearAllWaveformCache() {
    amplituda.clearCache()
  }

  private fun clearCache(cacheKey: String?, audioPath: String?) {
    if (cacheKey != null) {
      amplituda.clearCache(cacheKey, true)
    } else if (audioPath != null) {
      amplituda.clearCache(audioPath, false)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
