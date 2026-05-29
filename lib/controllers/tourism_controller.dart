import 'dart:io';
import 'package:chiabill/data/models/place_model.dart';
import 'package:chiabill/data/repositories/place_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import '../utils/toast_util.dart';

/// Controller thuần tuý: chỉ quản lý state + logic nghiệp vụ.
/// Mọi UI (Dialog, BottomSheet, v.v.) phải nằm ở tầng Screen.
class TourismController extends GetxController {
  final PlaceRepository _placeRepository = PlaceRepository();
  final fmap.MapController mapController = fmap.MapController();
  gmap.GoogleMapController? googleMapController;
  final _storage = GetStorage();

  // --- Storage keys ---
  static const _kMapStyle            = 'map_style';
  static const _kMaptilerNoticeShown = 'maptiler_notice_shown';

  // --- State ---
  final RxList<PlaceModel> places        = <PlaceModel>[].obs;
  final RxList<PlaceModel> searchResults = <PlaceModel>[].obs;
  final RxBool isLoading   = false.obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString selectedCategory = 'Tất cả'.obs;

  List<PlaceModel> get filteredPlaces {
    if (selectedCategory.value == 'Tất cả') {
      return places;
    }
    return places.where((p) => p.category == selectedCategory.value).toList();
  }

  List<PlaceModel> get filteredSearchResults {
    if (selectedCategory.value == 'Tất cả') {
      return searchResults;
    }
    return searchResults.where((p) => p.category == selectedCategory.value).toList();
  }

  // Vietnam default coordinates
  final LatLng defaultCenter = const LatLng(16.047079, 108.206230);
  final Rx<LatLng> currentCenter = const LatLng(16.047079, 108.206230).obs;
  final RxDouble  currentZoom   = 6.0.obs;

  late final RxString currentMapStyle;

  /// Flag để Screen lắng nghe và tự quyết định hiện Dialog hay không.
  /// True = cần hiện thông báo MapTiler, False = không cần.
  final RxBool shouldShowMaptilerNotice = false.obs;

  /// True = đang dùng Google Maps, False = đang dùng MapTiler.
  final RxBool isUsingGoogleMaps = true.obs;

  @override
  void onInit() {
    super.onInit();

    // Khôi phục style đã lưu
    final savedStyle = _storage.read<String>(_kMapStyle) ?? 'streets-v2';
    currentMapStyle = savedStyle.obs;

    // Tự động persist mỗi khi đổi style
    ever(currentMapStyle, (style) {
      _storage.write(_kMapStyle, style);
    });

    // Khi chuyển về Google Maps → reset flag để lần sau đổi về MapTiler sẽ hiện notice lại
    ever(isUsingGoogleMaps, (usingGoogle) {
      if (usingGoogle) {
        _storage.write(_kMaptilerNoticeShown, false);
        shouldShowMaptilerNotice.value = false;
      } else {
        // Vừa chuyển sang MapTiler: kiểm tra có cần hiện thông báo không
        _checkAndSetMaptilerNotice();
      }
    });

    fetchPlacesNearby(defaultCenter.latitude, defaultCenter.longitude, 20000.0);
    _fetchMapConfig();
  }

  /// Lấy cấu hình bản đồ từ Server để biết nên dùng Google Maps hay MapTiler
  Future<void> _fetchMapConfig() async {
    try {
      isUsingGoogleMaps.value = true;
    } catch (e) {
      isUsingGoogleMaps.value = true;
    }

    if (!isUsingGoogleMaps.value) {
      _checkAndSetMaptilerNotice();
    }
  }

  void _checkAndSetMaptilerNotice() {
    final alreadyShown = _storage.read<bool>(_kMaptilerNoticeShown) ?? false;
    if (!alreadyShown) {
      shouldShowMaptilerNotice.value = true;
    }
  }

  /// Gọi bởi Screen sau khi đã hiển thị dialog thành công.
  void markMaptilerNoticeSeen() {
    _storage.write(_kMaptilerNoticeShown, true);
    shouldShowMaptilerNotice.value = false;
  }

  Future<void> fetchPlacesNearby(double lat, double lng, double radius) async {
    isLoading.value = true;
    final response = await _placeRepository.getPlacesNearby(lat, lng, radius: radius, limit: 1000);
    if (response.success && response.data != null) {
      places.value = response.data!
          .where((p) => !p.latitude.isNaN &&
                        !p.longitude.isNaN &&
                        p.latitude >= -90.0 && p.latitude <= 90.0 &&
                        p.longitude >= -180.0 && p.longitude <= 180.0)
          .toList();
    } else {
      ToastUtil.showError("Lỗi", "Không thể tải danh sách địa điểm");
    }
    isLoading.value = false;
  }

  Future<void> searchPlaces(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    isLoading.value = true;
    final response = await _placeRepository.searchPlaces(keyword);
    if (response.success && response.data != null) {
      searchResults.value = response.data!
          .where((p) => !p.latitude.isNaN &&
                        !p.longitude.isNaN &&
                        p.latitude >= -90.0 && p.latitude <= 90.0 &&
                        p.longitude >= -180.0 && p.longitude <= 180.0)
          .toList();
    } else {
      searchResults.clear();
    }
    isLoading.value = false;
  }

  void moveToPlace(PlaceModel place) {
    currentCenter.value = LatLng(place.latitude, place.longitude);
    currentZoom.value   = 15.0;
    
    if (isUsingGoogleMaps.value) {
      googleMapController?.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(
          gmap.LatLng(place.latitude, place.longitude), 
          15.0
        )
      );
    } else {
      mapController.move(currentCenter.value, currentZoom.value);
    }

    searchController.clear();
    searchResults.clear();
    isSearching.value = false;
  }

  Future<PlaceModel?> createPlace({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    isLoading.value = true;
    final response = await _placeRepository.createPlace({
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
    });
    isLoading.value = false;
    if (response.success && response.data != null) {
      fetchPlacesNearby(defaultCenter.latitude, defaultCenter.longitude, 20000.0);
      return response.data;
    } else {
      ToastUtil.showError("Lỗi", response.message ?? "Không thể ghim địa điểm");
      return null;
    }
  }

  Future<bool> updatePlaceDetails({
    required int id,
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    required String city,
    required String summary,
    required String ticketPrices,
    required String openingHours,
  }) async {
    isLoading.value = true;
    final response = await _placeRepository.updatePlace(id, {
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'summary': summary,
      'ticketPrices': ticketPrices,
      'openingHours': openingHours,
    });
    isLoading.value = false;
    if (response.success && response.data != null) {
      fetchPlacesNearby(defaultCenter.latitude, defaultCenter.longitude, 20000.0);
      return true;
    } else {
      ToastUtil.showError("Lỗi", response.message ?? "Không thể lưu thông tin chi tiết");
      return false;
    }
  }

  Future<String?> uploadPlaceImage(int placeId, String album, File file) async {
    isLoading.value = true;
    final response = await _placeRepository.uploadPlaceImage(placeId, album, file);
    isLoading.value = false;
    if (response.success && response.data != null) {
      return response.data;
    } else {
      ToastUtil.showError("Lỗi", response.message ?? "Không thể tải ảnh lên");
      return null;
    }
  }

  Future<bool> reportPlace(int id, String reportType, String description) async {
    isLoading.value = true;
    final response = await _placeRepository.reportPlace(id, reportType, description);
    isLoading.value = false;
    if (response.success) {
      return true;
    } else {
      ToastUtil.showError("Lỗi", response.message ?? "Không thể gửi báo cáo");
      return false;
    }
  }
}
