import '../../domain/repositories/document_repository.dart';
import '../entities/document_item.dart';

class GetDocuments {
  final DocumentRepository repository;
  GetDocuments(this.repository);

  Future<List<DocumentItem>> call() => repository.getDocuments();
}
