import '../../../auth/domain/entities/app_user.dart';
import '../entities/public_profile.dart';

abstract class ProfileRepository {
  Future<AppUser?> getCurrentUserProfile();

  Future<void> updateProfile(Map<String, dynamic> data);

  Future<List<PublicProfile>> getMemberDirectory({String? query});
}
