import '../entities/opportunity.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getActiveOpportunities();

  Stream<List<Opportunity>> watchActiveOpportunities();

  Future<List<Opportunity>> getAllOpportunitiesForAdmin();

  Future<Opportunity?> getOpportunityById(String opportunityId);

  Future<List<Opportunity>> searchOpportunities(String query);

  Future<Opportunity> createOpportunity(
    Map<String, dynamic> data,
  );

  Future<Opportunity> updateOpportunity(
    String opportunityId,
    Map<String, dynamic> data,
  );

  Future<void> deleteOpportunity(String opportunityId);
}