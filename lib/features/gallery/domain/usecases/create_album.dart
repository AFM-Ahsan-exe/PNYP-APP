import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class CreateAlbum {
  final GalleryRepository repository;
  CreateAlbum(this.repository);
  Future<Album> call(Map<String, dynamic> data) => repository.createAlbum(data);
}
