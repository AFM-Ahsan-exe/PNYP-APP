import '../entities/document_item.dart';

abstract class DocumentRepository {
  Future<List<DocumentItem>> getDocuments();
  Future<DocumentItem?> getDocumentById(String documentId);
  Future<DocumentItem> uploadDocument(Map<String, dynamic> data);
  Future<DocumentItem> updateDocument(
    String documentId,
    Map<String, dynamic> data,
  );
  Future<void> deleteDocument(String documentId);
  Stream<List<DocumentItem>> watchDocuments();
}