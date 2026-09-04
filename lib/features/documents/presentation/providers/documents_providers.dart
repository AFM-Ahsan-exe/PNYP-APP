import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_document_detail.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/update_document.dart';
import '../../domain/usecases/upload_document.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    ref.watch(firestoreProvider),
  );
});

final getDocumentsProvider = Provider<GetDocuments>((ref) {
  return GetDocuments(
    ref.watch(documentRepositoryProvider),
  );
});

final getDocumentDetailProvider = Provider<GetDocumentDetail>((ref) {
  return GetDocumentDetail(
    ref.watch(documentRepositoryProvider),
  );
});

final uploadDocumentProvider = Provider<UploadDocument>((ref) {
  return UploadDocument(
    ref.watch(documentRepositoryProvider),
  );
});

final updateDocumentProvider = Provider<UpdateDocument>((ref) {
  return UpdateDocument(
    ref.watch(documentRepositoryProvider),
  );
});

final deleteDocumentProvider = Provider<DeleteDocument>((ref) {
  return DeleteDocument(
    ref.watch(documentRepositoryProvider),
  );
});

final documentsProvider =
    FutureProvider.autoDispose<List<DocumentItem>>((ref) async {
  return ref.watch(getDocumentsProvider)();
});

final documentsStreamProvider =
    StreamProvider.autoDispose<List<DocumentItem>>((ref) {
  return ref
      .watch(documentRepositoryProvider)
      .watchDocuments();
});

final documentDetailProvider =
    FutureProvider.autoDispose.family<DocumentItem?, String>(
  (ref, documentId) async {
    return ref.watch(getDocumentDetailProvider)(documentId);
  },
);