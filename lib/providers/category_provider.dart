import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../service_locator.dart';

class CategoryProvider extends ChangeNotifier {
  Map<int, models.Category> _categories = {};

  List<models.Category> get categories => _categories.values.toList();

  Future<void> init() async {
    // Initialize with data from database
    final categories = await serviceLocator.databaseService.getAllCategories();
    _categories = {for (var category in categories) category.id: category};
    notifyListeners();
  }

  Future<void> update() async {
    // Reload data from database
    await init();
  }

  Future<void> addCategory(String categoryName) async {
    final category = await serviceLocator.databaseService.createCategory(
      categoryName,
    );
    _categories[category.id] = category;
    notifyListeners();
  }

  Future<void> removeCategory(int id) async {
    await serviceLocator.databaseService.deleteCategory(id);
    _categories.remove(id);
    notifyListeners();
  }
}
