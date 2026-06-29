import 'dart:io';
import 'dart:typed_data';
import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportHelper {
  static void showExportActionSheet({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required String shareText,
  }) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'export_success'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Nút 1: Lưu vào điện thoại (Download/Save As)
            InkWell(
              onTap: () async {
                Get.back();
                try {
                  String? outputFile = await FilePicker.platform.saveFile(
                    dialogTitle: 'choose_save_location'.tr,
                    fileName: fileName,
                    bytes: Uint8List.fromList(bytes),
                  );
                  if (outputFile == null) return;

                  try {
                    final file = File(outputFile);
                    if (!await file.exists() || (await file.length()) == 0) {
                      await file.writeAsBytes(bytes, flush: true);
                    }
                  } catch (_) {}

                  ToastUtil.showSuccess('success'.tr, 'save_file_success'.tr);
                } catch (e) {
                  ToastUtil.showError('error'.tr, 'save_file_error'.trParams({'error': e.toString()}));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.file_download_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'save_to_device'.tr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'save_to_device_desc'.tr,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nút 2: Chia sẻ qua ứng dụng khác
            InkWell(
              onTap: () async {
                Get.back();
                try {
                  final tempDir = await getTemporaryDirectory();
                  final filePath = "${tempDir.path}/$fileName";
                  final file = File(filePath);
                  await file.writeAsBytes(bytes, flush: true);

                  await SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile(
                          filePath,
                          mimeType: mimeType,
                          name: fileName,
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ToastUtil.showError('system_error'.tr, 'share_error'.trParams({'error': e.toString()}));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'share_via_apps'.tr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'share_via_apps_desc'.tr,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'export_note'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nút đóng
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'btn_close'.tr.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
