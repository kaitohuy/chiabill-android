import 'package:get/get.dart';
import '../data/models/payment_response.dart';
import '../data/models/trip_history_response.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/trip_repository.dart';

class TripHistoryController extends GetxController {
  final int tripId;
  TripHistoryController(this.tripId);

  final TripRepository _tripRepo = TripRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  // History (Audit Logs)
  var tripHistories = <TripHistoryResponse>[].obs;
  var isHistoryLoading = false.obs;
  var currentHistoryPage = 0.obs;
  var isHistoryLastPage = false.obs;
  var isLoadingMoreHistories = false.obs;
  var filterHistoryActions = <String>[].obs;
  var filterHistoryStartDate = RxnString();
  var filterHistoryEndDate = RxnString();

  // Payments (Lịch sử giao dịch)
  var payments = <PaymentResponse>[].obs;
  var currentPaymentPage = 0.obs;
  var isPaymentLastPage = false.obs;
  var isLoadingMorePayments = false.obs;
  var filterPaymentStatus = RxnString();
  var filterPaymentFromUserId = RxnInt();
  var filterPaymentToUserId = RxnInt();
  var filterPaymentStartDate = RxnString();
  var filterPaymentEndDate = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchTripHistory(isRefresh: true);
    fetchPayments(isRefresh: true);
  }

  void fetchData() {
    fetchTripHistory(isRefresh: true);
    fetchPayments(isRefresh: true);
  }

  Future<void> fetchTripHistory({bool isRefresh = true, bool isSilent = false}) async {
    if (isRefresh) {
      currentHistoryPage.value = 0;
      isHistoryLastPage.value = false;
      isLoadingMoreHistories.value = false;
      if (!isSilent && tripHistories.isNotEmpty) tripHistories.clear();
      if (!isSilent) isHistoryLoading.value = true;
    } else {
      if (isHistoryLastPage.value || isLoadingMoreHistories.value) return;
      isLoadingMoreHistories.value = true;
    }

    final result = await _tripRepo.getTripHistory(
      tripId: tripId,
      page: currentHistoryPage.value,
      size: 15,
      actions: filterHistoryActions.isNotEmpty ? filterHistoryActions : null,
      startDate: filterHistoryStartDate.value,
      endDate: filterHistoryEndDate.value,
    );

    if (result.success && result.data != null) {
      if (isRefresh) {
        tripHistories.value = result.data!.content;
      } else {
        tripHistories.addAll(result.data!.content);
      }
      currentHistoryPage.value++;
      isHistoryLastPage.value = result.data!.last;
    }

    if (!isSilent && isRefresh) isHistoryLoading.value = false;
    if (!isRefresh) isLoadingMoreHistories.value = false;
  }

  void applyHistoryFilter({List<String>? actions, String? startDate, String? endDate}) {
    if (actions != null) {
      filterHistoryActions.value = actions;
    } else {
      filterHistoryActions.clear();
    }
    filterHistoryStartDate.value = startDate;
    filterHistoryEndDate.value = endDate;
    fetchTripHistory(isRefresh: true);
  }

  Future<void> fetchPayments({bool isRefresh = true, bool isSilent = false}) async {
    if (isRefresh) {
      currentPaymentPage.value = 0;
      isPaymentLastPage.value = false;
      isLoadingMorePayments.value = false;
      if (!isSilent && payments.isNotEmpty) payments.clear(); 
    } else {
      if (isPaymentLastPage.value || isLoadingMorePayments.value) return;
      isLoadingMorePayments.value = true;
    }

    final result = await _paymentRepo.getTripPaymentsPaginated(
      tripId: tripId,
      page: currentPaymentPage.value,
      size: 15,
      status: filterPaymentStatus.value,
      fromUserId: filterPaymentFromUserId.value,
      toUserId: filterPaymentToUserId.value,
      startDate: filterPaymentStartDate.value,
      endDate: filterPaymentEndDate.value,
    );

    if (result.success && result.data != null) {
      if (isRefresh) {
        payments.value = result.data!.content;
      } else {
        payments.addAll(result.data!.content);
      }
      currentPaymentPage.value++;
      isPaymentLastPage.value = result.data!.last;
    }

    if (!isRefresh) isLoadingMorePayments.value = false;
  }

  void applyPaymentFilter({String? status, int? fromId, int? toId, String? startDate, String? endDate}) {
    filterPaymentStatus.value = status;
    filterPaymentFromUserId.value = fromId;
    filterPaymentToUserId.value = toId;
    filterPaymentStartDate.value = startDate;
    filterPaymentEndDate.value = endDate;
    fetchPayments(isRefresh: true);
  }
}
