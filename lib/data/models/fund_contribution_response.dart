import 'user_response.dart';

class FundContributionResponse {
  final int id;
  final int fundId;
  final UserResponse contributor;
  final double amount;
  final DateTime contributionDate;
  final String? notes;
  final String type; // REQUIRED, VOLUNTARY
  final bool isConfirmed;

  FundContributionResponse({
    required this.id,
    required this.fundId,
    required this.contributor,
    required this.amount,
    required this.contributionDate,
    this.notes,
    required this.type,
    required this.isConfirmed,
  });

  factory FundContributionResponse.fromJson(Map<String, dynamic> json) {
    return FundContributionResponse(
      id: json['id'] as int,
      fundId: json['fundId'] as int,
      contributor: UserResponse.fromJson(json['contributor'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      contributionDate: DateTime.parse(json['contributionDate'] as String),
      notes: json['notes'] as String?,
      type: json['type'] as String? ?? "REQUIRED",
      isConfirmed: json['isConfirmed'] as bool? ?? false,
    );
  }
}
