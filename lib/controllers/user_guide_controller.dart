import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserGuideController extends GetxController {
  final _storage = GetStorage();

  // Settings Keys
  static const String keyFirstRun = 'guide_first_run_v1';
  static const String keyHomeEnabled = 'guide_home_enabled_v1';
  static const String keyTripDetailEnabled = 'guide_trip_detail_enabled_v1';
  static const String keyTourismEnabled = 'guide_tourism_enabled_v1';

  // State observables
  final isFirstRun = true.obs;
  final guideHomeEnabled = true.obs;
  final guideTripDetailEnabled = true.obs;
  final guideTourismEnabled = true.obs;

  // Global Keys for Targeting Widgets in Guides
  // Main & HomeScreen
  final fabTripKey = GlobalKey();
  final joinTripKey = GlobalKey();
  final calculatorKey = GlobalKey();
  final bellKey = GlobalKey();

  // TripDetailScreen
  final shareTripKey = GlobalKey();
  final itineraryBtnKey = GlobalKey();
  final historyBtnKey = GlobalKey();
  final addExpenseKey = GlobalKey();
  final bottomTabExpenseKey = GlobalKey();
  final bottomTabFundKey = GlobalKey();
  final bottomTabSettlementKey = GlobalKey();
  final bottomTabMembersKey = GlobalKey();

  // TourismMapScreen
  final searchPlaceKey = GlobalKey();
  final filterCategoryKey = GlobalKey();
  final toggleMapKey = GlobalKey();
  final mapProviderToggleKey = GlobalKey();
  final mapLayersKey = GlobalKey();
  final pinNewPlaceKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    // Load persisted state or default to true
    isFirstRun.value = _storage.read(keyFirstRun) ?? true;
    guideHomeEnabled.value = _storage.read(keyHomeEnabled) ?? true;
    guideTripDetailEnabled.value = _storage.read(keyTripDetailEnabled) ?? true;
    guideTourismEnabled.value = _storage.read(keyTourismEnabled) ?? true;
  }

  void disableFirstRun() {
    isFirstRun.value = false;
    _storage.write(keyFirstRun, false);
  }

  void setGuideEnabled(String screen, bool value) {
    if (screen == 'home') {
      guideHomeEnabled.value = value;
      _storage.write(keyHomeEnabled, value);
    } else if (screen == 'trip_detail') {
      guideTripDetailEnabled.value = value;
      _storage.write(keyTripDetailEnabled, value);
    } else if (screen == 'tourism') {
      guideTourismEnabled.value = value;
      _storage.write(keyTourismEnabled, value);
    }
  }

  void resetAllGuides() {
    setGuideEnabled('home', true);
    setGuideEnabled('trip_detail', true);
    setGuideEnabled('tourism', true);
    isFirstRun.value = false;
    _storage.write(keyFirstRun, false);
  }
}
