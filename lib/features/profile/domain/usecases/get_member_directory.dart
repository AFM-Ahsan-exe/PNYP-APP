import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class GetMemberDirectory {
  final ProfileRepository repository;

  GetMemberDirectory(this.repository);

  Future<List<PublicProfile>> call({String? query}) =>
      repository.getMemberDirectory(query: query);
}
