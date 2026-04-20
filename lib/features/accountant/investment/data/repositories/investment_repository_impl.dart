import '../../domain/repositories/investment_repository.dart';
import '../datasources/investment_remote_datasource.dart';
import '../model/investment_model.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  final InvestmentRemoteDatasource datasource;
  const InvestmentRepositoryImpl(this.datasource);

  @override
  Future<List<InvestmentModel>> getInvestments({
    required String accountantId,
  }) => datasource.getInvestments(accountantId: accountantId);

  @override
  Future<void> addInvestment({
    required String accountantId,
    required String name,
    required double amount,
    String? note,
  }) => datasource.addInvestment(
    accountantId: accountantId,
    name:         name,
    amount:       amount,
    note:         note,
  );
}