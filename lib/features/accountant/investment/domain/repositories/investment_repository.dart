import '../../data/model/investment_model.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentModel>> getInvestments({required String accountantId});
  Future<void> addInvestment({
    required String accountantId,
    required String name,
    required double amount,
    String? note,
  });
}