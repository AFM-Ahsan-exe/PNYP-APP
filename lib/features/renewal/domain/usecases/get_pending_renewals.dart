import '../../domain/entities/renewal_request.dart';
import '../../domain/repositories/renewal_repository.dart';

class GetPendingRenewals {
  final RenewalRepository repository;

  GetPendingRenewals(this.repository);

  Future<List<RenewalRequest>> call() => repository.getPendingRenewals();
}
