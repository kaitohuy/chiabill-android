import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/models/announcement_response.dart';
import '../data/repositories/announcement_repository.dart';
import '../widgets/announcement_dialog.dart';

class AnnouncementController extends GetxController {
  final AnnouncementRepository _repository = AnnouncementRepository();

  var isLoading = false.obs;

  /// Gọi khi app khởi động (sau khi đã login) để fetch & hiện thông báo.
  /// Nên gọi từ HomeController.onInit() hoặc sau khi login thành công.
  Future<void> fetchAndShowAnnouncements(BuildContext context) async {
    if (isLoading.value) return;
    isLoading.value = true;

    final result = await _repository.getActiveAnnouncements();
    isLoading.value = false;

    if (!result.success || result.data == null || result.data!.isEmpty) return;

    // Lấy thông tin phiên bản hiện tại của app
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    // Lọc theo displayMode và version code (đối với thông báo UPDATE)
    final toShow = result.data!.where((a) {
      if (a.isUpdate && a.latestVersion != null) {
        if (currentBuild >= a.latestVersion!) {
          return false; // Đã cài đặt bản mới nhất hoặc cao hơn → không hiển thị cập nhật nữa
        }
      }
      return _repository.shouldShow(a);
    }).toList();
    if (toShow.isEmpty) return;

    for (final announcement in toShow) {
      if (!context.mounted) break;

      await _showDialog(context, announcement);

      // Ghi nhận đã xem (sau khi dialog đóng)
      _repository.markAsSeen(announcement);

      // Nếu là force update → dừng lại, không cho dùng app
      if (announcement.isUpdate && announcement.isForceUpdate == true) break;

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _showDialog(
      BuildContext context, AnnouncementResponse announcement) {
    return showDialog(
      context: context,
      barrierDismissible: announcement.isDismissible,
      builder: (_) => AnnouncementDialog(announcement: announcement),
    );
  }

  /// Xử lý khi user bấm nút action trong dialog
  Future<void> handleAction(AnnouncementResponse announcement) async {
    switch (announcement.actionType) {
      case 'OPEN_URL':
        final uri = Uri.tryParse(announcement.actionUrl ?? '');
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;

      case 'OPEN_STORE':
        const storeUrl =
            'https://play.google.com/store/apps/details?id=com.kaitohuy.chiabill';
        final uri = Uri.parse(storeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;

      case 'OPEN_SCREEN':
        if (announcement.actionUrl != null) {
          Get.back();
          Get.toNamed(announcement.actionUrl!);
        }
        break;

      case 'DISMISS':
      case 'NONE':
      default:
        Get.back();
        break;
    }
  }
}
