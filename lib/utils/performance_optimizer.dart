import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'memory_optimizer.dart';
import 'memory_monitor.dart';

class PerformanceOptimizer {
  static bool _isInitialized = false;
  static Timer? _performanceTimer;

  /// Initialize performance optimizations
  static void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;

    // Optimize for memory
    MemoryOptimizer.optimizeForMemory();
    MemoryOptimizer.limitImageCacheSize();

    // Start memory monitoring
    MemoryMonitor.startMonitoring();

    // Optimize rendering performance
    _optimizeRendering();

    // Start performance monitoring
    _startPerformanceMonitoring();

   
  }

  /// Optimize rendering performance
  static void _optimizeRendering() {
    // Reduce rendering overhead
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Enable performance overlays in debug mode
      if (kDebugMode) {
        // Uncomment to see performance overlays
        // WidgetsApp.debugAllowBannerOverride = false;
      }
    });
  }

  /// Start performance monitoring
  static void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkPerformance();
    });
  }

  /// Check performance metrics
  static void _checkPerformance() {
    try {
      // Simple performance check - monitor memory usage
      final imageCache = PaintingBinding.instance.imageCache;
      final currentSize = imageCache.currentSize;
      final currentSizeBytes = imageCache.currentSizeBytes;

      // Log performance metrics
    

      // Check if we need optimization
      if (currentSizeBytes > 80 << 20) {
        // 80MB threshold
       
        _handlePerformanceIssue();
      }
    } catch (e) {
     
    }
  }

  /// Handle performance issues
  static void _handlePerformanceIssue() {
  

    // Clear image cache
    MemoryOptimizer.clearImageCache();

    // Force garbage collection
    // Note: This is a development aid, use sparingly in production
    if (kDebugMode) {
      SystemChannels.platform.invokeMethod('System.gc');
    }
  }

  /// Optimize for smooth scrolling
  static void optimizeForScrolling() {
    // Pre-cache images before scrolling
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
  }

  /// Reset to normal optimization
  static void resetToNormal() {
    MemoryOptimizer.limitImageCacheSize();
  }

  /// Dispose performance monitoring
  static void dispose() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
    MemoryMonitor.stopMonitoring();
    _isInitialized = false;
 
  }
}

/// Mixin for performance-aware widgets
mixin PerformanceAwareMixin<T extends StatefulWidget> on State<T> {
  bool _isPerformanceMode = false;

  @override
  void initState() {
    super.initState();
    PerformanceOptimizer.initialize();
  }

  @override
  void dispose() {
    PerformanceOptimizer.dispose();
    super.dispose();
  }

  /// Enable performance mode for heavy operations
  void enablePerformanceMode() {
    if (!_isPerformanceMode) {
      _isPerformanceMode = true;
      PerformanceOptimizer.optimizeForScrolling();
    }
  }

  /// Disable performance mode
  void disablePerformanceMode() {
    if (_isPerformanceMode) {
      _isPerformanceMode = false;
      PerformanceOptimizer.resetToNormal();
    }
  }
}

/// Widget for performance monitoring
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitorWidget({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitorWidget> createState() =>
      _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Utility for debouncing heavy operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

/// Utility for throttling frequent updates
class Throttler {
  final Duration duration;
  DateTime? _lastRun;

  Throttler({required this.duration});

  bool run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
      return true;
    }
    return false;
  }
}
