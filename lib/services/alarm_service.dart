import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../screens/trip/itinerary_screen.dart';
import '../data/models/itinerary_item_response.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static final Map<String, Future<Uint8List?>> _activeImageDownloads = {};

  /// Khởi tạo dịch vụ thông báo cục bộ
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      
      // Khởi tạo múi giờ cục bộ của thiết bị để zonedSchedule hoạt động chính xác
      String timeZoneName;
      try {
        const MethodChannel channel = MethodChannel('com.kaitohuy.chiabill/timezone');
        final String? systemTimezone = await channel.invokeMethod<String>('getLocalTimezone');
        timeZoneName = systemTimezone ?? 'Asia/Ho_Chi_Minh';
      } catch (_) {
        timeZoneName = 'Asia/Ho_Chi_Minh';
      }
      if (timeZoneName == 'Asia/Saigon') {
        timeZoneName = 'Asia/Ho_Chi_Minh';
      }
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('[AlarmService] Timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('[AlarmService] Timezone $timeZoneName not found in database. Falling back. Error: $e');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
          debugPrint('[AlarmService] Timezone set to fallback: Asia/Ho_Chi_Minh');
        } catch (e2) {
          tz.setLocalLocation(tz.UTC);
          debugPrint('[AlarmService] Timezone set to fallback: UTC');
        }
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          final payload = details.payload;
          if (payload != null && payload.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              handleNotificationPayload(payload);
            });
          }
        },
      );

      // Tạo kênh thông báo độ ưu tiên cao (High Importance Channel) cho Android 8.0+
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel_v3', // id
          'Thông báo lịch trình', // title
          description: 'Kênh này dùng để gửi thông báo nhắc nhở lịch trình chuyến đi.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(channel);
        debugPrint('[AlarmService] High Importance Channel created.');
      }

      _isInitialized = true;
      debugPrint('[AlarmService] Initialized successfully.');
    } catch (e) {
      debugPrint('[AlarmService] Failed to initialize: $e');
    }
  }

  /// Yêu cầu quyền gửi thông báo (Android 13+)
  static Future<void> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[AlarmService] Failed to request permissions: $e');
    }
  }

  /// Hủy tất cả thông báo của một chuyến đi
  static Future<void> cancelAllAlarmsForTrip(List<ItineraryItemResponse> items) async {
    for (final item in items) {
      if (item.id != null) {
        await _notificationsPlugin.cancel(item.id!);
      }
    }
  }

  static Future<void> scheduleAlarmsForTrip({
    required int tripId,
    required String tripName,
    required String? startDateStr,
    required List<ItineraryItemResponse> items,
    String? coverUrl,
  }) async {
    await init();
    final storage = GetStorage();

    // Đọc cài đặt cấu hình từ GetStorage
    final isEnabled = storage.read('itinerary_alarm_enabled_$tripId') ?? true;
    final enableVibrate = storage.read('itinerary_alarm_vibrate_$tripId') ?? true;
    final enableSound = storage.read('itinerary_alarm_sound_$tripId') ?? true;
    final alarmValue = storage.read('itinerary_alarm_value_$tripId') ?? 15;
    final alarmUnit = storage.read('itinerary_alarm_unit_$tripId') ?? 'Phút';

    // 1. Nếu tắt thông báo: Hủy tất cả lịch báo thức của chuyến đi
    if (!isEnabled) {
      debugPrint('[AlarmService] Notifications disabled for trip $tripId. Cancelling all alarms.');
      await cancelAllAlarmsForTrip(items);
      return;
    }

    // 2. Nếu bật thông báo: Tính toán thời gian và lên lịch nhắc nhở
    debugPrint('[AlarmService] Notifications enabled for trip $tripId. Scheduling alarms...');

    AndroidBitmap<Object>? largeIconBitmap;
    if (coverUrl != null && coverUrl.trim().isNotEmpty) {
      try {
        final cacheKey = 'cached_cropped_image_${coverUrl.hashCode}';
        final cachedBase64 = storage.read<String>(cacheKey);
        if (cachedBase64 == 'FAILED') {
          debugPrint('[AlarmService] Cover image previously failed to load. Skipping to avoid retries for trip $tripId');
        } else if (cachedBase64 != null) {
          final croppedBytes = base64Decode(cachedBase64);
          largeIconBitmap = ByteArrayAndroidBitmap(croppedBytes);
          debugPrint('[AlarmService] Loaded cropped cover image from cache for trip $tripId');
        } else {
          // Sử dụng Map để chia sẻ Future download + crop giữa các luồng đồng thời
          final imageFuture = _activeImageDownloads.putIfAbsent(coverUrl, () async {
            try {
              final bytes = await _downloadImageBytes(coverUrl);
              if (bytes != null) {
                final cropped = await _getCircleCroppedImageBytes(bytes, 120);
                storage.write(cacheKey, base64Encode(cropped));
                debugPrint('[AlarmService] Prepared circle-cropped cover image and cached it for trip $tripId');
                return cropped;
              } else {
                storage.write(cacheKey, 'FAILED');
              }
            } catch (e) {
              debugPrint('[AlarmService] Error inside active download/crop: $e');
            } finally {
              _activeImageDownloads.remove(coverUrl);
            }
            return null;
          });

          final cropped = await imageFuture;
          if (cropped != null) {
            largeIconBitmap = ByteArrayAndroidBitmap(cropped);
          }
        }
      } catch (e) {
        debugPrint('[AlarmService] Error preparing cover image bitmap: $e');
      }
    }

    // Lấy ngày bắt đầu chuyến đi
    DateTime baseDate = DateTime.now();
    if (startDateStr != null) {
      final parsed = DateTime.tryParse(startDateStr);
      if (parsed != null) {
        baseDate = parsed;
      }
    }

    for (final item in items) {
      if (item.id == null) continue;

      // Hủy lịch cũ trước khi lên lịch mới để tránh trùng lặp
      await _notificationsPlugin.cancel(item.id!);

      if (item.timeRange == null || item.timeRange!.trim().isEmpty) {
        continue;
      }

      // Phân tích giờ bắt đầu hoạt động (ví dụ "13:00 - 14:00" -> "13:00", hoặc "13h15 - 14h" -> "13h15")
      final parts = item.timeRange!.split('-');
      if (parts.isEmpty) continue;
      final startTimeStr = parts[0].trim().toLowerCase();

      int? hour;
      int? minute;

      if (startTimeStr.contains(':')) {
        final timeParts = startTimeStr.split(':');
        if (timeParts.isNotEmpty) {
          hour = int.tryParse(timeParts[0].trim());
          if (timeParts.length >= 2) {
            minute = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '').trim());
          } else {
            minute = 0;
          }
        }
      } else if (startTimeStr.contains('h')) {
        final timeParts = startTimeStr.split('h');
        if (timeParts.isNotEmpty) {
          hour = int.tryParse(timeParts[0].trim());
          if (timeParts.length >= 2 && timeParts[1].trim().isNotEmpty) {
            minute = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '').trim());
          } else {
            minute = 0;
          }
        }
      } else {
        // Có thể chỉ có mỗi số giờ (ví dụ "9" -> 9:00)
        hour = int.tryParse(startTimeStr);
        minute = 0;
      }

      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        continue;
      }

      // Tính ngày cụ thể dựa vào dayNumber (dayNumber = 1 tương ứng với ngày khởi hành)
      final int offsetDays = (item.dayNumber > 0) ? (item.dayNumber - 1) : 0;
      final activityDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      ).add(Duration(days: offsetDays));

      // Tính thời gian báo trước
      Duration alarmOffset;
      switch (alarmUnit) {
        case 'Giây':
          alarmOffset = Duration(seconds: alarmValue);
          break;
        case 'Giờ':
          alarmOffset = Duration(hours: alarmValue);
          break;
        case 'Ngày':
          alarmOffset = Duration(days: alarmValue);
          break;
        case 'Phút':
        default:
          alarmOffset = Duration(minutes: alarmValue);
          break;
      }

      final scheduledTime = activityDateTime.subtract(alarmOffset);

      // Nếu thời gian lên lịch đã ở quá khứ, bỏ qua
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('[AlarmService] Scheduled time $scheduledTime is in the past for item: ${item.activity}. Skipping.');
        continue;
      }

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel_v3',
        'Nhắc nhở lịch trình',
        channelDescription: 'Thông báo nhắc nhở lịch trình chuyến đi',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'small_icon',
        largeIcon: largeIconBitmap ?? const DrawableResourceAndroidBitmap('logo_home'),
        color: const Color(0xFFE11D48),
        vibrationPattern: enableVibrate ? Int64List.fromList([0, 1000, 500, 1000]) : null,
        playSound: enableSound,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      try {
        await _notificationsPlugin.zonedSchedule(
          item.id!,
          'Sắp đến lịch trình: ${item.activity}',
          'Thời gian diễn ra: ${item.timeRange} (Báo trước $alarmValue $alarmUnit)',
          tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'ITINERARY|$tripId',
        );
        debugPrint('[AlarmService] Scheduled exact alarm for "${item.activity}" at $scheduledTime');
      } catch (e) {
        debugPrint('[AlarmService] Failed to schedule exact alarm: $e. Retrying in non-exact mode.');
        try {
          await _notificationsPlugin.zonedSchedule(
            item.id!,
            'Sắp đến lịch trình: ${item.activity}',
            'Thời gian diễn ra: ${item.timeRange}',
            tz.TZDateTime.from(scheduledTime, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'ITINERARY|$tripId',
          );
          debugPrint('[AlarmService] Scheduled inexact fallback alarm for "${item.activity}" at $scheduledTime');
        } catch (e2) {
          debugPrint('[AlarmService] Failed to schedule alarm in fallback mode: $e2');
        }
      }
    }
  }

  /// Hiển thị thông báo ngay lập tức (dùng khi nhận tin từ FCM)
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    AndroidBitmap<Object>? largeIconBitmap;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        final storage = GetStorage();
        final cacheKey = 'cached_cropped_image_${imageUrl.hashCode}';
        final cachedBase64 = storage.read<String>(cacheKey);
        if (cachedBase64 == 'FAILED') {
          debugPrint('[AlarmService] Instant notification image previously failed to load. Skipping.');
        } else if (cachedBase64 != null) {
          final croppedBytes = base64Decode(cachedBase64);
          largeIconBitmap = ByteArrayAndroidBitmap(croppedBytes);
        } else {
          final imageFuture = _activeImageDownloads.putIfAbsent(imageUrl, () async {
            try {
              final bytes = await _downloadImageBytes(imageUrl);
              if (bytes != null) {
                final cropped = await _getCircleCroppedImageBytes(bytes, 120);
                storage.write(cacheKey, base64Encode(cropped));
                return cropped;
              } else {
                storage.write(cacheKey, 'FAILED');
              }
            } catch (e) {
              debugPrint('[AlarmService] Error inside active instant notification download/crop: $e');
            } finally {
              _activeImageDownloads.remove(imageUrl);
            }
            return null;
          });

          final cropped = await imageFuture;
          if (cropped != null) {
            largeIconBitmap = ByteArrayAndroidBitmap(cropped);
          }
        }
      } catch (e) {
        debugPrint('[AlarmService] Error preparing instant notification image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel_v3',
      'Thông báo chung',
      channelDescription: 'Kênh thông báo của ứng dụng',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'small_icon',
      largeIcon: largeIconBitmap ?? const DrawableResourceAndroidBitmap('logo_home'),
      color: const Color(0xFFE11D48),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(id, title, body, notificationDetails, payload: payload);
    } catch (e) {
      debugPrint('[AlarmService] Failed to show instant notification: $e');
    }
  }

  static Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final response = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          return Uint8List.fromList(response.data!);
        }
      } else {
        // Hỗ trợ đường dẫn tệp cục bộ
        final file = File(url.replaceFirst('file://', ''));
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Failed to load image bytes from $url: $e');
    }
    return null;
  }

  static Future<Uint8List> _getCircleCroppedImageBytes(Uint8List imageBytes, int size) async {
    // Giải mã trực tiếp ra kích thước mục tiêu (size x size) để tối ưu hóa bộ nhớ và tốc độ
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: size,
      targetHeight: size,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final double radius = size / 2.0;

    final ui.Path path = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: ui.Offset(radius, radius), radius: radius));
    canvas.clipPath(path);

    canvas.drawImage(image, ui.Offset.zero, ui.Paint()..isAntiAlias = true);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image croppedImage = await picture.toImage(size, size);
    final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    
    // Giải phóng bộ nhớ native image ngay lập tức
    image.dispose();
    croppedImage.dispose();
    
    return byteData!.buffer.asUint8List();
  }

  static void handleNotificationPayload(String payload) {
    try {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final referenceId = parts[1];
        int tripId = int.parse(referenceId);
        if (type == "ITINERARY") {
          Get.to(() => ItineraryScreen(tripId: tripId));
        } else if (type == "EXPENSE_CREATED" || type == "PAYMENT_REQUESTED" || type == "PAYMENT_APPROVED") {
          Get.toNamed(Routes.TRIP_DETAIL, arguments: tripId);
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Error handling notification tap: $e');
    }
  }

  static Future<void> checkAppLaunchNotification() async {
    try {
      final NotificationAppLaunchDetails? details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            handleNotificationPayload(payload);
          });
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Error checking app launch notification: $e');
    }
  }
}
