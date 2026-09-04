import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/registration_repository.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/submit_registration.dart';
import '../../domain/usecases/upload_document.dart';

final registrationRemoteDataSourceProvider = Provider<RegistrationRemoteDataSource>((ref) {
  return RegistrationRemoteDataSource(
    FirebaseAuth.instance,
    ref.watch(cloudFunctionsClientProvider),
  );
});

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepositoryImpl(
    ref.watch(registrationRemoteDataSourceProvider),
  );
});

final submitRegistrationProvider = Provider<SubmitRegistration>((ref) {
  return SubmitRegistration(ref.watch(registrationRepositoryProvider));
});

final uploadDocumentProvider = Provider<UploadDocument>((ref) {
  return UploadDocument(ref.watch(registrationRepositoryProvider));
});

final sendEmailVerificationProvider = Provider<SendEmailVerification>((ref) {
  return SendEmailVerification(ref.watch(registrationRepositoryProvider));
});

class RegistrationState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool emailSent;

  const RegistrationState({
    this.user,
    this.isLoading = false,
    this.error,
    this.emailSent = false,
  });

  RegistrationState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? emailSent,
  }) {
    return RegistrationState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      emailSent: emailSent ?? this.emailSent,
    );
  }
}

class RegistrationController extends Notifier<RegistrationState> {
  SubmitRegistration get _submitRegistration => ref.read(submitRegistrationProvider);
  UploadDocument get _uploadDocument => ref.read(uploadDocumentProvider);
  SendEmailVerification get _sendEmailVerification => ref.read(sendEmailVerificationProvider);

  @override
  RegistrationState build() {
    return const RegistrationState();
  }

  Future<void> submit(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _submitRegistration(data: data);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> uploadDocumentFile({
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    state = state.copyWith(error: null);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('No authenticated user');
      // storage.rules only grants access under documents/{userId}/{file}
      // (exactly two path segments). The previous path -
      // 'documents/<timestamp>_<filename>' - has one segment and matches
      // no rule, so Storage denies every upload by default. Every
      // registration document upload (CNIC front/back, CV, payment
      // proof) was failing because of this.
      final isCnic =
    fileName.toLowerCase().contains('cnic');

final folder = isCnic
    ? 'cnic_images'
    : 'documents';

final path =
    '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      return await _uploadDocument(path: path, bytes: bytes, contentType: contentType);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> sendVerificationEmail() async {
    state = state.copyWith(error: null);
    try {
      await _sendEmailVerification();
      state = state.copyWith(emailSent: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> completeRegistration({
    required Map<String, dynamic> formData,
    required Map<String, List<int>> documentBytes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Each upload is now paired with its field key at the point of
      // creation, not zipped afterward against a fixed key list by
      // index. The old code built `uploadPromises` conditionally (only
      // for document types that were actually present) but then zipped
      // the results against a fixed 4-key list by position - so
      // whenever any one document type was skipped, every later
      // document's URL got attributed to the wrong field (e.g. a
      // payment proof image saved as the CNIC back URL).
      final uploadEntries = <MapEntry<String, Future<String?>>>[];
      if (documentBytes['cnicFront'] != null) {
        uploadEntries.add(MapEntry(
          'cnicFront',
          uploadDocumentFile(
            fileName: 'cnic_front.jpg',
            bytes: documentBytes['cnicFront']!,
            contentType: 'image/jpeg',
          ),
        ));
      }
      if (documentBytes['cnicBack'] != null) {
        uploadEntries.add(MapEntry(
          'cnicBack',
          uploadDocumentFile(
            fileName: 'cnic_back.jpg',
            bytes: documentBytes['cnicBack']!,
            contentType: 'image/jpeg',
          ),
        ));
      }
      if (documentBytes['cv'] != null) {
        uploadEntries.add(MapEntry(
          'cv',
          uploadDocumentFile(
            fileName: 'cv.pdf',
            bytes: documentBytes['cv']!,
            contentType: 'application/pdf',
          ),
        ));
      }
      if (documentBytes['paymentProof'] != null) {
        uploadEntries.add(MapEntry(
          'paymentProof',
          uploadDocumentFile(
            fileName: 'payment_proof.jpg',
            bytes: documentBytes['paymentProof']!,
            contentType: 'image/jpeg',
          ),
        ));
      }

      final urls = await Future.wait(uploadEntries.map((e) => e.value));
      final urlMap = <String, String>{};
      for (var i = 0; i < uploadEntries.length; i++) {
        final url = urls[i];
        if (url != null) urlMap[uploadEntries[i].key] = url;
      }

      final data = Map<String, dynamic>.from(formData);
      data['cnicFrontUrl'] = urlMap['cnicFront'] ?? '';
      data['cnicBackUrl'] = urlMap['cnicBack'] ?? '';
      data['cvUrl'] = urlMap['cv'] ?? '';
      data['paymentProofUrl'] = urlMap['paymentProof'] ?? '';

      await _submitRegistration(data: data);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'onboardingCompleted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _sendEmailVerification();
      state = state.copyWith(isLoading: false, emailSent: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final registrationControllerProvider = NotifierProvider<RegistrationController, RegistrationState>(
  RegistrationController.new,
);
