import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/admin_member.dart';
import '../../domain/repositories/admin_member_repository.dart';
import '../datasources/admin_member_remote_datasource.dart';

class AdminMemberRepositoryImpl implements AdminMemberRepository {
  final AdminMemberRemoteDataSource remoteDataSource;

  AdminMemberRepositoryImpl(FirebaseAuth auth, http.Client client)
    : remoteDataSource = AdminMemberRemoteDataSource(auth, client);

  @override
  Future<List<AdminMember>> getMembers({String status = 'pending'}) {
    return remoteDataSource.getMembers(status: status);
  }

  @override
  Future<void> updateStatus(String uid, String status) {
    return remoteDataSource.updateStatus(uid, status);
  }
}
