import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/money.dart';
import '../service_locator.dart';

// Провайдер для управления состоянием финансовых целей
class GoalProvider extends ChangeNotifier {
  Map<int, Goal> _goals = {};

  List<Goal> get goals => _goals.values.toList();

  // Получение цели для конкретного счета (первой найденной)
  Goal? getGoalByAccountId(int accountId) {
    try {
      return _goals.values.firstWhere((goal) => goal.accountId == accountId);
    } catch (e) {
      return null;
    }
  }

  // Получение всех целей для конкретного счета
  List<Goal> getGoalsByAccountId(int accountId) {
    return _goals.values.where((goal) => goal.accountId == accountId).toList();
  }

  // Загрузка всех целей из базы данных
  Future<void> init() async {
    final goals = await serviceLocator.databaseService.getAllGoals();
    _goals = {for (var goal in goals) goal.id: goal};
    notifyListeners();
  }

  // Обновление списка целей из БД
  Future<void> update() async {
    await init();
  }

  // Создание новой цели
  Future<void> addGoal({
    required int accountId,
    required Money targetAmount,
    required DateTime deadline,
  }) async {
    final goal = await serviceLocator.databaseService.createGoal(
      accountId: accountId,
      targetAmount: targetAmount,
      deadline: deadline,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  // Обновление существующей цели
  Future<void> updateGoal({
    required int id,
    int? accountId,
    Money? targetAmount,
    DateTime? deadline,
    bool? isCompleted,
  }) async {
    final goal = await serviceLocator.databaseService.updateGoal(
      id: id,
      accountId: accountId,
      targetAmount: targetAmount,
      deadline: deadline,
      isCompleted: isCompleted,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  // Пометка цели как выполненной
  Future<void> markGoalComplete(int id) async {
    final goal = await serviceLocator.databaseService.updateGoal(
      id: id,
      isCompleted: true,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  // Пометка цели как невыполненной
  Future<void> markGoalIncomplete(int id) async {
    final goal = await serviceLocator.databaseService.updateGoal(
      id: id,
      isCompleted: false,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  // Удаление цели
  Future<void> removeGoal(int id) async {
    await serviceLocator.databaseService.deleteGoal(id);
    _goals.remove(id);
    notifyListeners();
  }
}
