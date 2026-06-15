import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/toast_util.dart';
import '../../../utils/trip_category_util.dart';
import '../../trip/edit_trip_dialog.dart';
import '../../trip/itinerary_screen.dart';
import 'member_avatars.dart';
import 'trip_actions_helper.dart';

class TripCard extends StatelessWidget {
  final dynamic trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    String dateStr = "";
    if (trip.startDate != null && (trip.startDate as String).isNotEmpty) {
      String startDayMonth = "";
      String startYear = "";
      final startParts = (trip.startDate as String).substring(0, 10).split('-');
      if (startParts.length == 3) {
        startDayMonth = "${startParts[2]}/${startParts[1]}";
        startYear = startParts[0];
      }

      String endDayMonth = "";
      String endYear = "";
      if (trip.endDate != null && (trip.endDate as String).isNotEmpty) {
        final endParts = (trip.endDate as String).substring(0, 10).split('-');
        if (endParts.length == 3) {
          endDayMonth = "${endParts[2]}/${endParts[1]}";
          endYear = endParts[0];
        }
      }

      if (endDayMonth.isNotEmpty && endDayMonth != startDayMonth) {
        if (startYear == endYear) {
          dateStr = "$startDayMonth - $endDayMonth/$endYear";
        } else {
          dateStr = "$startDayMonth/$startYear - $endDayMonth/$endYear";
        }
      } else {
        dateStr = "$startDayMonth/$startYear";
      }
    } else {
      dateStr = trip.createdAt ?? "";
      if (dateStr.length >= 10) {
        final parts = dateStr.substring(0, 10).split('-');
        if (parts.length == 3) {
          dateStr = "${parts[2]}/${parts[1]}/${parts[0]}";
        }
      }
    }

    Color categoryColor = TripCategoryUtil.getColor(trip.categoryIcon);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(trip.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.65,
          children: [
            SlidableAction(
              onPressed: (context) {
                if (trip.id == -1) return;
                Get.to(() => ItineraryScreen(tripId: trip.id));
              },
              backgroundColor: Colors.teal.shade50,
              foregroundColor: Colors.teal.shade700,
              icon: Icons.explore_outlined,
              label: 'Lịch trình',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            SlidableAction(
              onPressed: (context) {
                if (trip.id == -1) return;
                Get.bottomSheet(EditTripDialog(trip: trip, isFromHome: true), isScrollControlled: true);
              },
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              icon: Icons.edit_outlined,
              label: 'Sửa',
            ),
            SlidableAction(
              onPressed: (context) {
                if (trip.id == -1) return;
                TripActionsHelper.confirmDeleteTrip(trip);
              },
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              icon: Icons.delete_outline_rounded,
              label: 'Xóa',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (trip.id == -1) {
                ToastUtil.showWarning("Đang chờ đồng bộ", "Chuyến đi này chưa được đồng bộ lên máy chủ");
                return;
              }
              Get.toNamed(Routes.TRIP_DETAIL, arguments: trip.id);
            },
            onLongPress: () => trip.id == -1 ? null : TripActionsHelper.showTripOptions(context, trip),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      image: trip.coverUrl != null && (trip.coverUrl as String).isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(trip.coverUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: trip.coverUrl != null && (trip.coverUrl as String).isNotEmpty
                        ? null
                        : Icon(
                            TripCategoryUtil.getIconData(trip.categoryIcon),
                            color: categoryColor,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (trip.id == -1) ...[
                              const Icon(Icons.schedule, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                            ],
                            Expanded(child: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(trip.description ?? "Không có mô tả", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MemberAvatars(trip: trip),
                      const SizedBox(height: 8),
                      Text(dateStr, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
