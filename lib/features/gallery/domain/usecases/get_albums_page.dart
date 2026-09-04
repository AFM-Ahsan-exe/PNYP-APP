import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class GetAlbumsPage {
  final GalleryRepository repository;
  GetAlbumsPage(this.repository);
  Future<List<Album>> call({int limit = 20, Album? startAfter}) =>
      repository.getAlbumsPage(limit: limit, startAfter: startAfter);
}
