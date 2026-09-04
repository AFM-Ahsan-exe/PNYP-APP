import '../../domain/repositories/document_repository.dart';
import '../entities/document_item.dart';

class GetDocumentDetail {
  final DocumentRepository repository;
  GetDocumentDetail(this.repository);

  Future<DocumentItem?> call(String documentId) =>
      repository.getDocumentById(documentId);
}
