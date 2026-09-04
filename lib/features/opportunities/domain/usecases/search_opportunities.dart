import '../../domain/repositories/opportunity_repository.dart';
import '../entities/opportunity.dart';

class SearchOpportunities {
  final OpportunityRepository repository;
  SearchOpportunities(this.repository);

  Future<List<Opportunity>> call(String query) =>
      repository.searchOpportunities(query);
}
