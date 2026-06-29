import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_trip_controller.dart';

import '../../utils/trip_category_util.dart';

class CreateTripBottomSheet extends StatelessWidget {
  const CreateTripBottomSheet({super.key});

  CreateTripController get controller => Get.find<CreateTripController>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("create_trip_title".tr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 24),

            TextField(
              controller: controller.nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: "create_trip_name_label".tr,
                prefixIcon: Icon(Icons.map, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: "", 
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: controller.descController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: "create_trip_desc_label".tr,
                prefixIcon: Icon(Icons.description, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),

            Text("create_trip_duration".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              final start = controller.startDate.value;
              final end = controller.endDate.value;
              String dateRangeStr = "";
              if (end == null) {
                dateRangeStr = "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
              } else {
                final duration = end.difference(start).inDays + 1;
                dateRangeStr = "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year} ($duration ${'days'.tr})";
              }

              return InkWell(
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDateRangePicker(
                    context: context,
                    locale: Locale(Get.locale?.languageCode ?? 'vi', Get.locale?.countryCode ?? 'VN'),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    initialDateRange: DateTimeRange(
                      start: start,
                      end: end ?? start,
                    ),
                    helpText: "create_trip_picker_help".tr,
                    cancelText: "cancel".tr,
                    confirmText: "save".tr,
                    saveText: "save".tr,
                    fieldStartLabelText: "start_date".tr,
                    fieldEndLabelText: "end_date_select".tr,
                    fieldStartHintText: "start_date".tr,
                    fieldEndHintText: "end_date_select".tr,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (!context.mounted) return;
                  FocusScope.of(context).unfocus();
                  if (picked != null) {
                    controller.startDate.value = picked.start;
                    controller.endDate.value = picked.end;
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateRangeStr,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            Text("create_trip_theme".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TripCategoryUtil.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = TripCategoryUtil.categories[index];
                  return Obx(() {
                    final isSelected = controller.selectedCategoryName.value == cat["name"];
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        controller.selectedCategoryName.value = cat["name"];
                        controller.selectedCategoryIcon.value = cat["iconName"];
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? cat["color"] : (cat["color"] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat["icon"] as IconData,
                              color: isSelected ? Colors.white : cat["color"],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (cat["name"] as String).tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Text("create_trip_cover_label".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() {
              final file = controller.selectedCoverFile.value;
              return Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: file != null
                      ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (file == null)
                      InkWell(
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          await controller.pickCoverImage();
                          if (!context.mounted) return;
                          FocusScope.of(context).unfocus();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                "create_trip_pick_photo".tr,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              await controller.pickCoverImage();
                              if (!context.mounted) return;
                              FocusScope.of(context).unfocus();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            controller.clearCoverImage();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: controller.isLoading.value ? null : () => controller.createTrip(),
                child: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("create_trip_button".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }
}