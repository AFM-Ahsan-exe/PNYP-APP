import '../../domain/repositories/document_repository.dart';

class DeleteDocument {
  final DocumentRepository repository;

  DeleteDocument(this.repository);

  Future<void> call(String documentId) {
    return repository.deleteDocument(documentId);
  }
}
