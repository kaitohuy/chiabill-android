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
  static const _kGoogleMapsNoticeShown = 'google_maps_notice_shown';

  // --- State ---
  final RxBool isMapView = true.obs;
  final RxList<PlaceModel> galleryPlaces = <PlaceModel>[].obs;
  final RxInt galleryPage = 0.obs;
  final RxBool galleryHasMore = true.obs;
  final RxBool isGalleryLoadingMore = false.obs;

  final RxList<PlaceModel> places        = <PlaceModel>[].obs;
  final RxList<PlaceModel> searchResults = <PlaceModel>[].obs;
  final RxBool isLoading   = false.obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString selectedCategory = 'Tất cả'.obs;

  final RxList<PlaceModel> filteredPlaces        = <PlaceModel>[].obs;
  final RxList<PlaceModel> filteredSearchResults = <PlaceModel>[].obs;

  void _updateFilteredPlaces() {
    if (selectedCategory.value == 'Tất cả') {
      filteredPlaces.value = places;
    } else {
      filteredPlaces.value = places.where((p) => p.category == selectedCategory.value).toList();
    }
  }

  void _updateFilteredSearchResults() {
    if (selectedCategory.value == 'Tất cả') {
      filteredSearchResults.value = searchResults;
    } else {
      filteredSearchResults.value = searchResults.where((p) => p.category == selectedCategory.value).toList();
    }
  }

  // Vietnam default coordinates
  final LatLng defaultCenter = const LatLng(16.047079, 108.206230);
  final Rx<LatLng> currentCenter = const LatLng(16.047079, 108.206230).obs;
  final RxDouble  currentZoom   = 6.0.obs;

  late final RxString currentMapStyle;

  /// Flag để Screen lắng nghe và tự quyết định hiện Dialog hay không.
  /// True = cần hiện thông báo MapTiler, False = không cần.
  final RxBool shouldShowMaptilerNotice = false.obs;
  final RxBool shouldShowGoogleMapsNotice = false.obs;

  /// True = đang dùng Google Maps, False = đang dùng MapTiler.
  final RxBool isUsingGoogleMaps = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Khôi phục style đã lưu
    final savedStyle = _storage.read<String>(_kMapStyle) ?? 'basic-v2';
    currentMapStyle = savedStyle.obs;

    // Tự động persist mỗi khi đổi style
    ever(currentMapStyle, (style) {
      _storage.write(_kMapStyle, style);
    });

    // Khi chuyển đổi nhà cung cấp bản đồ → ẩn thông báo cũ và kiểm tra hiện thông báo mới (nếu chưa từng xem)
    ever(isUsingGoogleMaps, (usingGoogle) {
      if (usingGoogle) {
        shouldShowMaptilerNotice.value = false;
        _checkAndSetGoogleMapsNotice();
      } else {
        shouldShowGoogleMapsNotice.value = false;
        _checkAndSetMaptilerNotice();
      }
    });

    // Tự động đồng bộ các danh sách đã lọc
    ever(places, (_) => _updateFilteredPlaces());
    ever(searchResults, (_) => _updateFilteredSearchResults());
    ever(selectedCategory, (_) {
      _updateFilteredPlaces();
      _updateFilteredSearchResults();
      fetchGalleryPlaces(isRefresh: true);
    });

    // Khởi tạo giá trị ban đầu
    _updateFilteredPlaces();
    _updateFilteredSearchResults();

    fetchPlacesNearby(defaultCenter.latitude, defaultCenter.longitude, 20000.0);
    fetchGalleryPlaces(isRefresh: true);
    _fetchMapConfig();
  }

  Future<void> fetchGalleryPlaces({bool isRefresh = true}) async {
    if (isRefresh) {
      galleryPage.value = 0;
      galleryHasMore.value = true;
      isLoading.value = true;
    } else {
      if (isGalleryLoadingMore.value || !galleryHasMore.value) return;
      isGalleryLoadingMore.value = true;
    }

    final response = await _placeRepository.getPlaces(
      category: selectedCategory.value,
      page: galleryPage.value,
      size: 10,
    );

    if (response.success && response.data != null) {
      final newPlaces = response.data!;
      if (isRefresh) {
        galleryPlaces.value = newPlaces;
      } else {
        galleryPlaces.addAll(newPlaces);
      }
      
      if (newPlaces.length < 10) {
        galleryHasMore.value = false;
      } else {
        galleryPage.value++;
      }
    } else {
      ToastUtil.showError("Lỗi", "Không thể tải danh sách địa điểm");
    }

    if (isRefresh) {
      isLoading.value = false;
    } else {
      isGalleryLoadingMore.value = false;
    }
  }

  /// Lấy cấu hình bản đồ từ Server để biết nên dùng Google Maps hay MapTiler
  Future<void> _fetchMapConfig() async {
    try {
      isUsingGoogleMaps.value = false;
    } catch (e) {
      isUsingGoogleMaps.value = false;
    }

    if (!isUsingGoogleMaps.value) {
      _checkAndSetMaptilerNotice();
    } else {
      _checkAndSetGoogleMapsNotice();
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

  void _checkAndSetGoogleMapsNotice() {
    final alreadyShown = _storage.read<bool>(_kGoogleMapsNoticeShown) ?? false;
    if (!alreadyShown) {
      shouldShowGoogleMapsNotice.value = true;
    }
  }

  /// Gọi bởi Screen sau khi đã hiển thị dialog thành công.
  void markGoogleMapsNoticeSeen() {
    _storage.write(_kGoogleMapsNoticeShown, true);
    shouldShowGoogleMapsNotice.value = false;
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
