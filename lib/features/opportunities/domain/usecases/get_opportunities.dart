import '../../domain/repositories/opportunity_repository.dart';
import '../entities/opportunity.dart';

class GetOpportunities {
  final OpportunityRepository repository;
  GetOpportunities(this.repository);

  Future<List<Opportunity>> call() => repository.getActiveOpportunities();
}
