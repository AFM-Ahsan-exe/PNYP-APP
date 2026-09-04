import '../../domain/entities/opportunity.dart' as app_opportunity;
import '../../domain/repositories/opportunity_repository.dart';

class CreateOpportunity {
  final OpportunityRepository repository;
  CreateOpportunity(this.repository);
  Future<app_opportunity.Opportunity> call(Map<String, dynamic> data) =>
      repository.createOpportunity(data);
}
