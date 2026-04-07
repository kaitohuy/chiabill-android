import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../widgets/kick_member_dialog.dart';

class MembersTab extends StatelessWidget {
  final TripDetailController controller;
  final VoidCallback onAddMemberTap; // Thêm callback để mở hộp thoại từ khoảng trống

  const MembersTab({super.key, required this.controller, required this.onAddMemberTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      final trip = controller.trip.value;

      return Column(
        children: [
          Expanded(
            // 🌟 BỌC GESTURE DETECTOR ĐỂ BẮT CLICK KHOẢNG TRỐNG
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onAddMemberTap,
              child: Builder(
                  builder: (context) {
                    // Xử lý Empty State
                    if (trip == null || trip.members == null || trip.members!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.blue.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text("Chưa có thành viên nào.\nChạm vào bất cứ đâu để thêm!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    // Danh sách thành viên
                    return RefreshIndicator(
                        color: Colors.lightGreen,
                        onRefresh: () async => controller.fetchData(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: trip.members!.length,
                          itemBuilder: (context, index) {
                            final memberData = trip.members![index];
                            final member = memberData.user;

                            bool isDisabled = memberData.status == 'DISABLED';
                            bool isMemberOwner = trip.ownerId == member.id;
                            String memberInitial = (member.name != null && member.name!.trim().isNotEmpty) ? member.name!.trim()[0].toUpperCase() : "U";

                            return Opacity(
                              opacity: isDisabled ? 0.5 : 1.0,
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0.5,
                                child: ListTile(
                                  leading: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: member.isGhost ? Colors.grey[200] : Colors.lightGreen[100],
                                        backgroundImage: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) ? NetworkImage(member.avatarUrl!) : null,
                                        child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                                            ? (member.isGhost ? const Icon(Icons.visibility_off, color: Colors.grey, size: 20) : Text(memberInitial, style: const TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold)))
                                            : null,
                                      ),
                                      if (isMemberOwner) const Text("👑", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  title: Row(
                                      children: [
                                        Expanded(
                                            child: Text(member.name ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)
                                        ),
                                        if (isDisabled)
                                          const Text(" (Tạm ngưng)", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                                      ]
                                  ),
                                  subtitle: Text(member.isGhost ? "Người dùng ảo (Ghost)" : "Thành viên app"),
                                  trailing: const Icon(Icons.settings, color: Colors.grey, size: 20),

                                  // 🌟 MENU ADMIN QUẢN LÝ THÀNH VIÊN KHI BẤM VÀO
                                  onTap: () {
                                    Get.bottomSheet(
                                        Container(
                                          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + MediaQuery.of(context).padding.bottom),
                                          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(member.name ?? "Thành viên", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 16),

                                              ListTile(
                                                  leading: const Icon(Icons.email, color: Colors.blue),
                                                  title: const Text("Email / Tài khoản"),
                                                  subtitle: Text(member.email ?? "Không có thông tin")
                                              ),

                                              if (controller.isOwner && !isMemberOwner) ...[
                                                const Divider(),
                                                const Text("Quản trị thành viên", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                                const SizedBox(height: 8),

                                                ListTile(
                                                    leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                                                    title: const Text("Chuyển quyền Chủ phòng"),
                                                    onTap: () { Get.back(); controller.transferOwner(member.id!); }
                                                ),
                                                ListTile(
                                                    leading: Icon(isDisabled ? Icons.play_arrow : Icons.pause, color: Colors.orange),
                                                    title: Text(isDisabled ? "Mở khóa thành viên" : "Tạm ngưng hoạt động"),
                                                    onTap: () {
                                                      Get.back();
                                                      if (isDisabled) {
                                                        controller.activateMember(member.id!);
                                                      } else {
                                                        controller.disableMember(member.id!);
                                                      }
                                                    }
                                                ),
                                                ListTile(
                                                    leading: const Icon(Icons.person_remove, color: Colors.red),
                                                    title: const Text("Đuổi khỏi nhóm", style: TextStyle(color: Colors.red)),
                                                    onTap: () {
                                                      Get.back();
                                                      Get.back();
                                                      Get.dialog(
                                                          KickMemberDialog(
                                                              userName: member.name ?? "Thành viên",
                                                              onConfirm: (forgive) => controller.kickMember(member.id!, forgive)
                                                          )
                                                      );
                                                    }
                                                ),
                                              ]
                                            ],
                                          ),
                                        )
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        )
                    );
                  }
              ),
            ),
          ),

          // NÚT RỜI NHÓM NẰM CỐ ĐỊNH Ở DƯỚI
          if (!controller.isOwner)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text("Rời nhóm", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Get.defaultDialog(
                      title: "Rời nhóm",
                      middleText: "Bạn chắc chắn muốn rời khỏi nhóm này?",
                      textConfirm: "XÁC NHẬN",
                      textCancel: "HỦY",
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.orange,
                      onConfirm: () => controller.leaveTrip(),
                    );
                  },
                ),
              ),
            )
        ],
      );
    });
  }
}