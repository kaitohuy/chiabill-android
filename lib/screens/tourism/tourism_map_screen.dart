import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/tourism_controller.dart';
import 'widgets/tourism_map_view.dart';
import 'widgets/tourism_gallery_view.dart';
import 'create_place_screen.dart';
import 'dart:async';
import '../../controllers/user_guide_controller.dart';
import '../../widgets/user_guide_overlay.dart';

class TourismMapScreen extends StatefulWidget {
  const TourismMapScreen({super.key});

  @override
  State<TourismMapScreen> createState() => _TourismMapScreenState();
}

class _TourismMapScreenState extends State<TourismMapScreen> with AutomaticKeepAliveClientMixin {
  final TourismController controller = Get.find<TourismController>();
  Timer? _debounce;
  Worker? _noticeWorker;
  Worker? _googleNoticeWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Kiểm tra ngay khi khởi tạo xem có cần hiện hướng dẫn không
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTourismGuide();
    });

    // Lắng nghe thay đổi flag từ Controller cho các lần toggle sau
    _noticeWorker = ever(controller.shouldShowMaptilerNotice, (shouldShow) {
      if (shouldShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMaptilerNoticeDialog();
        });
      }
    });

    _googleNoticeWorker = ever(controller.shouldShowGoogleMapsNotice, (shouldShow) {
      if (shouldShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGoogleMapsNoticeDialog();
        });
      }
    });
  }

  void _checkAndShowTourismGuide() {
    final userGuideController = Get.find<UserGuideController>();
    if (userGuideController.guideTourismEnabled.value) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _startTourismGuide(userGuideController);
      });
    } else {
      _checkAndShowMapNotices();
    }
  }

  void _checkAndShowMapNotices() {
    if (controller.shouldShowMaptilerNotice.value) {
      _showMaptilerNoticeDialog();
    } else if (controller.shouldShowGoogleMapsNotice.value) {
      _showGoogleMapsNoticeDialog();
    }
  }

  void _startTourismGuide(UserGuideController userGuideController) {
    if (!mounted) return;

    final targets = [
      GuideTarget(
        key: userGuideController.searchPlaceKey,
        title: "Tìm kiếm địa điểm",
        description: "Nhập tên địa danh, thành phố hoặc danh thắng du lịch bạn muốn khám phá.",
        isCircle: false,
      ),
      GuideTarget(
        key: userGuideController.filterCategoryKey,
        title: "Lọc theo danh mục",
        description: "Lọc nhanh các địa điểm xung quanh theo thể loại như: bãi biển, núi non, quán cafe, cắm trại,...",
        isCircle: true,
      ),
      GuideTarget(
        key: userGuideController.toggleMapKey,
        title: "Đổi chế độ xem",
        description: "Chuyển đổi linh hoạt giữa giao diện Bản đồ trực quan và Bộ sưu tập ảnh lưới địa điểm.",
        isCircle: false,
      ),
      GuideTarget(
        key: userGuideController.mapProviderToggleKey,
        title: "Đổi nhà cung cấp Bản đồ",
        description: "Chuyển đổi nhanh giữa bản đồ vector mặc định (Flutter Map) và bản đồ vệ tinh độ nét cao (Google Maps).",
        isCircle: true,
      ),
      GuideTarget(
        key: userGuideController.mapLayersKey,
        title: "Lớp giao diện Bản đồ",
        description: "Chọn các kiểu hiển thị bản đồ khác nhau như: Ngoài trời, Địa hình topo, Phong cách vẽ màu nước, Tối giản...",
        isCircle: true,
      ),
      GuideTarget(
        key: userGuideController.pinNewPlaceKey,
        title: "Ghim địa điểm mới",
        description: "Đóng góp và ghim thêm một địa điểm du lịch, vui chơi mới chưa có trên hệ thống của Chiabill.",
        isCircle: true,
      ),
    ];

    UserGuideOverlay.show(
      context,
      targets: targets,
      onCompleted: () {
        userGuideController.setGuideEnabled('tourism', false);
        _checkAndShowMapNotices();
      },
      onDismissed: () {
        userGuideController.setGuideEnabled('tourism', false);
        _checkAndShowMapNotices();
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _noticeWorker?.dispose();
    _googleNoticeWorker?.dispose();
    super.dispose();
  }

  void _showGoogleMapsNoticeDialog() {
    controller.markGoogleMapsNoticeSeen(); // Báo controller đã xử lý xong
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha:0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thông báo về bản đồ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Bản đồ Google Maps có các biểu tượng và tên địa điểm hiển thị kém chi tiết và mờ hơn một chút so với bản đồ mặc định hiện tại.\n\n'
                'Bạn có chắc chắn muốn chuyển sang Google Maps?',
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () {
                        controller.isUsingGoogleMaps.value = false; // Quay lại Flutter Map
                        Navigator.of(context).pop();
                      },
                      child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaptilerNoticeDialog() {
    controller.markMaptilerNoticeSeen(); // Báo controller đã xử lý xong
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha:0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map_outlined, color: Colors.orange, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thông báo về bản đồ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Thư viện bản đồ này được cung cấp bởi bên thứ 3, tuy nhiên họ lại không đưa quần đảo Hoàng Sa, Trường Sa của chúng ta vào, thậm chí Biển Đông còn bị đổi tên thành South China Sea.\n\n'
                'Tôi đã khắc phục bằng cách "đè tem", trông có hơi xấu một chút, mong các bạn thông cảm. Tôi sẽ cố gắng tìm ra cách để trông các khu vực trên đẹp hơn.\n\n'
                'Cảm ơn mọi người rất nhiều! 🇻🇳',
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đã hiểu, cảm ơn!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      controller.searchPlaces(query);
    });
  }

  final Map<String, Map<String, dynamic>> _categories = {
    'Tất cả': {'name': 'Tất cả', 'icon': Icons.map, 'color': Colors.blueGrey},
    'Biển': {'name': 'Biển', 'icon': Icons.beach_access, 'color': Colors.blue},
    'Núi': {'name': 'Núi', 'icon': Icons.terrain, 'color': Colors.green},
    'Bể bơi': {'name': 'Bể bơi', 'icon': Icons.pool, 'color': Colors.cyan},
    'TTTM': {'name': 'TTTM', 'icon': Icons.local_mall, 'color': Colors.purple},
    'Di tích': {'name': 'Di tích', 'icon': Icons.account_balance, 'color': Colors.brown},
    'Cafe': {'name': 'Cafe', 'icon': Icons.local_cafe, 'color': Colors.orange},
    'Nhà hàng': {'name': 'Nhà hàng', 'icon': Icons.restaurant, 'color': Colors.red},
    'Cắm trại': {'name': 'Cắm trại', 'icon': Icons.park, 'color': Colors.green[700]},
    'Khác': {'name': 'Khác', 'icon': Icons.category, 'color': Colors.grey},
  };

  void _showCategoryFilterBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Lọc Theo Danh Mục",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Obx(() {
                  if (controller.selectedCategory.value != 'Tất cả') {
                    return TextButton(
                      onPressed: () {
                        controller.selectedCategory.value = 'Tất cả';
                        Get.back();
                      },
                      child: const Text("Xóa lọc", style: TextStyle(color: Colors.red)),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final key = _categories.keys.elementAt(index);
                  final item = _categories[key]!;
                  return Obx(() {
                    final isSelected = key == controller.selectedCategory.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? item['color'].withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? item['color'] : Colors.grey[200]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item['color'].withOpacity(0.15),
                          child: Icon(item['icon'], color: item['color']),
                        ),
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? item['color'] : Colors.black87,
                          ),
                        ),
                        trailing: isSelected ? Icon(Icons.check_circle, color: item['color']) : null,
                        onTap: () {
                          controller.selectedCategory.value = key;
                          Get.back();
                        },
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View hoặc Gallery View
          Positioned.fill(
            child: Obx(() {
              if (controller.isMapView.value) {
                return const TourismMapView();
              } else {
                return const TourismGalleryView();
              }
            }),
          ),
          
          // 2. Search Bar & Toggle & Results
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            key: Get.find<UserGuideController>().searchPlaceKey,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                              ]
                            ),
                            child: TextField(
                              controller: controller.searchController,
                              onChanged: _onSearchChanged,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: "Tìm kiếm địa điểm du lịch...",
                                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(Icons.search, color: Colors.grey, size: 20),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 24,
                                ),
                                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller.searchController,
                                  builder: (context, value, child) {
                                    if (value.text.isNotEmpty) {
                                      return IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                        onPressed: () {
                                          controller.searchController.clear();
                                          controller.searchPlaces("");
                                        },
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          key: Get.find<UserGuideController>().filterCategoryKey,
                          onTap: _showCategoryFilterBottomSheet,
                          child: Obx(() {
                            final bool isFiltering = controller.selectedCategory.value != 'Tất cả';
                            return Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isFiltering ? AppColors.primary : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                                ]
                              ),
                              child: Icon(
                                Icons.tune,
                                color: isFiltering ? Colors.white : Colors.black87,
                                size: 20,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        // Toggle Map / Gallery Capsule
                        Obx(() => GestureDetector(
                          key: Get.find<UserGuideController>().toggleMapKey,
                          onTap: () => controller.isMapView.value = !controller.isMapView.value,
                          child: Container(
                            width: 64,
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                              ]
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: controller.isMapView.value ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      controller.isMapView.value ? Icons.map_rounded : Icons.grid_view_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                  // Kết quả tìm kiếm
                  Obx(() {
                    if (!controller.isSearching.value) return const SizedBox.shrink();
                    
                    if (controller.isLoading.value) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (controller.filteredSearchResults.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            const Icon(Icons.sentiment_dissatisfied, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text("Không tìm thấy địa điểm này"),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              onPressed: () {
                                Get.to(() => const CreatePlaceScreen());
                              },
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text("Ghim địa điểm mới"),
                            )
                          ],
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: controller.filteredSearchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = controller.filteredSearchResults[index];
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Icon(Icons.place, color: AppColors.primary),
                            ),
                            title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${place.category} • ${place.city}"),
                            onTap: () {
                              controller.moveToPlace(place);
                              controller.isMapView.value = true; // Chuyển sang Map để định vị
                            },
                          );
                        },
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
