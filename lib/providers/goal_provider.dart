import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../service_locator.dart';

class GoalProvider extends ChangeNotifier {
  Map<int, Goal> _goals = {};

  List<Goal> get goals => _goals.values.toList();

  /// Get goal by account ID instead of goal ID
  Goal? getGoalByAccountId(int accountId) {
    try {
      return _goals.values.firstWhere((goal) => goal.accountId == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Get all goals for a specific account
  List<Goal> getGoalsByAccountId(int accountId) {
    return _goals.values.where((goal) => goal.accountId == accountId).toList();
  }

  Future<void> init() async {
    // Initialize with data from database
    final goals = await serviceLocator.databaseService.getAllGoals();
    _goals = {for (var goal in goals) goal.id: goal};
    notifyListeners();
  }

  Future<void> addGoal({
    required int accountId,
    required double targetAmount,
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

  Future<void> updateGoal({
    required int id,
    int? accountId,
    double? targetAmount,
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

  Future<void> markGoalComplete(int id) async {
    final goal = await serviceLocator.databaseService.updateGoal(
      id: id,
      isCompleted: true,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  Future<void> markGoalIncomplete(int id) async {
    final goal = await serviceLocator.databaseService.updateGoal(
      id: id,
      isCompleted: false,
    );
    _goals[goal.id] = goal;
    notifyListeners();
  }

  Future<void> removeGoal(int id) async {
    await serviceLocator.databaseService.deleteGoal(id);
    _goals.remove(id);
    notifyListeners();
  }
}
