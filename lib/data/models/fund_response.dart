import 'user_response.dart';

class FundResponse {
  final int id;
  final int tripId;
  final double balance;
  final String currency;
  final double? alertThreshold;
  final UserResponse treasurer;

  FundResponse({
    required this.id,
    required this.tripId,
    required this.balance,
    required this.currency,
    this.alertThreshold,
    required this.treasurer,
  });

  factory FundResponse.fromJson(Map<String, dynamic> json) {
    return FundResponse(
      id: json['id'] as int,
      tripId: json['tripId'] as int,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? "VND",
      alertThreshold: json['alertThreshold'] != null 
          ? (json['alertThreshold'] as num).toDouble() 
          : null,
      treasurer: UserResponse.fromJson(json['treasurer'] as Map<String, dynamic>),
    );
  }
}
