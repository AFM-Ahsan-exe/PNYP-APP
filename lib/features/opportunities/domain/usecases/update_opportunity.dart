import '../../domain/entities/opportunity.dart' as app_opportunity;
import '../../domain/repositories/opportunity_repository.dart';

class UpdateOpportunity {
  final OpportunityRepository repository;
  UpdateOpportunity(this.repository);
  Future<app_opportunity.Opportunity> call(
    String opportunityId,
    Map<String, dynamic> data,
  ) => repository.updateOpportunity(opportunityId, data);
}
