import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../service_locator.dart';

// Провайдер для управления состоянием категорий транзакций
class CategoryProvider extends ChangeNotifier {
  Map<int, models.Category> _categories = {};

  List<models.Category> get categories => _categories.values.toList();

  // Загрузка всех категорий из базы данных
  Future<void> init() async {
    final categories = await serviceLocator.databaseService.getAllCategories();
    _categories = {for (var category in categories) category.id: category};
    notifyListeners();
  }

  // Обновление списка категорий из БД
  Future<void> update() async {
    await init();
  }

  // Создание новой категории
  Future<void> addCategory(String categoryName) async {
    final category = await serviceLocator.databaseService.createCategory(
      categoryName,
    );
    _categories[category.id] = category;
    notifyListeners();
  }

  // Удаление категории
  Future<void> removeCategory(int id) async {
    await serviceLocator.databaseService.deleteCategory(id);
    _categories.remove(id);
    notifyListeners();
  }
}
