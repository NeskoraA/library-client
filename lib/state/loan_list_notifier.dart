import '../models/loan.dart';
import '../repositories/entity_repositories.dart';
import 'entity_list_notifier.dart';

class LoanListNotifier extends EntityListNotifier<Loan> {
  final LoanRepository _loans;

  LoanListNotifier(this._loans, {super.onDataChanged, super.onRecovered})
    : super(_loans);

  Future<void> returnLoan(int id) => runAction(() => _loans.returnLoan(id));
}
