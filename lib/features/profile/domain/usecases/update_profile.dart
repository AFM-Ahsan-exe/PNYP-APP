import '../../domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<void> call(Map<String, dynamic> data) =>
      repository.updateProfile(data);
}
