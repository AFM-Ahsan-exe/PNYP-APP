import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GetAlbumMedia {
  final GalleryRepository repository;
  GetAlbumMedia(this.repository);
  Future<List<GalleryMedia>> call(String albumId) =>
      repository.getMediaByAlbumId(albumId);
}
