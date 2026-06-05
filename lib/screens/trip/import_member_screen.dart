import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/import_member_controller.dart';

class ImportMemberScreen extends StatelessWidget {
  final int currentTripId;

  const ImportMemberScreen({super.key, required this.currentTripId});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo controller
    final controller = Get.put(ImportMemberController(currentTripId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Nhập thành viên", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingTrips.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.myTrips.isEmpty) {
          return const Center(child: Text("Bạn chưa có chuyến đi nào khác để nhập thành viên."));
        }

        return Column(
          children: [
            // Dropdown chọn chuyến đi
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flight_takeoff, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text("Chọn chuyến đi nguồn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showTripSelectionBottomSheet(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: controller.selectedTripId.value != null ? AppColors.primaryBackgroundLight : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: controller.selectedTripId.value != null ? AppColors.primaryLight : Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined, color: controller.selectedTripId.value != null ? AppColors.primaryDark : Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.selectedTripId.value != null 
                                ? controller.myTrips.firstWhere((t) => t.id == controller.selectedTripId.value).name 
                                : "Chọn chuyến đi...",
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: controller.selectedTripId.value != null ? FontWeight.bold : FontWeight.normal,
                                color: controller.selectedTripId.value != null ? Colors.black87 : Colors.grey.shade500
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.unfold_more_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Danh sách thành viên
            Expanded(
              child: controller.isLoadingMembers.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.selectedTripId.value == null
                      ? const Center(child: Text("Vui lòng chọn chuyến đi để xem thành viên", style: TextStyle(color: Colors.grey)))
                      : controller.availableMembers.isEmpty
                          ? const Center(child: Text("Không có thành viên nào mới để nhập.", style: TextStyle(color: Colors.grey)))
                          : Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Chọn thành viên (${controller.selectedUserIds.length}/${controller.availableMembers.length})", 
                                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                      TextButton(
                                        onPressed: () {
                                          bool isAllSelected = controller.selectedUserIds.length == controller.availableMembers.length;
                                          controller.toggleAllMembers(!isAllSelected);
                                        },
                                        child: Text(controller.selectedUserIds.length == controller.availableMembers.length ? "Bỏ chọn tất cả" : "Chọn tất cả"),
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: controller.availableMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = controller.availableMembers[index];
                                      bool isSelected = controller.selectedUserIds.contains(member.id);

                                      return Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade200)),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: CheckboxListTile(
                                          activeColor: AppColors.primaryDark,
                                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          value: isSelected,
                                          onChanged: (val) => controller.toggleMemberSelection(member.id),
                                          secondary: Stack(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: member.isGhost ? Colors.grey[200] : AppColors.primaryBackground,
                                                backgroundImage: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) 
                                                    ? CachedNetworkImageProvider(member.avatarUrl!) : null,
                                                child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                                                    ? Text((member.name != null && member.name!.isNotEmpty) ? member.name![0].toUpperCase() : "U", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                                                    : null,
                                              ),
                                              if (member.isGhost)
                                                Positioned(
                                                    bottom: 0, right: 0,
                                                    child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                                                        child: Icon(Icons.visibility_off, size: 10, color: Colors.white)
                                                    )
                                                )
                                            ],
                                          ),
                                          title: Text(member.name ?? "Người dùng", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(member.email ?? member.phone ?? (member.isGhost ? "Người ảo" : ""), style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.selectedTripId.value == null || controller.availableMembers.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -5))]
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.selectedUserIds.isEmpty ? Colors.grey : AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0
            ),
            onPressed: controller.selectedUserIds.isEmpty || controller.isImporting.value 
                ? null 
                : controller.importMembers,
            child: controller.isImporting.value
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("NHẬP ${controller.selectedUserIds.length} THÀNH VIÊN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        );
      }),
    );
  }

  void _showTripSelectionBottomSheet(BuildContext context, ImportMemberController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Chọn chuyến đi nguồn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.myTrips.length,
                itemBuilder: (context, index) {
                  final trip = controller.myTrips[index];
                  final isSelected = controller.selectedTripId.value == trip.id;
                  
                  return InkWell(
                    onTap: () {
                      controller.onTripSelected(trip.id);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: isSelected ? AppColors.primary.withValues(alpha:0.05) : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryBackground : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.map_outlined, color: isSelected ? AppColors.primaryDark : Colors.grey.shade500),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              trip.name, 
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.primaryDark : Colors.black87
                              )
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryDark)
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}