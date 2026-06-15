import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/toast_util.dart';
import '../../../utils/trip_category_util.dart';
import 'member_avatars.dart';
import 'trip_actions_helper.dart';

class TripGalleryCard extends StatelessWidget {
  final dynamic trip;

  const TripGalleryCard({super.key, required this.trip});

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

    return Card(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Area
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: trip.coverUrl != null && (trip.coverUrl as String).isNotEmpty
                          ? Image.network(
                              trip.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/no_image.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/no_image.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Category Icon Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          TripCategoryUtil.getIconData(trip.categoryIcon),
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    // Offline badge
                    if (trip.id == -1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info Area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.description ?? "Không có mô tả",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MemberAvatars(trip: trip),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
