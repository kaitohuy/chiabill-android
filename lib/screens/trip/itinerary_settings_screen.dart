import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/data/repositories/itinerary_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chiabill/services/alarm_service.dart';
import 'package:get_storage/get_storage.dart';

class ItinerarySettingsScreen extends StatefulWidget {
  final int tripId;
  const ItinerarySettingsScreen({super.key, required this.tripId});

  @override
  State<ItinerarySettingsScreen> createState() => _ItinerarySettingsScreenState();
}

class _ItinerarySettingsScreenState extends State<ItinerarySettingsScreen> {
  final _storage = GetStorage();
  final _itineraryRepo = ItineraryRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isNotificationEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;
  bool _isLoading = true;

  final TextEditingController _timeController = TextEditingController();
  String _selectedUnit = 'Phút';
  bool _hasSaved = false;

  final List<String> _units = ['Giây', 'Phút', 'Giờ', 'Ngày'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _timeController.addListener(_onTimeChanged);
  }

  void _onTimeChanged() {
    if (_hasSaved) {
      setState(() {
        _hasSaved = false;
      });
    }
  }

  @override
  void dispose() {
    _timeController.removeListener(_onTimeChanged);
    _saveSettings(isAuto: true);
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final tripId = widget.tripId;
    
    // Load local sound/vibrate settings
    setState(() {
      _isVibrationEnabled = _storage.read('itinerary_alarm_vibrate_$tripId') ?? true;
      _isSoundEnabled = _storage.read('itinerary_alarm_sound_$tripId') ?? true;
    });

    try {
      final res = await _itineraryRepo.getItinerarySettings(tripId);
      if (res.success && res.data != null) {
        setState(() {
          _isNotificationEnabled = res.data!['alarmEnabled'] ?? true;
          _timeController.text = (res.data!['alarmValue'] ?? 15).toString();
          _selectedUnit = res.data!['alarmUnit'] ?? 'Phút';
          if (!_units.contains(_selectedUnit)) {
            _selectedUnit = 'Phút';
          }
        });
      }
    } catch (e) {
      debugPrint('[ItinerarySettingsScreen] Failed to load settings from server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings({bool isAuto = false}) async {
    if (_hasSaved) return;

    final tripId = widget.tripId;
    int alarmValue = int.tryParse(_timeController.text.trim()) ?? 15;
    if (alarmValue <= 0) {
      alarmValue = 15;
    }

    // Save local vibration and sound settings to GetStorage
    _storage.write('itinerary_alarm_vibrate_$tripId', _isVibrationEnabled);
    _storage.write('itinerary_alarm_sound_$tripId', _isSoundEnabled);

    if (!isAuto) {
      FocusManager.instance.primaryFocus?.unfocus(); // Đóng bàn phím
      LoadingUtil.show();
    }
    
    try {
      final res = await _itineraryRepo.updateItinerarySettings(
        tripId,
        _isNotificationEnabled,
        alarmValue,
        _selectedUnit,
      );
      
      _hasSaved = true;
      
      if (!isAuto) {
        LoadingUtil.hide();
        if (res.success) {
          ToastUtil.showSuccess("Thành công", "Đã lưu cài đặt báo thức!");
        } else {
          ToastUtil.showError("Lỗi", res.message ?? "Không thể lưu cài đặt báo thức");
        }
      }
    } catch (e) {
      debugPrint('[ItinerarySettingsScreen] Failed to save settings: $e');
      if (!isAuto) {
        LoadingUtil.hide();
        ToastUtil.showError("Lỗi hệ thống", e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Cài Đặt Báo Thức",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card 1: Loại thông báo
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Hình Thức Nhắc Nhở",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Nhắc nhở lịch trình",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                subtitle: const Text(
                                  "Nhận thông báo khi sắp đến giờ hoạt động",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                value: _isNotificationEnabled,
                                onChanged: (val) async {
                                  if (val) {
                                    await AlarmService.requestPermissions();
                                  }
                                  setState(() {
                                    _isNotificationEnabled = val;
                                    _hasSaved = false;
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Rung thiết bị",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                value: _isVibrationEnabled,
                                onChanged: _isNotificationEnabled
                                    ? (val) {
                                        setState(() {
                                          _isVibrationEnabled = val;
                                          _hasSaved = false;
                                        });
                                      }
                                    : null,
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Phát âm thanh chuông",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                value: _isSoundEnabled,
                                onChanged: _isNotificationEnabled
                                    ? (val) {
                                        setState(() {
                                          _isSoundEnabled = val;
                                          _hasSaved = false;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Thời gian báo trước
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.alarm_on_outlined, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Thời Gian Báo Trước",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),
                              const Text(
                                "Nhắc nhở trước khi lịch trình diễn ra:",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Text Field để nhập số
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _timeController,
                                      keyboardType: TextInputType.number,
                                      enabled: _isNotificationEnabled,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        filled: true,
                                        fillColor: _isNotificationEnabled ? Colors.grey.shade50 : Colors.grey.shade200,
                                        hintText: 'Nhập số',
                                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (!_isNotificationEnabled) return null;
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Bắt buộc';
                                        }
                                        final n = int.tryParse(value);
                                        if (n == null || n <= 0) {
                                          return 'Số hợp lệ';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Dropdown chọn đơn vị
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedUnit,
                                      items: _units.map((unit) {
                                        return DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit, style: const TextStyle(fontSize: 14)),
                                        );
                                      }).toList(),
                                      onChanged: _isNotificationEnabled
                                          ? (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedUnit = val;
                                                  _hasSaved = false;
                                                });
                                              }
                                            }
                                          : null,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        filled: true,
                                        fillColor: _isNotificationEnabled ? Colors.grey.shade50 : Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Button lưu ở cuối
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _saveSettings();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "LƯU CẤU HÌNH",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
