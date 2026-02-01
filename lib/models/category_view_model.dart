import 'package:lumio/models/category.dart';
import 'package:lumio/models/playlist_content_model.dart';

class CategoryViewModel {
  final Category category;
  final List<ContentItem> contentItems;

  CategoryViewModel({required this.category, required this.contentItems});
}