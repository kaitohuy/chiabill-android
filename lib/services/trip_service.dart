import '../data/models/api_response.dart';
import '../data/models/invitation_response.dart';
import '../data/models/trip_response.dart';
import '../data/repositories/invitation_repository.dart';
import '../data/repositories/trip_repository.dart';

class TripService {
  final TripRepository _tripRepo = TripRepository();
  final InvitationRepository _invitationRepo = InvitationRepository();

  Future<ApiResponse<TripResponse>> getTripDetail(int tripId) {
    return _tripRepo.getTripDetail(tripId);
  }

  Future<ApiResponse<void>> deleteTrip(int tripId) {
    return _tripRepo.deleteTrip(tripId);
  }

  /// Phân tích cú pháp input để xác định là email hay số điện thoại rồi gửi request
  Future<ApiResponse<void>> addDirectMember(int tripId, String input) {
    if (input.trim().isEmpty) {
      return Future.value(ApiResponse.withError(Exception("Input rỗng"), defaultMessage: "Vui lòng nhập email hoặc SĐT"));
    }

    String email = "";
    String phone = "";
    if (input.contains("@")) {
      email = input.trim();
    } else {
      phone = input.trim();
    }

    return _tripRepo.addDirectMember(tripId, email, phone);
  }

  Future<ApiResponse<InvitationResponse?>> getActiveInvite(int tripId) {
    return _invitationRepo.getActiveInvite(tripId);
  }

  Future<ApiResponse<InvitationResponse>> generateInviteCode(int tripId, String customCode) {
    return _invitationRepo.createInvite(
      tripId,
      customCode: customCode.isNotEmpty ? customCode : null
    );
  }

  Future<ApiResponse<void>> leaveTrip(int tripId) {
    return _tripRepo.leaveTrip(tripId);
  }

  Future<ApiResponse<void>> kickMember(int tripId, int memberId, bool forgiveDebt) {
    return _tripRepo.kickMember(tripId, memberId, forgiveDebt);
  }

  Future<ApiResponse<void>> transferOwner(int tripId, int newOwnerId) {
    return _tripRepo.transferOwner(tripId, newOwnerId);
  }

  Future<ApiResponse<void>> disableMember(int tripId, int memberId) {
    return _tripRepo.disableMember(tripId, memberId);
  }

  Future<ApiResponse<void>> activateMember(int tripId, int memberId) {
    return _tripRepo.activateMember(tripId, memberId);
  }

  Future<ApiResponse<dynamic>> exportTripBytes(
    int tripId,
    String format, {
    bool includeDetails = false,
    bool includeSettlement = false,
  }) {
    return _tripRepo.exportTripBytes(
      tripId,
      format,
      includeDetails: includeDetails,
      includeSettlement: includeSettlement,
    );
  }
}
