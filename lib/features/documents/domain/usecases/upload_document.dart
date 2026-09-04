import '../../domain/entities/document_item.dart' as app_document;
import '../../domain/repositories/document_repository.dart';

class UploadDocument {
  final DocumentRepository repository;

  UploadDocument(this.repository);

  Future<app_document.DocumentItem> call(Map<String, dynamic> data) {
    return repository.uploadDocument(data);
  }
}
