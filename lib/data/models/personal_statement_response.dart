import 'expense_response.dart';
import 'payment_response.dart';

class PersonalStatementResponse {
  final int userId;
  final String userName;
  final double totalPaid;
  final double totalSpent;
  final double netBalance;
  final List<ExpenseResponse> involvedExpenses;
  final List<PaymentResponse> involvedPayments;

  PersonalStatementResponse({
    required this.userId,
    required this.userName,
    required this.totalPaid,
    required this.totalSpent,
    required this.netBalance,
    required this.involvedExpenses,
    required this.involvedPayments,
  });

  factory PersonalStatementResponse.fromJson(Map<String, dynamic> json) {
    return PersonalStatementResponse(
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      totalPaid: (json['totalPaid'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      involvedExpenses: json['involvedExpenses'] != null
          ? (json['involvedExpenses'] as List).map((i) => ExpenseResponse.fromJson(i)).toList()
          : [],
      involvedPayments: json['involvedPayments'] != null
          ? (json['involvedPayments'] as List).map((i) => PaymentResponse.fromJson(i)).toList()
          : [],
    );
  }
}
