import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/registration_repository.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/submit_registration.dart';
import '../../domain/usecases/upload_document.dart';

final cloudFunctionsClientProvider = Provider<CloudFunctionsClient>((ref) {
  final projectId = Firebase.app().options.projectId;
  return CloudFunctionsClient(projectId: projectId, region: 'us-central1');
});

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
      final path = 'documents/${DateTime.now().millisecondsSinceEpoch}_$fileName';
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
      final uploadPromises = <Future<String?>>[];
      if (documentBytes['cnicFront'] != null) {
        uploadPromises.add(uploadDocumentFile(
          fileName: 'cnic_front.jpg',
          bytes: documentBytes['cnicFront']!,
          contentType: 'image/jpeg',
        ));
      }
      if (documentBytes['cnicBack'] != null) {
        uploadPromises.add(uploadDocumentFile(
          fileName: 'cnic_back.jpg',
          bytes: documentBytes['cnicBack']!,
          contentType: 'image/jpeg',
        ));
      }
      if (documentBytes['cv'] != null) {
        uploadPromises.add(uploadDocumentFile(
          fileName: 'cv.pdf',
          bytes: documentBytes['cv']!,
          contentType: 'application/pdf',
        ));
      }
      if (documentBytes['paymentProof'] != null) {
        uploadPromises.add(uploadDocumentFile(
          fileName: 'payment_proof.jpg',
          bytes: documentBytes['paymentProof']!,
          contentType: 'image/jpeg',
        ));
      }

      final urls = await Future.wait(uploadPromises);
      final urlMap = <String, String>{};
      const keys = ['cnicFront', 'cnicBack', 'cv', 'paymentProof'];
      for (var i = 0; i < urls.length && i < keys.length; i++) {
        if (urls[i] != null) urlMap[keys[i]] = urls[i]!;
      }

      final data = Map<String, dynamic>.from(formData);
      data['cnicFrontUrl'] = urlMap['cnicFront'] ?? '';
      data['cnicBackUrl'] = urlMap['cnicBack'] ?? '';
      data['cvUrl'] = urlMap['cv'] ?? '';
      data['paymentProofUrl'] = urlMap['paymentProof'] ?? '';

      await _submitRegistration(data: data);
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
