import '../entities/admin_member.dart';

abstract class AdminMemberRepository {
  Future<List<AdminMember>> getMembers({String status = 'pending'});

  Future<void> updateStatus(String uid, String status, {String? reason});
}
