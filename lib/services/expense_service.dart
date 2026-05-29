import '../data/models/api_response.dart';
import '../data/models/category_stat_response.dart';
import '../data/models/expense_category_respone.dart';
import '../data/models/expense_response.dart';
import '../data/models/page_response.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseService {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  Future<ApiResponse<PageResponse<ExpenseResponse>>> searchExpenses({
    required int tripId,
    int page = 0,
    int size = 10,
    String? keyword,
    int? categoryId,
    int? payerId,
    String? startDate,
    String? endDate,
  }) {
    return _expenseRepo.searchExpenses(
      tripId: tripId,
      page: page,
      size: size,
      keyword: keyword,
      categoryId: categoryId,
      payerId: payerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ApiResponse<void>> deleteExpense(int expenseId) {
    return _expenseRepo.deleteExpense(expenseId);
  }

  Future<ApiResponse<List<CategoryStatResponse>>> getTripStats(int tripId) {
    return _expenseRepo.getTripStats(tripId);
  }

  Future<ApiResponse<List<ExpenseCategoryResponse>>> getCategories(int tripId) {
    return _categoryRepo.getCategories(tripId);
  }
}
