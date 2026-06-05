import 'package:flutter/foundation.dart';

List<String>? parseTimeRange(String? range) {
  if (range == null) return null;
  final parts = range.split('-');
  if (parts.length != 2) return null;
  final start = parts[0].trim();
  final end = parts[1].trim();
  final timeReg = RegExp(r'^\d{1,2}[:h]\d{0,2}$|^\d{1,2}$|^\d{1,2}:\d{2}$');
  if (timeReg.hasMatch(start) && timeReg.hasMatch(end)) {
    return [start, end];
  }
  return null;
}

int compareTimeStrings(String t1, String t2) {
  try {
    final start1 = t1.trim().toLowerCase();
    final start2 = t2.trim().toLowerCase();

    if (start1.isEmpty && start2.isEmpty) return 0;
    if (start1.isEmpty) return 1;
    if (start2.isEmpty) return -1;

    int h1 = 0, m1 = 0;
    if (start1.contains(':')) {
      final p = start1.split(':');
      h1 = int.tryParse(p[0].trim()) ?? 0;
      m1 = p.length > 1 ? (int.tryParse(p[1].replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0) : 0;
    } else if (start1.contains('h')) {
      final p = start1.split('h');
      h1 = int.tryParse(p[0].trim()) ?? 0;
      m1 = (p.length > 1 && p[1].trim().isNotEmpty) ? (int.tryParse(p[1].replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0) : 0;
    } else {
      h1 = int.tryParse(start1.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    int h2 = 0, m2 = 0;
    if (start2.contains(':')) {
      final p = start2.split(':');
      h2 = int.tryParse(p[0].trim()) ?? 0;
      m2 = p.length > 1 ? (int.tryParse(p[1].replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0) : 0;
    } else if (start2.contains('h')) {
      final p = start2.split('h');
      h2 = int.tryParse(p[0].trim()) ?? 0;
      m2 = (p.length > 1 && p[1].trim().isNotEmpty) ? (int.tryParse(p[1].replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0) : 0;
    } else {
      h2 = int.tryParse(start2.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    if (h1 != h2) return h1.compareTo(h2);
    return m1.compareTo(m2);
  } catch (e) {
    debugPrint("[TimeUtil] Error comparing '$t1' and '$t2': $e");
    return 0;
  }
}

int compareTimeRanges(String? range1, String? range2) {
  if (range1 == null && range2 == null) return 0;
  if (range1 == null) return 1;
  if (range2 == null) return -1;

  final start1 = range1.split('-')[0].trim();
  final start2 = range2.split('-')[0].trim();

  return compareTimeStrings(start1, start2);
}
