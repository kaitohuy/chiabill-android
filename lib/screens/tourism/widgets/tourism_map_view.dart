import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import '../../../theme/app_colors.dart';
import '../../../controllers/tourism_controller.dart';
import '../../../controllers/main_controller.dart';
import '../../../utils/marker_generator.dart';
import '../place_detail_screen.dart';
import '../create_place_screen.dart';
import '../../../controllers/user_guide_controller.dart';

class TourismMapView extends StatefulWidget {
  const TourismMapView({super.key});

  @override
  State<TourismMapView> createState() => _TourismMapViewState();
}

class _TourismMapViewState extends State<TourismMapView> {
  // Cấu hình ngưỡng Zoom để hiển thị Marker (Áp dụng cho cả Google Maps và Flutter Map)
  static const double zoomShowLabel = 8.0;   // Zoom >= 6.0 sẽ hiện nhãn tên địa điểm
  static const double zoomShowImage = 9.0;  // Zoom >= 10.0 sẽ hiện ghim ảnh + tên

  final TourismController controller = Get.find<TourismController>();
  Timer? _debounceTimer;
  Worker? _placesWorker;
  Worker? _categoryWorker;
  final Map<int, gmap.BitmapDescriptor> _customIconsWithText = {};
  gmap.BitmapDescriptor? _defaultIconNoText;
  double _lastZoom = 0.0;

  Worker? _mapToggleWorker;
  
  final Rxn<LatLngBounds> _flutterMapBounds = Rxn<LatLngBounds>();
  Timer? _flutterMapBoundsTimer;

