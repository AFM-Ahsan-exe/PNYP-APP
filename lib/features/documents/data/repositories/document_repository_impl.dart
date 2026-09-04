import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final FirebaseFirestore _firestore;
  final int _limit;

  DocumentRepositoryImpl(this._firestore, {int limit = 50}) : _limit = limit;

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<List<DocumentItem>> getDocuments() async {
    final snapshot = await _firestore
        .collection('documents')
        .where(
          'accessLevel',
          whereIn: const [
            'public',
            'members_only',
          ],
        )
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs.map(DocumentItem.fromFirestore).toList();
  }

  @override
  Stream<List<DocumentItem>> watchDocuments() {
    return _firestore
        .collection('documents')
        .where(
          'accessLevel',
          whereIn: const [
            'public',
            'members_only',
          ],
        )
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DocumentItem.fromFirestore).toList());
  }

  @override
  Future<DocumentItem?> getDocumentById(String documentId) async {
    final doc = await _firestore.collection('documents').doc(documentId).get();
    if (!doc.exists) return null;
    return DocumentItem.fromFirestore(doc);
  }

  @override
  Future<DocumentItem> uploadDocument(Map<String, dynamic> data) async {
    final result = await _callFunction('uploadDocument', data);
    final documentId = result?['documentId'] as String?;
    if (documentId == null) throw StateError('Failed to upload document');
    final doc = await _firestore.collection('documents').doc(documentId).get();
    if (!doc.exists) throw StateError('Failed to load uploaded document');
    return DocumentItem.fromFirestore(doc);
  }

  @override
  Future<DocumentItem> updateDocument(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _callFunction('updateDocument', {...data, 'documentId': documentId});
    final doc = await _firestore.collection('documents').doc(documentId).get();
    if (!doc.exists) throw StateError('Failed to load updated document');
    return DocumentItem.fromFirestore(doc);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _callFunction('deleteDocument', {'documentId': documentId});
  }
}