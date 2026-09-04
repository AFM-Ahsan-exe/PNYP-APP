import '../../domain/repositories/opportunity_repository.dart';

class DeleteOpportunity {
  final OpportunityRepository repository;
  DeleteOpportunity(this.repository);
  Future<void> call(String opportunityId) =>
      repository.deleteOpportunity(opportunityId);
}