  @override
  void initState() {
    super.initState();
    _generateCustomMarkers();
    _placesWorker = ever(controller.places, (_) {
      _generateCustomMarkers();
    });
    _categoryWorker = ever(controller.selectedCategory, (_) {
      _generateCustomMarkers();
    });
    
    // Đồng bộ vị trí giữa Google Maps và Flutter Map khi chuyển đổi
    _mapToggleWorker = ever(controller.isUsingGoogleMaps, (isUsingGoogle) {
      final lat = controller.currentCenter.value.latitude;
      final lng = controller.currentCenter.value.longitude;
      final zoom = controller.currentZoom.value;
      if (lat.isNaN || lng.isNaN || zoom.isNaN) return;

      if (isUsingGoogle) {
        controller.googleMapController?.animateCamera(
          gmap.CameraUpdate.newLatLngZoom(gmap.LatLng(lat, lng), zoom)
        );
      } else {
        controller.mapController.move(LatLng(lat, lng), zoom);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _flutterMapBoundsTimer?.cancel();
    _placesWorker?.dispose();
    _categoryWorker?.dispose();
    _mapToggleWorker?.dispose();
    _customIconsWithText.clear();
    _defaultIconNoText = null;
    MarkerGenerator.clearCache();
    super.dispose();
  }

  void _generateCustomMarkers() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted) return;

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

      if (!controller.isUsingGoogleMaps.value || controller.currentZoom.value < zoomShowLabel) {
        return;
      }

      final double zoom = controller.currentZoom.value;
      final bool showImage = zoom >= zoomShowImage;

      // Xoá cache khi chuyển giao giữa chế độ chỉ chữ và chế độ ảnh
      final bool wasShowImage = _lastZoom >= zoomShowImage;
      final bool isShowImage = zoom >= zoomShowImage;
      if (wasShowImage != isShowImage) {
        _customIconsWithText.clear();
      }
      _lastZoom = zoom;

      final gController = controller.googleMapController;
      if (gController == null) return;

      try {
        final bounds = await gController.getVisibleRegion();
        final visiblePlaces = controller.filteredPlaces.where((place) {
          return bounds.southwest.latitude <= place.latitude &&
              place.latitude <= bounds.northeast.latitude &&
              bounds.southwest.longitude <= place.longitude &&
              place.longitude <= bounds.northeast.longitude;
        }).toList();

        final Map<int, gmap.BitmapDescriptor> newIcons = {};
        for (var place in visiblePlaces) {
          if (!_customIconsWithText.containsKey(place.id)) {
            gmap.BitmapDescriptor icon;
            if (showImage) {
              final hasImage = place.images.isNotEmpty;
              final imageUrl = hasImage ? place.images.first.imageUrl : '';
              icon = await MarkerGenerator.createMarkerWithImage(
                imageUrl,
                place.name,
                AppColors.primary,
              );
            } else {
              icon = await MarkerGenerator.createMarkerWithText(
                place.name,
                AppColors.primary,
                showText: true,
              );
            }
            newIcons[place.id] = icon;
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
          
          _flutterMapBoundsTimer?.cancel();
          _flutterMapBoundsTimer = Timer(const Duration(milliseconds: 200), () {
            if (mounted) {
              _flutterMapBounds.value = position.visibleBounds;
            }
          });
        },
      ),
      children: [
        Obx(() => TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/${controller.currentMapStyle.value}/256/{z}/{x}/{y}{r}.png?key=${dotenv.env['MAPTILER_API_KEY']}',
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.kaitohuy.chiabill',
        )),
        Obx(() => MarkerLayer(
          markers: _buildSovereigntyLabels(controller.currentZoom.value),
        )),
        Obx(() => MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            markers: controller.filteredPlaces.where((place) {
              final bounds = _flutterMapBounds.value;
              if (bounds == null) return true;
              return bounds.contains(LatLng(place.latitude, place.longitude));
            }).map((place) {
              final style = controller.markerStyle.value;
              final bool showImage = style == MapMarkerStyle.image;
              final bool showLabelOnly = style == MapMarkerStyle.label;

              Widget markerWidget;

              if (showImage) {
                final hasImage = place.images.isNotEmpty;
                final imageUrl = hasImage ? place.images.first.imageUrl : '';

                markerWidget = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: hasImage && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 39,
                                height: 39,
                                fit: BoxFit.cover,
                                cacheWidth: 100,
                                cacheHeight: 100,
                                errorBuilder: (_, __, ___) => Icon(Icons.landscape, color: AppColors.primary, size: 20),
                              )
                            : Icon(Icons.landscape, color: AppColors.primary, size: 20),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -4),
                      child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          place.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              } else if (showLabelOnly) {
                markerWidget = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 30),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        place.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              } else {
                markerWidget = Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                );
              }

              return Marker(
                width: showImage ? 120.0 : (showLabelOnly ? 120.0 : 16.0),
                height: showImage ? 85.0 : (showLabelOnly ? 70.0 : 16.0),
                point: LatLng(place.latitude, place.longitude),
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => PlaceDetailScreen(place: place));
                  },
                  child: markerWidget,
                ));
            }).toList(),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
        final double zoom = controller.currentZoom.value;
        final bool showCustom = zoom >= zoomShowLabel;
        return gmap.Marker(
          markerId: gmap.MarkerId(place.id.toString()),
          position: gmap.LatLng(place.latitude, place.longitude),
          clusterManagerId: const gmap.ClusterManagerId('places_cluster'),
          icon: (showCustom ? _customIconsWithText[place.id] : _defaultIconNoText) ?? _defaultIconNoText ?? gmap.BitmapDescriptor.defaultMarker,
          onTap: () {
            Get.to(() => PlaceDetailScreen(place: place));
          },
        );
      }).toSet(),
    );
  }

  List<Marker> _buildSovereigntyLabels(double zoom) {
    final double scaleFactor = (zoom / 6.0).clamp(0.55, 1.45);
    final double markerWidth = 145.0 * scaleFactor;
    final double markerHeight = 65.0 * scaleFactor;
    final double hPadding = 10.0 * scaleFactor;
    final double vPadding = 6.0 * scaleFactor;
    final double borderRadius = 8.0 * scaleFactor;
    final double borderWidth = 1.5 * scaleFactor;
    final double shadowBlur = 6.0 * scaleFactor;

    final locations = [
      _SovereigntyLocation('sovereignty_east_sea'.tr, 11.6, 113.8, minZoom: 1.0, fontSize: 16 * scaleFactor, italic: true, color: const Color(0xFF1565C0)),
      _SovereigntyLocation('sovereignty_paracel_islands'.tr, 16.35, 111.75, minZoom: 3.5, fontSize: 13 * scaleFactor),
      _SovereigntyLocation('sovereignty_spratly_islands'.tr, 9.00, 114.00, minZoom: 3.5, fontSize: 13 * scaleFactor),
      _SovereigntyLocation('sovereignty_phu_quoc_island'.tr, 10.22, 103.96, minZoom: 8.0, fontSize: 12 * scaleFactor),
      _SovereigntyLocation('sovereignty_con_dao'.tr, 8.70, 106.62, minZoom: 8.0, fontSize: 12 * scaleFactor),
      _SovereigntyLocation('sovereignty_ly_son_island'.tr, 15.37, 109.12, minZoom: 9.0, fontSize: 12 * scaleFactor),
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
                    color: Colors.white,
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

  void _showMapStylePicker(BuildContext context, TourismController controller) {
    final styleGroups = [
      {
        'label': 'style_group_simple'.tr,
        'icon': Icons.crop_square,
        'styles': <String, String>{
          'backdrop': 'style_minimalist'.tr,
          'basic-v2': 'style_base_map'.tr,
          'dataviz': 'style_data_viz'.tr,
          'landscape': 'style_landscape'.tr,
          'toner-v2': 'style_toner'.tr,
        }
      },
      {
        'label': 'style_group_navigation'.tr,
        'icon': Icons.navigation,
        'styles': <String, String>{
          'hybrid': 'style_hybrid'.tr,
          'openstreetmap': 'style_openstreetmap'.tr,
          'satellite': 'style_satellite'.tr,
          'streets-v2': 'style_streets'.tr,
        }
      },
      {
        'label': 'style_group_terrain'.tr,
        'icon': Icons.terrain,
        'styles': <String, String>{
          'ocean': 'style_ocean'.tr,
          'outdoor-v2': 'style_outdoors'.tr,
          'topo-v2': 'style_topo'.tr,
          'winter-v2': 'style_winter'.tr,
        }
      },
      {
        'label': 'style_group_other'.tr,
        'icon': Icons.more_horiz,
        'styles': <String, String>{
          'aquarelle': 'style_watercolor'.tr,
          'dataviz-light': 'style_dataviz_light'.tr,
          'dataviz-dark': 'style_dataviz_dark'.tr,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.layers, size: 20),
                      const SizedBox(width: 8),
                      Text("map_layers_title".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final bool isActiveTab = Get.isRegistered<MainController>()
              ? Get.find<MainController>().currentIndex.value == 2
              : true;

          if (!isActiveTab) {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: AppColors.primary, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "loading_map".tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return IndexedStack(
            index: controller.isUsingGoogleMaps.value ? 0 : 1,
            children: [
              _buildGoogleMap(),
              _buildFlutterMap(),
            ],
          );
        }),

        // Floating action buttons for map layers
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                key: Get.find<UserGuideController>().mapProviderToggleKey,
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
                        key: Get.find<UserGuideController>().mapLayersKey,
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
                key: Get.find<UserGuideController>().pinNewPlaceKey,
                heroTag: 'add_place',
                onPressed: () {
                  Get.to(() => const CreatePlaceScreen());
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add_location_alt, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
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
                          if (entry.key == 'basic-v2') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'default_label'.tr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (isSelected) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'currently_using'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                          ],
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
