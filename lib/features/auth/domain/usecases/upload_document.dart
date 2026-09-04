import '../../domain/repositories/registration_repository.dart';

class UploadDocument {
  final RegistrationRepository repository;

  const UploadDocument(this.repository);

  Future<String> call({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) {
    return repository.uploadFile(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
