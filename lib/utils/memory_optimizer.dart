import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryOptimizer {
  static void logMemoryUsage(String tag) {
  }

  static void optimizeForMemory() {
    // Reduce system UI overhead
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // Prefer performance over quality for memory efficiency
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static void clearImageCache() {
    // Clear image cache when memory pressure is detected
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static void limitImageCacheSize() {
    // Limit image cache size to prevent memory issues
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
  }
}
