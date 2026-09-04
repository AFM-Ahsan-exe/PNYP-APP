import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';

class GetAllOpportunitiesForAdmin {
  final OpportunityRepository repository;

  GetAllOpportunitiesForAdmin(this.repository);

  Future<List<Opportunity>> call() {
    return repository.getAllOpportunitiesForAdmin();
  }
}