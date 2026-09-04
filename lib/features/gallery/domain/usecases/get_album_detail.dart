import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GetAlbumDetail {
  final GalleryRepository repository;
  GetAlbumDetail(this.repository);
  Future<Album?> call(String albumId) => repository.getAlbumById(albumId);
}
