import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import '../../controllers/tourism_controller.dart';
import '../../utils/marker_generator.dart';
import 'place_detail_screen.dart';
import 'create_place_screen.dart';
import 'dart:async';

class TourismMapScreen extends StatefulWidget {
  const TourismMapScreen({super.key});

  @override
  State<TourismMapScreen> createState() => _TourismMapScreenState();
}

class _TourismMapScreenState extends State<TourismMapScreen> with AutomaticKeepAliveClientMixin {
  final TourismController controller = Get.put(TourismController());
  Timer? _debounceTimer;
  Timer? _debounce;
  Worker? _noticeWorker;
  Worker? _placesWorker;
  Worker? _categoryWorker;
  final Map<int, gmap.BitmapDescriptor> _customIconsWithText = {};
  gmap.BitmapDescriptor? _defaultIconNoText;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Lắng nghe flag từ Controller, Screen tự quyết định hiện Dialog
    _noticeWorker = ever(controller.shouldShowMaptilerNotice, (shouldShow) {
      if (shouldShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMaptilerNoticeDialog();
        });
      }
    });

    _generateCustomMarkers();
    _placesWorker = ever(controller.places, (_) {
      _generateCustomMarkers();
    });
    _categoryWorker = ever(controller.selectedCategory, (_) {
      _generateCustomMarkers();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounce?.cancel();
    _noticeWorker?.dispose();
    _placesWorker?.dispose();
    _categoryWorker?.dispose();
    _customIconsWithText.clear();
    _defaultIconNoText = null;
    super.dispose();
  }

  void _generateCustomMarkers() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted) return;

      // 1. Tạo icon mặc định không chữ dùng chung nếu chưa có
      if (_defaultIconNoText == null) {
        _defaultIconNoText = await MarkerGenerator.createMarkerWithText(
          "Default",
          AppColors.primary,
          showText: false,
        );
        if (mounted) {
          setState(() {});
        }
      }

      // 2. Chỉ sinh custom marker có chữ khi là Google Maps và mức zoom đủ sâu (>= 10.0)
      if (!controller.isUsingGoogleMaps.value || controller.currentZoom.value < 10.0) {
        return;
      }

      final gController = controller.googleMapController;
      if (gController == null) return;

      try {
        // 3. Lấy viewport hiện tại (Vùng địa lý đang hiển thị trên màn hình)
        final bounds = await gController.getVisibleRegion();

        // 4. Lọc ra các địa điểm thực sự nằm trong viewport hiện tại
        final visiblePlaces = controller.filteredPlaces.where((place) {
          return bounds.southwest.latitude <= place.latitude &&
              place.latitude <= bounds.northeast.latitude &&
              bounds.southwest.longitude <= place.longitude &&
              place.longitude <= bounds.northeast.longitude;
        }).toList();

        // 5. Gom việc sinh custom marker có chữ cho các địa điểm trong viewport
        final Map<int, gmap.BitmapDescriptor> newIcons = {};
        for (var place in visiblePlaces) {
          if (!_customIconsWithText.containsKey(place.id)) {
            final iconText = await MarkerGenerator.createMarkerWithText(
              place.name,
              AppColors.primary,
              showText: true,
            );
            newIcons[place.id] = iconText;
          }
        }

        if (mounted && newIcons.isNotEmpty) {
          setState(() {
            _customIconsWithText.addAll(newIcons);
          });
        }
      } catch (e) {
        debugPrint("Error generating visible markers: $e");
      }
    });
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

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.defaultCenter,
        initialZoom: controller.currentZoom.value.isNaN ? 6.0 : controller.currentZoom.value,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (position, hasGesture) {
          if (!position.zoom.isNaN && position.zoom != controller.currentZoom.value) {
            controller.currentZoom.value = position.zoom;
          }
          if (hasGesture && !position.center.latitude.isNaN && !position.center.longitude.isNaN) {
            controller.currentCenter.value = position.center;
          }
        },
      ),
      children: [
        Obx(() => TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/${controller.currentMapStyle.value}/256/{z}/{x}/{y}{r}.png?key=${dotenv.env['MAPTILER_API_KEY'] ?? 'ZX1daXespLxGCIWidVUM'}',
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.kaitohuy.chiabill',
        )),
        // Lớp nhãn địa danh chủ quyền Việt Nam
        Obx(() => MarkerLayer(
          markers: _buildSovereigntyLabels(controller.currentZoom.value),
        )),
        Obx(() => MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            maxZoom: 15,
            markers: controller.filteredPlaces.map((place) {
              return Marker(
                width: 120.0,
                height: 80.0,
                point: LatLng(place.latitude, place.longitude),
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => PlaceDetailScreen(place: place));
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 30),
                      if (controller.currentZoom.value >= 6.0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            place.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        )),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: gmap.LatLng(controller.currentCenter.value.latitude, controller.currentCenter.value.longitude),
        zoom: controller.currentZoom.value,
      ),
      onMapCreated: (gmap.GoogleMapController gController) {
        controller.googleMapController = gController;
      },
      onCameraMove: (gmap.CameraPosition position) {
        if (!position.zoom.isNaN) {
          controller.currentZoom.value = position.zoom;
        }
        if (!position.target.latitude.isNaN && !position.target.longitude.isNaN) {
          controller.currentCenter.value = LatLng(position.target.latitude, position.target.longitude);
        }
      },
      onCameraIdle: () {
        _generateCustomMarkers();
      },
      clusterManagers: {
        gmap.ClusterManager(
          clusterManagerId: const gmap.ClusterManagerId('places_cluster'),
          onClusterTap: (gmap.Cluster cluster) {
            controller.currentZoom.value += 2.0;
            controller.currentCenter.value = LatLng(cluster.position.latitude, cluster.position.longitude);
            controller.googleMapController?.animateCamera(
              gmap.CameraUpdate.newLatLngZoom(cluster.position, controller.currentZoom.value),
            );
          },
        ),
      },
      markers: controller.filteredPlaces.map((place) {
        final bool showText = controller.currentZoom.value >= 10.0;
        return gmap.Marker(
          markerId: gmap.MarkerId(place.id.toString()),
          position: gmap.LatLng(place.latitude, place.longitude),
          clusterManagerId: const gmap.ClusterManagerId('places_cluster'),
          icon: (showText ? _customIconsWithText[place.id] : _defaultIconNoText) ?? _defaultIconNoText ?? gmap.BitmapDescriptor.defaultMarker,
          onTap: () {
            Get.to(() => PlaceDetailScreen(place: place));
          },
        );
      }).toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          Obx(() {
            if (controller.isUsingGoogleMaps.value) {
              return _buildGoogleMap();
            } else {
              return _buildFlutterMap();
            }
          }),
          // 2. Search Bar & Results
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                              ]
                            ),
                            child: TextField(
                              controller: controller.searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: "Tìm kiếm địa điểm du lịch...",
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller.searchController,
                                  builder: (context, value, child) {
                                    if (value.text.isNotEmpty) {
                                      return IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showCategoryFilterBottomSheet,
                          child: Obx(() {
                            final bool isFiltering = controller.selectedCategory.value != 'Tất cả';
                            return Container(
                              width: 50,
                              height: 50,
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
                              ),
                            );
                          }),
                        ),
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

                  return Flexible(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                            onTap: () => controller.moveToPlace(place),
                          );
                        },
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút toggle Map để test
          FloatingActionButton(
            heroTag: 'map_toggle',
            onPressed: () {
              controller.isUsingGoogleMaps.value = !controller.isUsingGoogleMaps.value;
            },
            backgroundColor: Colors.white,
            child: Obx(() => Icon(
              controller.isUsingGoogleMaps.value ? Icons.map : Icons.satellite, 
              color: AppColors.primary,
            )),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (!controller.isUsingGoogleMaps.value) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'map_layers',
                    onPressed: () => _showMapStylePicker(context, controller),
                    backgroundColor: Colors.white,
                    child: Icon(Icons.layers, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          FloatingActionButton(
            heroTag: 'add_place',
            onPressed: () {
              Get.to(() => const CreatePlaceScreen());
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add_location_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Tạo danh sách nhãn địa danh chủ quyền Việt Nam
  /// Hiển thị/ẩn tuỳ theo mức zoom để không làm rối bản đồ
  List<Marker> _buildSovereigntyLabels(double zoom) {
    // scaleFactor dựa trên mức zoom hiện tại, nhỏ nhất là 0.55 và lớn nhất là 1.45
    final double scaleFactor = (zoom / 6.0).clamp(0.55, 1.45);
    final double markerWidth = 145.0 * scaleFactor;
    final double markerHeight = 65.0 * scaleFactor;
    final double hPadding = 10.0 * scaleFactor;
    final double vPadding = 6.0 * scaleFactor;
    final double borderRadius = 8.0 * scaleFactor;
    final double borderWidth = 1.5 * scaleFactor;
    final double shadowBlur = 6.0 * scaleFactor;

    // Danh sách địa danh: {tên TV, lat, lng, zoom tối thiểu để hiện}
    final locations = [
      // Biển Đông — đè lên "South China Sea"
      _SovereigntyLocation('Biển Đông', 11.6, 113.8, minZoom: 1.0, fontSize: 16 * scaleFactor, italic: true, color: const Color(0xFF1565C0)),
      // Quần đảo Hoàng Sa — đè lên "Paracel Islands"
      _SovereigntyLocation('Quần đảo\nHoàng Sa', 16.35, 111.75, minZoom: 3.5, fontSize: 13 * scaleFactor),
      // Quần đảo Trường Sa — đè lên "Spratly Islands"
      _SovereigntyLocation('Quần đảo\nTrường Sa', 9.00, 114.00, minZoom: 3.5, fontSize: 13 * scaleFactor),
      // Đảo Phú Quốc — hiện khi zoom 8+
      _SovereigntyLocation('Đảo Phú Quốc', 10.22, 103.96, minZoom: 8.0, fontSize: 12 * scaleFactor),
      // Côn Đảo — hiện khi zoom 8+
      _SovereigntyLocation('Côn Đảo', 8.70, 106.62, minZoom: 8.0, fontSize: 12 * scaleFactor),
      // Đảo Lý Sơn — hiện khi zoom 9+
      _SovereigntyLocation('Đảo Lý Sơn', 15.37, 109.12, minZoom: 9.0, fontSize: 12 * scaleFactor),
    ];

    return locations
        .where((loc) => zoom >= loc.minZoom)
        .map((loc) => Marker(
              width: markerWidth,
              height: markerHeight,
              point: LatLng(loc.lat, loc.lng),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
                  decoration: BoxDecoration(
                    color: Colors.white, // Solid white to cover the underlying text completely
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: loc.color.withValues(alpha:0.6), width: borderWidth),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.15),
                        blurRadius: shadowBlur,
                        offset: Offset(0, 3 * scaleFactor),
                      )
                    ],
                  ),
                  child: Text(
                    loc.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: loc.fontSize,
                      fontWeight: FontWeight.bold,
                      color: loc.color,
                      fontStyle: loc.italic ? FontStyle.italic : FontStyle.normal,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ))
        .toList();
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
                        _fitFilteredBounds();
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
                          _fitFilteredBounds();
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

  void _fitFilteredBounds() {
    final filtered = controller.filteredPlaces;
    if (filtered.isEmpty) return;

    if (controller.isUsingGoogleMaps.value) {
      final gController = controller.googleMapController;
      if (gController == null) return;

      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var place in filtered) {
        if (place.latitude < minLat) minLat = place.latitude;
        if (place.latitude > maxLat) maxLat = place.latitude;
        if (place.longitude < minLng) minLng = place.longitude;
        if (place.longitude > maxLng) maxLng = place.longitude;
      }

      // Đưa camera về bao phủ toàn bộ bounds địa danh đã lọc
      gController.animateCamera(
        gmap.CameraUpdate.newLatLngBounds(
          gmap.LatLngBounds(
            southwest: gmap.LatLng(minLat, minLng),
            northeast: gmap.LatLng(maxLat, maxLng),
          ),
          50.0, // padding để các marker không sát lề màn hình quá
        ),
      );
    } else {
      // MapTiler (flutter_map) camera movement
      final mapController = controller.mapController;
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var place in filtered) {
        if (place.latitude < minLat) minLat = place.latitude;
        if (place.latitude > maxLat) maxLat = place.latitude;
        if (place.longitude < minLng) minLng = place.longitude;
        if (place.longitude > maxLng) maxLng = place.longitude;
      }

      final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
      mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0),
      ));
    }
  }

  void _showMapStylePicker(BuildContext context, TourismController controller) {
    final styleGroups = [
      {
        'label': 'Simple',
        'icon': Icons.crop_square,
        'styles': <String, String>{
          'backdrop': 'Backdrop',
          'basic-v2': 'Base',
          'dataviz': 'Dataviz',
          'landscape': 'Landscape',
          'toner-v2': 'Toner',
        }
      },
      {
        'label': 'Navigation',
        'icon': Icons.navigation,
        'styles': <String, String>{
          'hybrid': 'Satellite Hybrid',
          'openstreetmap': 'OpenStreetMap',
          'satellite': 'Satellite Plain',
          'streets-v2': 'Streets',
        }
      },
      {
        'label': 'Terrain',
        'icon': Icons.terrain,
        'styles': <String, String>{
          'ocean': 'Ocean',
          'outdoor-v2': 'Outdoor',
          'topo-v2': 'Topo',
          'winter-v2': 'Winter',
        }
      },
      {
        'label': 'Others',
        'icon': Icons.more_horiz,
        'styles': <String, String>{
          'aquarelle': 'Aquarelle',
          'dataviz-light': 'Dataviz Light',
          'dataviz-dark': 'Dataviz Dark',
        }
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.layers, size: 20),
                      SizedBox(width: 8),
                      Text("Lớp Bản Đồ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: styleGroups.length,
                    itemBuilder: (context, i) {
                      final group = styleGroups[i];
                      return _MapStyleGroup(
                        label: group['label'] as String,
                        icon: group['icon'] as IconData,
                        styles: group['styles'] as Map<String, String>,
                        controller: controller,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MapStyleGroup extends StatefulWidget {
  final String label;
  final IconData icon;
  final Map<String, String> styles;
  final TourismController controller;

  const _MapStyleGroup({
    required this.label,
    required this.icon,
    required this.styles,
    required this.controller,
  });

  @override
  State<_MapStyleGroup> createState() => _MapStyleGroupState();
}

class _MapStyleGroupState extends State<_MapStyleGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Tự động mở nhóm đang chứa style đang được chọn
    _expanded = widget.styles.containsKey(widget.controller.currentMapStyle.value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: widget.styles.entries.map((entry) {
                return Obx(() {
                  final isSelected = widget.controller.currentMapStyle.value == entry.key;
                  return InkWell(
                    onTap: () {
                      widget.controller.currentMapStyle.value = entry.key;
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha:0.08) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const Divider(height: 1),
      ],
    );
  }
}

/// Data class lưu thông tin nhãn địa danh chủ quyền Việt Nam
class _SovereigntyLocation {
  final String name;
  final double lat;
  final double lng;
  final double minZoom;
  final double fontSize;
  final bool italic;
  final Color color;

  const _SovereigntyLocation(
    this.name,
    this.lat,
    this.lng, {
    required this.minZoom,
    this.fontSize = 13,
    this.italic = false,
    this.color = const Color(0xFF444444),
  });
}
