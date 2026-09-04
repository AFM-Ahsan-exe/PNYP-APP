import '../../domain/repositories/opportunity_repository.dart';
import '../entities/opportunity.dart';

class GetOpportunityDetail {
  final OpportunityRepository repository;
  GetOpportunityDetail(this.repository);

  Future<Opportunity?> call(String opportunityId) =>
      repository.getOpportunityById(opportunityId);
}
