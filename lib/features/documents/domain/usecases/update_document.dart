import '../../domain/entities/document_item.dart' as app_document;
import '../../domain/repositories/document_repository.dart';

class UpdateDocument {
  final DocumentRepository repository;

  UpdateDocument(this.repository);

  Future<app_document.DocumentItem> call(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return repository.updateDocument(documentId, data);
  }
}
