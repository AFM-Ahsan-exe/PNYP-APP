import '../../domain/entities/app_user.dart';
import '../../domain/repositories/registration_repository.dart';
import '../datasources/registration_remote_datasource.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  final RegistrationRemoteDataSource remoteDataSource;

  RegistrationRepositoryImpl(this.remoteDataSource);

  @override
  Future<AppUser> submitRegistration({required Map<String, dynamic> data}) {
    return remoteDataSource.submitRegistration(data: data);
  }

  @override
  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) {
    return remoteDataSource.uploadFile(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  @override
  Future<void> sendEmailVerification() {
    return remoteDataSource.sendEmailVerification();
  }
}
