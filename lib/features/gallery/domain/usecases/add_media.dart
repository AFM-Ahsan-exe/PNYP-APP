import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

class AddMedia {
  final GalleryRepository repository;
  AddMedia(this.repository);
  Future<GalleryMedia> call(Map<String, dynamic> data) =>
      repository.addMedia(data);
}
