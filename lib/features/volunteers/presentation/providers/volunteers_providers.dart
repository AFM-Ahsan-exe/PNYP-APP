import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/volunteer_repository_impl.dart';
import '../../domain/entities/volunteer.dart';
import '../../domain/repositories/volunteer_repository.dart';
import '../../domain/usecases/apply_as_volunteer.dart';
import '../../domain/usecases/get_all_volunteer_applications.dart';
import '../../domain/usecases/get_my_volunteer_applications.dart';
import '../../domain/usecases/update_volunteer_status.dart';
import '../../domain/usecases/withdraw_volunteer_application.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final volunteerRepositoryProvider = Provider<VolunteerRepository>((ref) {
  return VolunteerRepositoryImpl(ref.watch(firestoreProvider));
});

final getMyVolunteerApplicationsProvider = Provider<GetMyVolunteerApplications>(
  (ref) {
    return GetMyVolunteerApplications(ref.watch(volunteerRepositoryProvider));
  },
);

final getAllVolunteerApplicationsProvider =
    Provider<GetAllVolunteerApplications>((ref) {
      return GetAllVolunteerApplications(
        ref.watch(volunteerRepositoryProvider),
      );
    });

final applyAsVolunteerProvider = Provider<ApplyAsVolunteer>((ref) {
  return ApplyAsVolunteer(ref.watch(volunteerRepositoryProvider));
});

final updateVolunteerStatusProvider = Provider<UpdateVolunteerStatus>((ref) {
  return UpdateVolunteerStatus(ref.watch(volunteerRepositoryProvider));
});

final withdrawVolunteerApplicationProvider =
    Provider<WithdrawVolunteerApplication>((ref) {
      return WithdrawVolunteerApplication(
        ref.watch(volunteerRepositoryProvider),
      );
    });

final volunteersProvider = FutureProvider.autoDispose<List<Volunteer>>((
  ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  return ref.watch(getMyVolunteerApplicationsProvider)(user.uid);
});

final adminVolunteersProvider = FutureProvider.autoDispose<List<Volunteer>>((
  ref,
) async {
  return ref.watch(getAllVolunteerApplicationsProvider)();
});
