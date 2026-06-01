import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageUtil {
  static final _storage = GetStorage();

  // Settings Keys
  static const String keySchedule = 'storage_auto_clean_schedule'; // 'daily', 'weekly', 'off'
  static const String keyMaxSize = 'storage_max_cache_size'; // 20, 50, 100, 0 (unlimited)
  static const String keyLastClean = 'storage_last_clean_time';

  // Get current schedule preference (default: 'weekly')
  static String getCleanSchedule() {
    return _storage.read(keySchedule) ?? 'weekly';
  }

  // Set schedule preference
  static void setCleanSchedule(String value) {
    _storage.write(keySchedule, value);
  }

  // Get current max cache size preference (default: 50 MB)
  static int getMaxCacheSize() {
    return _storage.read(keyMaxSize) ?? 50;
  }

  // Set max cache size preference
  static void setMaxCacheSize(int value) {
    _storage.write(keyMaxSize, value);
  }

  // Calculate total cache directory size in Megabytes (MB)
  static Future<double> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;
      if (await tempDir.exists()) {
        await for (var file in tempDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            try {
              totalSize += await file.length();
            } catch (_) {}
          }
        }
      }
      return totalSize / (1024 * 1024);
    } catch (e) {
      debugPrint('[StorageUtil] Error calculating cache size: $e');
      return 0;
    }
  }

  // Clear cache directory
  static Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: false);
        for (var entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      _storage.write(keyLastClean, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('[StorageUtil] Error clearing cache: $e');
      return false;
    }
  }

  // Run automatic background checks on app startup
  static Future<void> checkAndAutoClean() async {
    try {
      final lastCleanStr = _storage.read(keyLastClean);
      final lastClean = lastCleanStr != null ? DateTime.tryParse(lastCleanStr) : null;
      final now = DateTime.now();

      bool shouldClean = false;

      // 1. Check schedule
      final schedule = getCleanSchedule();
      if (schedule != 'off' && lastClean != null) {
        final isNewDay = lastClean.year != now.year || lastClean.month != now.month || lastClean.day != now.day;
        final diffDays = now.difference(lastClean).inDays;
        
        if (schedule == 'daily' && isNewDay) {
          shouldClean = true;
          debugPrint('[StorageUtil] Auto-clean triggered by Daily schedule (calendar day changed).');
        } else if (schedule == 'weekly' && diffDays >= 7) {
          shouldClean = true;
          debugPrint('[StorageUtil] Auto-clean triggered by Weekly schedule.');
        }
      } else if (lastClean == null) {
        // First run
        _storage.write(keyLastClean, now.toIso8601String());
      }

      // 2. Check max size limit if not already triggered
      if (!shouldClean) {
        final maxSizeLimit = getMaxCacheSize();
        if (maxSizeLimit > 0) {
          final currentSize = await getCacheSize();
          if (currentSize > maxSizeLimit) {
            shouldClean = true;
            debugPrint('[StorageUtil] Auto-clean triggered by Max Cache Size limit (${currentSize.toStringAsFixed(1)} MB > $maxSizeLimit MB).');
          }
        }
      }

      if (shouldClean) {
        await clearCache();
      }
    } catch (e) {
      debugPrint('[StorageUtil] Error during auto-clean check: $e');
    }
  }
}
