import 'dart:async';
import 'dart:developer' as developer;

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void startTrace(String name) {
    _timers[name] = Stopwatch()..start();
    developer.Timeline.startSync(name);
  }

  static void endTrace(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      developer.Timeline.finishSync();
      if (duration > 16) {
        developer.log('$name took ${duration}ms', name: 'Performance');
      }
      _timers.remove(name);
    }
  }

  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() callback,
  ) async {
    startTrace(name);
    try {
      return await callback();
    } finally {
      endTrace(name);
    }
  }
}

class FirebasePerformanceService {
  static bool _isEnabled = false;

  static void initialize() {
    _isEnabled = true;
  }

  static Future<void> traceHttpRequest(
    String url,
    Future<void> Function() request,
  ) async {
    if (!_isEnabled) {
      await request();
      return;
    }

    PerformanceMonitor.startTrace('http_$url');
    try {
      await request();
    } finally {
      PerformanceMonitor.endTrace('http_$url');
    }
  }

  static Future<void> traceFirestoreRead(
    String collection,
    Future<void> Function() read,
  ) async {
    if (!_isEnabled) {
      await read();
      return;
    }

    PerformanceMonitor.startTrace('firestore_read_$collection');
    try {
      await read();
    } finally {
      PerformanceMonitor.endTrace('firestore_read_$collection');
    }
  }
}
