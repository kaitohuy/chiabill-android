import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class MemberAvatars extends StatelessWidget {
  final dynamic trip;

  const MemberAvatars({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip.members == null || (trip.members as List).isEmpty) {
      return Text(
        "${trip.memberCount ?? 0} TV",
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
      );
    }

    final members = trip.members as List;
    final int displayCount = members.length > 3 ? 3 : members.length;
    final int extraCount = (trip.memberCount ?? members.length) - displayCount;

    return SizedBox(
      height: 28,
      width: (displayCount * 14.0) + (extraCount > 0 ? 24.0 : 0) + 14.0, // Fixed width to align right properly
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              right: i * 14.0 + (extraCount > 0 ? 20.0 : 0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: members[displayCount - 1 - i].avatarUrl != null
                      ? NetworkImage(members[displayCount - 1 - i].avatarUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: members[displayCount - 1 - i].avatarUrl == null
                      ? Text(
                          members[displayCount - 1 - i].name?.substring(0, 1).toUpperCase() ?? "?",
                          style: const TextStyle(fontSize: 10, color: Colors.black),
                        )
                      : null,
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: AppColors.primaryBackgroundLight,
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryBackgroundLight,
                  child: Text(
                    "+$extraCount",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
