import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GetAlbums {
  final GalleryRepository repository;
  GetAlbums(this.repository);
  Future<List<Album>> call() => repository.getAlbums();
}
