import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final FirebaseFirestore _firestore;
  final int _limit;

  GalleryRepositoryImpl(this._firestore, {int limit = 50}) : _limit = limit;

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
  Future<List<Album>> getAlbums() async {
    final snapshot = await _firestore
        .collection('gallery_albums')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs.map(Album.fromFirestore).toList();
  }

  @override
  Stream<List<Album>> watchAlbums() {
    return _firestore
        .collection('gallery_albums')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Album.fromFirestore).toList());
  }

  @override
  Future<Album?> getAlbumById(String albumId) async {
    final doc = await _firestore
        .collection('gallery_albums')
        .doc(albumId)
        .get();
    if (!doc.exists) return null;
    return Album.fromFirestore(doc);
  }

  @override
  Future<List<GalleryMedia>> getMediaByAlbumId(String albumId) async {
    final snapshot = await _firestore
        .collection('gallery_media')
        .where('albumId', isEqualTo: albumId)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs.map(GalleryMedia.fromFirestore).toList();
  }

  @override
  Future<Album> createAlbum(Map<String, dynamic> data) async {
    final result = await _callFunction('createAlbum', data);
    final albumId = result?['albumId'] as String?;
    if (albumId == null) throw StateError('Failed to create album');
    final doc = await _firestore
        .collection('gallery_albums')
        .doc(albumId)
        .get();
    if (!doc.exists) throw StateError('Failed to load created album');
    return Album.fromFirestore(doc);
  }

  @override
  Future<void> updateAlbum(String albumId, Map<String, dynamic> data) async {
    // updateAlbum (unlike createAlbum) doesn't return the updated document -
    // just a confirmation message - so nothing needs re-fetching here; the
    // album stream/list providers already pick up the change via Firestore.
    await _callFunction('updateAlbum', {'albumId': albumId, ...data});
  }

  @override
  Future<GalleryMedia> addMedia(Map<String, dynamic> data) async {
    final result = await _callFunction('addMediaToAlbum', data);
    final mediaId = result?['mediaId'] as String?;
    if (mediaId == null) throw StateError('Failed to add media');
    final doc = await _firestore.collection('gallery_media').doc(mediaId).get();
    if (!doc.exists) throw StateError('Failed to load added media');
    return GalleryMedia.fromFirestore(doc);
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    await _callFunction('deleteMedia', {'mediaId': mediaId});
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    await _callFunction('deleteAlbum', {'albumId': albumId});
  }

  @override
  Future<List<Album>> getAlbumsPage({int limit = 20, Album? startAfter}) async {
    var query = _firestore
        .collection('gallery_albums')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfter([startAfter.createdAt, startAfter.id]);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(Album.fromFirestore).toList();
  }

  @override
  Future<List<GalleryMedia>> getMediaPage(
    String albumId, {
    int limit = 20,
    GalleryMedia? startAfter,
  }) async {
    var query = _firestore
        .collection('gallery_media')
        .where('albumId', isEqualTo: albumId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfter([startAfter.createdAt, startAfter.id]);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(GalleryMedia.fromFirestore).toList();
  }
}