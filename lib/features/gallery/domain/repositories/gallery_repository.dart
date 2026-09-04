import '../entities/gallery_item.dart';

abstract class GalleryRepository {
  Future<List<Album>> getAlbums();
  Stream<List<Album>> watchAlbums();
  Future<Album?> getAlbumById(String albumId);
  Future<List<GalleryMedia>> getMediaByAlbumId(String albumId);
  Future<Album> createAlbum(Map<String, dynamic> data);
  Future<void> updateAlbum(String albumId, Map<String, dynamic> data);
  Future<GalleryMedia> addMedia(Map<String, dynamic> data);
  Future<void> deleteMedia(String mediaId);
  Future<void> deleteAlbum(String albumId);
  Future<List<Album>> getAlbumsPage({int limit = 20, Album? startAfter});
  Future<List<GalleryMedia>> getMediaPage(
    String albumId, {
    int limit = 20,
    GalleryMedia? startAfter,
  });
}