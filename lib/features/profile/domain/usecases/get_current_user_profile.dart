import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';

class GetCurrentUserProfile {
  final ProfileRepository repository;

  GetCurrentUserProfile(this.repository);

  Future<AppUser?> call() => repository.getCurrentUserProfile();
}
