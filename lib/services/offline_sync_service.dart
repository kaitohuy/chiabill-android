import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../controllers/home_controller.dart';
import '../utils/toast_util.dart';

class OfflineSyncService extends GetxService {
  final _storage = GetStorage();
  final Connectivity _connectivity = Connectivity();
  
  var syncTrigger = 0.obs;
  bool _isSyncing = false;
  bool isOffline = false;
  List<ConnectivityResult>? _lastResult;

  @override
  void onInit() {
    super.onInit();
    // Trì hoãn việc kiểm tra kết nối mạng lúc khởi động 2 giây để nhường luồng vẽ mượt mà giao diện,
    // tránh nhảy frame do các cuộc gọi kênh nền (platform channel calls) đồng thời.
    Future.delayed(const Duration(seconds: 2), () {
      _initConnectivity();
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    });
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      return;
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Tránh xử lý trùng lặp khi stream phát lại trạng thái cũ ngay lúc khởi động
    if (_lastResult != null && listEquals(_lastResult, result)) {
      return;
    }
    _lastResult = result;

    bool wasOffline = isOffline;
    isOffline = result.isEmpty || result.contains(ConnectivityResult.none);
    
    debugPrint('[OfflineSync] wasOffline=$wasOffline, isOffline=$isOffline, result=$result');
    
    if (!isOffline) {
      // Khi phát hiện thiết bị đang có mạng (kể cả lúc vừa mở app hoặc khôi phục mạng)
      // Chờ 2 giây để mạng kết nối ổn định rồi tiến hành đồng bộ
      Future.delayed(const Duration(seconds: 2), () => syncOfflineQueue());
    }
  }

  // Thêm một request vào hàng đợi
  void addToQueue(String method, String path, dynamic data) {
    List queue = _storage.read('offline_queue') ?? [];
    
    // Tạo ID tạm cho item này để dễ nhận diện trên UI (vd: hiển thị icon đồng hồ)
    String offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    Map<String, dynamic> item = {
      'id': offlineId,
      'method': method,
      'path': path,
      'data': data is Map ? data : null, // Chỉ lưu data nếu là Map
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    queue.add(item);
    _storage.write('offline_queue', queue);
  }

  // Đọc hàng đợi
  List<dynamic> getQueue() {
    return _storage.read('offline_queue') ?? [];
  }

  // Xóa một item khỏi hàng đợi
  void removeFromQueue(String id) {
    List queue = getQueue();
    queue.removeWhere((item) => item['id'] == id);
    _storage.write('offline_queue', queue);
  }

  // Lấy các chi phí đang chờ đồng bộ của một chuyến đi cụ thể
  List<Map<String, dynamic>> getPendingExpensesForTrip(int tripId) {
    List queue = getQueue();
    List<Map<String, dynamic>> pending = [];
    
    for (var item in queue) {
      if (item['path'] == '/api/expenses' && item['method'] == 'POST') {
        var data = item['data'] as Map<String, dynamic>?;
        if (data != null && data['tripId'] == tripId) {
          pending.add(item as Map<String, dynamic>);
        }
      }
    }
    return pending;
  }

  // Lấy các chuyến đi đang chờ tạo
  List<Map<String, dynamic>> getPendingCreatedTrips() {
    List queue = getQueue();
    List<Map<String, dynamic>> pending = [];
    for (var item in queue) {
      if (item['path'] == '/api/trips' && item['method'] == 'POST') {
        pending.add(item as Map<String, dynamic>);
      }
    }
    return pending;
  }

  // Lấy danh sách ID các chuyến đi đã xóa ngoại tuyến
  List<int> getPendingDeletedTripIds() {
    List queue = getQueue();
    List<int> deletedIds = [];
    for (var item in queue) {
      if (item['path'].toString().startsWith('/api/trips/') && item['method'] == 'DELETE') {
        String idStr = item['path'].toString().split('/').last;
        int? id = int.tryParse(idStr);
        if (id != null) deletedIds.add(id);
      }
    }
    return deletedIds;
  }

  // Hàm đồng bộ dữ liệu lên Server
  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;
    
    List queue = getQueue();
    if (queue.isEmpty) {
      debugPrint('[OfflineSync] Queue rỗng, bỏ qua sync');
      return;
    }

    debugPrint('[OfflineSync] Bắt đầu sync ${queue.length} items...');
    _isSyncing = true;
    ToastUtil.showSuccess("Đang đồng bộ", "Đang tải dữ liệu lưu nháp lên máy chủ...");

    // Tạo Dio riêng không có Interceptor offline để tránh bị chặn lại
    Dio dio = Dio();
    final storage = GetStorage();
    dio.options.baseUrl = dotenv.env['BASE_URL'] ?? "http://192.168.4.29:8080";
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    String? token = storage.read('token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    int successCount = 0;
    int errorCount = 0;

    // Duyệt qua từng item và gửi lại
    for (var i = 0; i < queue.length; i++) {
      var item = queue[i];
      debugPrint('[OfflineSync] Gửi: ${item['method']} ${item['path']}');
      try {
        if (item['method'] == 'POST') {
          await dio.post(item['path'], data: item['data']);
        } else if (item['method'] == 'PUT') {
          await dio.put(item['path'], data: item['data']);
        } else if (item['method'] == 'DELETE') {
          await dio.delete(item['path'], data: item['data']);
        }
        
        // Gửi thành công -> Xóa khỏi queue
        debugPrint('[OfflineSync] Thành công: ${item['path']}');
        queue.removeAt(i);
        i--; // Lùi index vì vừa xóa
        successCount++;
      } catch (e) {
        debugPrint('[OfflineSync] Lỗi: $e');
        // Nếu lỗi do mạng, dừng đồng bộ. Nếu lỗi do API (ví dụ 400), có thể bỏ qua hoặc giữ lại
        if (e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout)) {
          break; // Mất mạng lại rồi, ngưng
        }
        // Lỗi API (400, 409, etc.) -> xóa luôn khỏi queue để không bị kẹt mãi
        queue.removeAt(i);
        i--;
        errorCount++;
      }
    }

    _storage.write('offline_queue', queue);
    _isSyncing = false;

    if (successCount > 0 || errorCount > 0) {
      String msg = 'Đã đẩy $successCount thao tác lên máy chủ.';
      if (errorCount > 0) msg += ' ($errorCount thất bại)';
      ToastUtil.showSuccess("Đồng bộ hoàn tất", msg);
      syncTrigger.value++;

      // Refresh HomeController nếu đang mở
      if (Get.isRegistered<HomeController>()) {
        // ignore: invalid_use_of_protected_member
        Get.find<HomeController>().fetchTrips(isRefresh: true);
      }
    }
  }
}
