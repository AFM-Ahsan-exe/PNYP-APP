import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_all_opportunities_for_admin.dart';
import '../../data/repositories/opportunity_repository_impl.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';
import '../../domain/usecases/create_opportunity.dart';
import '../../domain/usecases/delete_opportunity.dart';
import '../../domain/usecases/get_opportunities.dart';
import '../../domain/usecases/get_opportunity_detail.dart';
import '../../domain/usecases/search_opportunities.dart';
import '../../domain/usecases/update_opportunity.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepositoryImpl(ref.watch(firestoreProvider));
});

final getOpportunitiesProvider = Provider<GetOpportunities>((ref) {
  return GetOpportunities(ref.watch(opportunityRepositoryProvider));
});

final getOpportunityDetailProvider = Provider<GetOpportunityDetail>((ref) {
  return GetOpportunityDetail(ref.watch(opportunityRepositoryProvider));
});

final searchOpportunitiesProvider = Provider<SearchOpportunities>((ref) {
  return SearchOpportunities(ref.watch(opportunityRepositoryProvider));
});

final createOpportunityProvider = Provider<CreateOpportunity>((ref) {
  return CreateOpportunity(ref.watch(opportunityRepositoryProvider));
});

final updateOpportunityProvider = Provider<UpdateOpportunity>((ref) {
  return UpdateOpportunity(ref.watch(opportunityRepositoryProvider));
});

final deleteOpportunityProvider = Provider<DeleteOpportunity>((ref) {
  return DeleteOpportunity(ref.watch(opportunityRepositoryProvider));
});

final opportunitiesProvider = FutureProvider.autoDispose<List<Opportunity>>((
  ref,
) async {
  return ref.watch(getOpportunitiesProvider)();
});
final opportunitiesStreamProvider =
    StreamProvider.autoDispose<List<Opportunity>>((ref) {
  return ref.watch(opportunityRepositoryProvider).watchActiveOpportunities();
});

final getAllOpportunitiesForAdminProvider =
    Provider<GetAllOpportunitiesForAdmin>((ref) {
  return GetAllOpportunitiesForAdmin(
    ref.watch(opportunityRepositoryProvider),
  );
});

final adminOpportunitiesProvider =
    FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  return ref.watch(getAllOpportunitiesForAdminProvider)();
});

final opportunityDetailProvider = FutureProvider.autoDispose
    .family<Opportunity?, String>((ref, opportunityId) async {
      return ref.watch(getOpportunityDetailProvider)(opportunityId);
    });

final opportunitySearchProvider = FutureProvider.autoDispose
    .family<List<Opportunity>, String>((ref, query) async {
      return ref.watch(searchOpportunitiesProvider)(query);
    });
