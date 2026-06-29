import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/toast_util.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../controllers/home_controller.dart';
import '../../trip/edit_trip_dialog.dart';

class TripActionsHelper {
  static void showTripOptions(BuildContext context, dynamic trip) {
    if (Get.isBottomSheetOpen == true) return;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 16 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trip.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("S盻ｭa thﾃｴng tin"),
              onTap: () {
                Get.back();
                Get.bottomSheet(EditTripDialog(trip: trip, isFromHome: true), isScrollControlled: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Xﾃｳa chuy蘯ｿn ﾄ訴", style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                confirmDeleteTrip(trip);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void confirmDeleteTrip(dynamic trip) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xﾃｳa chuy蘯ｿn ﾄ訴?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
        content: const Text("Chuy蘯ｿn ﾄ訴 nﾃy s蘯ｽ b盻・xﾃｳa. B蘯｡n v蘯ｫn cﾃｳ th盻・ph盻･c h盻妬 l蘯｡i trong Thﾃｹng rﾃ｡c.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red, 
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
            ),
            onPressed: () => Get.back(),
            child: Text("cancel_caps_alt".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
            ),
            onPressed: () async {
              Get.back();
              final result = await TripRepository().deleteTrip(trip.id!);
              if (result.success) {
                ToastUtil.showSuccess("Thﾃnh cﾃｴng", "ﾄ静｣ xﾃｳa chuy蘯ｿn ﾄ訴");
                if (Get.isRegistered<HomeController>()) {
                  Get.find<HomeController>().fetchTrips(isRefresh: true);
                }
              } else {
                ToastUtil.showError("error".tr, result.message ?? "cannot_delete".tr);
              }
            },
            child: const Text("Xﾃ鄭", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

