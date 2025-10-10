import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../service_locator.dart';

class CategoryProvider extends ChangeNotifier {
  Map<int, models.Category> _categories = {};

  List<models.Category> get categories => _categories.values.toList();

  Future<void> init() async {
    // Initialize with data from cache
    final categories = await serviceLocator.hiveService.getAllCategories();
    _categories = {for (var category in categories) category.id: category};
    notifyListeners();
    update();
  }

  Future<void> update() async {
    try {
      final categories = await serviceLocator.apiService.getAllCategories();
      _categories = {for (var category in categories) category.id: category};
      await serviceLocator.hiveService.clearAllCategories();
      await serviceLocator.hiveService.saveCategories(categories);
      notifyListeners();
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void addCategory(String categoryName) async {
    final category = await serviceLocator.apiService.createCategory(
      categoryName,
    );
    _categories[category.id] = category;
    await serviceLocator.hiveService.saveCategories([category]);

    notifyListeners();
  }

  void removeCategory(int id) async {
    await serviceLocator.apiService.deleteCategory(id);
    _categories.remove(id);
    await serviceLocator.hiveService.deleteCategory(id);
    notifyListeners();
  }
}
