import '../../domain/entities/app_user.dart';

abstract class RegistrationRepository {
  Future<AppUser> submitRegistration({required Map<String, dynamic> data});

  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  });

  Future<void> sendEmailVerification();
}
