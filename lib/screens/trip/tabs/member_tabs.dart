import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart' as org_cached;
import '../../../controllers/trip_detail_controller.dart';
import '../widgets/kick_member_dialog.dart';
import '../../../utils/ui_util.dart';

class MembersTab extends StatefulWidget {
  final TripDetailController controller;
  final VoidCallback onAddMemberTap; // Thêm callback để mở hộp thoại từ khoảng trống

  const MembersTab({super.key, required this.controller, required this.onAddMemberTap});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (widget.controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      final trip = widget.controller.trip.value;

      return Column(
        children: [
          Expanded(
            // 🌟 BỌC GESTURE DETECTOR ĐỂ BẮT CLICK KHOẢNG TRỐNG
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => UIUtil.smartTap(context, widget.onAddMemberTap),
              child: Builder(
                  builder: (context) {
                    // Xử lý Empty State
                    if (trip == null || trip.members == null || trip.members!.isEmpty) {
                      return EmptyState(text: "no_members_yet".tr);
                    }

                    // Danh sách thành viên
                    return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async => widget.controller.fetchData(),
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
                                        backgroundColor: member.isGhost ? Colors.grey[200] : AppColors.primaryBackground,
                                        backgroundImage: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) ? org_cached.CachedNetworkImageProvider(member.avatarUrl!, maxWidth: 150, maxHeight: 150) : null,
                                        child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                                            ? (member.isGhost ? const Icon(Icons.visibility_off, color: Colors.grey, size: 10) : Text(memberInitial, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))
                                            : null,
                                      ),
                                      if (isMemberOwner) const Text("👑", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  title: Row(
                                      children: [
                                        Expanded(
                                            child: Text(member.name ?? "anonymous".tr, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)
                                        ),
                                        if (isDisabled)
                                          Text(" (${'suspended'.tr})", style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                                      ]
                                  ),
                                  subtitle: Text(member.isGhost ? "ghost_user_label".tr : "app_member_label".tr),
                                  trailing: const Icon(Icons.settings, color: Colors.grey, size: 22),

                                  // 🌟 MENU ADMIN QUẢN LÝ THÀNH VIÊN KHI BẤM VÀO

                                  onTap: () {
                                    Get.bottomSheet(
                                        Container(
                                          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 48 + MediaQuery.of(context).padding.bottom),
                                          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(member.name ?? "unnamed".tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 16),

                                              ListTile(
                                                  leading: const Icon(Icons.email, color: Colors.blue),
                                                  title: Text("email_or_account".tr),
                                                  subtitle: Text(member.email ?? "no_info".tr)
                                              ),

                                              if (widget.controller.isOwner && !isMemberOwner) ...[
                                                const Divider(),
                                                Text("member_admin_label".tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                                const SizedBox(height: 8),

                                                ListTile(
                                                    leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                                                    title: Text("transfer_owner".tr),
                                                    onTap: () { Get.back(); widget.controller.transferOwner(member.id); }
                                                ),
                                                ListTile(
                                                    leading: Icon(isDisabled ? Icons.play_arrow : Icons.pause, color: Colors.orange),
                                                    title: Text(isDisabled ? "unlock_member".tr : "suspend_member".tr),
                                                    onTap: () {
                                                      Get.back();
                                                      if (isDisabled) {
                                                        widget.controller.activateMember(member.id);
                                                      } else {
                                                        widget.controller.disableMember(member.id);
                                                      }
                                                    }
                                                ),
                                                ListTile(
                                                    leading: const Icon(Icons.person_remove, color: Colors.red),
                                                    title: Text("kick_from_group".tr, style: const TextStyle(color: Colors.red)),
                                                    onTap: () {
                                                      Get.back(); // Đóng bottom sheet
                                                      Get.dialog(
                                                          KickMemberDialog(
                                                              userName: member.name ?? "unnamed".tr,
                                                              onConfirm: (forgive) => widget.controller.kickMember(member.id, forgive)
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
          if (!widget.controller.isOwner)
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
                  label: Text("leave_group".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text("leave_group_question".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
                        content: Text("leave_group_confirm_desc".tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange, 
                              side: const BorderSide(color: Colors.orange),
                              minimumSize: const Size(100, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                            ),
                            onPressed: () => Get.back(),
                            child: Text("cancel_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange, 
                              foregroundColor: Colors.white,
                              minimumSize: const Size(100, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                            ),
                            onPressed: () {
                              Get.back();
                              widget.controller.leaveTrip();
                            },
                            child: Text("confirm_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
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
