import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:dio/dio.dart';
import 'dart:async';
import '../../controllers/tourism_controller.dart';
import 'setup_place_detail_screen.dart';

class CreatePlaceScreen extends StatefulWidget {
  const CreatePlaceScreen({super.key});

  @override
  State<CreatePlaceScreen> createState() => _CreatePlaceScreenState();
}

class _CreatePlaceScreenState extends State<CreatePlaceScreen> {
  final TourismController _tourismController = Get.find<TourismController>();
  final MapController _mapController = MapController();
  gmap.GoogleMapController? _googleMapController;

  LatLng _selectedLocation = const LatLng(16.047079, 108.206230); // Default Da Nang
  String _selectedCity = 'Đà Nẵng';
  bool _isReverseGeocoding = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  // Định nghĩa các Danh mục tiếng Việt cao cấp có icon & màu sắc riêng
  String _selectedCategoryKey = 'Biển';
  final Map<String, Map<String, dynamic>> _categories = {
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

  // Search autocomplete state
  final Dio _dio = Dio();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  // Thực hiện tìm kiếm qua Nominatim API
  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() {
        _isSearching = true;
      });
      try {
        final response = await _dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': query,
            'format': 'json',
            'limit': 5,
            'accept-language': 'vi',
            'addressdetails': 1,
          },
          options: Options(
            headers: {
              'User-Agent': 'com.kaitohuy.chiabill',
            },
          ),
        );
        if (response.data != null && response.data is List) {
          setState(() {
            _searchResults = response.data;
          });
        }
      } catch (e) {
        debugPrint("Error searching Nominatim: $e");
      } finally {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  // Lấy thành phố tự động từ tọa độ (Reverse Geocoding)
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'accept-language': 'vi',
        },
        options: Options(
          headers: {
            'User-Agent': 'com.kaitohuy.chiabill',
          },
        ),
      );
      if (response.data != null && response.data['address'] != null) {
        final address = response.data['address'] as Map<String, dynamic>;
        final city = address['city'] ?? address['state'] ?? address['province'] ?? address['municipality'] ?? address['county'] ?? 'Đà Nẵng';
        return city.toString().replaceAll(RegExp(r'^(Thành phố|Tỉnh)\s+'), '').trim();
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return 'Đà Nẵng';
  }

  // Xử lý khi user chọn một kết quả tìm kiếm gợi ý
  void _selectSearchResult(Map<String, dynamic> result) {
    final double lat = double.parse(result['lat'].toString());
    final double lon = double.parse(result['lon'].toString());
    final LatLng location = LatLng(lat, lon);

    final address = result['address'] as Map<String, dynamic>? ?? {};
    final city = address['city'] ?? address['state'] ?? address['province'] ?? address['municipality'] ?? address['county'] ?? 'Đà Nẵng';
    final String cleanCity = city.toString().replaceAll(RegExp(r'^(Thành phố|Tỉnh)\s+'), '').trim();
    final String fullDisplayName = result['display_name'].toString();
    final String shortName = fullDisplayName.split(',').first.trim();

    setState(() {
      _selectedLocation = location;
      _selectedCity = cleanCity;
      _nameController.text = shortName;
      _searchResults.clear();
      _searchController.clear();
    });

    FocusScope.of(context).unfocus();

    // Di chuyển map camera đến tọa độ mới
    if (_tourismController.isUsingGoogleMaps.value) {
      _googleMapController?.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(gmap.LatLng(lat, lon), 15.0),
      );
    } else {
      _mapController.move(location, 15.0);
    }
  }

  // Mở BottomSheet thiết kế đẹp mắt để chọn danh mục, tránh tràn màn hình khi có nhiều mục
  void _showCategorySelectorBottomSheet() async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Get.bottomSheet(
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
            const Text(
              "Chọn Danh Mục Địa Điểm",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final key = _categories.keys.elementAt(index);
                  final item = _categories[key]!;
                  final isSelected = key == _selectedCategoryKey;

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
                        setState(() {
                          _selectedCategoryKey = key;
                        });
                        Get.back();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Widget _buildMap() {
    return Obx(() {
      if (_tourismController.isUsingGoogleMaps.value) {
        return gmap.GoogleMap(
          initialCameraPosition: gmap.CameraPosition(
            target: gmap.LatLng(_selectedLocation.latitude, _selectedLocation.longitude),
            zoom: 15.0,
          ),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
          onCameraMove: (position) {
            _selectedLocation = LatLng(position.target.latitude, position.target.longitude);
          },
        );
      } else {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedLocation,
            initialZoom: 15.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                _selectedLocation = position.center;
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kaitohuy.chiabill',
            ),
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedCategoryKey]!;
  
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
        title: const Text("Thêm địa điểm mới", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Bản đồ chiếm toàn bộ không gian phía trên (Expanded), thoáng rộng tối đa
          Expanded(
            child: Stack(
              children: [
                // Bản đồ chính
                Positioned.fill(child: _buildMap()),

                // Tâm ghim bản đồ cố định chính giữa
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_on, color: Colors.red, size: 50),
                  ),
                ),

                // Thanh tìm kiếm địa danh Nominatim
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm địa điểm (VD: Hồ Hoàn Kiếm)...",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 8),
                              child: Icon(Icons.search, color: Colors.grey),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 24,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged("");
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),

                      // Dropdown gợi ý kết quả
                      if (_isSearching)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
                        )
                      else if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              final String displayName = item['display_name'].toString();
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place, color: Colors.orange, size: 20),
                                title: Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                onTap: () => _selectSearchResult(item),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Nhãn chỉ dẫn
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Kéo bản đồ để ghim đúng vị trí tâm",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Biểu mẫu nhập liệu rút gọn (Tên + Danh mục) sát đáy với margin cực nhỏ 24px
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20 + MediaQuery.of(context).padding.bottom),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Tên địa điểm (*)",
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập tên địa điểm" : null,
                  ),
                  const SizedBox(height: 12),

                  // GestureDetector giả lập Dropdown để mở BottomSheet chọn danh mục, tránh tràn màn hình
                  GestureDetector(
                    onTap: _showCategorySelectorBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(selectedCategory['icon'], color: selectedCategory['color']),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Danh mục địa điểm (*)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(selectedCategory['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút ghim địa điểm
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isReverseGeocoding ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isReverseGeocoding = true;
                          });

                          // 1. Tự động Reverse Geocoding để lấy thành phố thật
                          final city = await _reverseGeocode(_selectedLocation.latitude, _selectedLocation.longitude);
                          
                          setState(() {
                            _selectedCity = city;
                            _isReverseGeocoding = false;
                          });

                          // 2. Gọi API ghim địa điểm ở Database
                          final newPlace = await _tourismController.createPlace(
                            name: _nameController.text.trim(),
                            category: _selectedCategoryKey,
                            latitude: _selectedLocation.latitude,
                            longitude: _selectedLocation.longitude,
                            city: _selectedCity,
                          );
                          
                          if (newPlace != null) {
                            // Chuyển sang màn hình setup thông tin chi tiết
                            Get.off(() => SetupPlaceDetailScreen(place: newPlace));
                          }
                        }
                      },
                      child: _isReverseGeocoding
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  "GHIM ĐỊA ĐIỂM NÀY",
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
