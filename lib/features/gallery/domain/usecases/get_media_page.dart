import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GetMediaPage {
  final GalleryRepository repository;
  GetMediaPage(this.repository);
  Future<List<GalleryMedia>> call(
    String albumId, {
    int limit = 20,
    GalleryMedia? startAfter,
  }) => repository.getMediaPage(albumId, limit: limit, startAfter: startAfter);
}
