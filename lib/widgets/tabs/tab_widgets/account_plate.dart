import 'package:finance_tracker_app/providers/account_provider.dart';
import 'package:finance_tracker_app/providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/account.dart';
import 'add_goal_bottom_sheet.dart';
import 'edit_account_bottom_sheet.dart';
import 'edit_goal_bottom_sheet.dart';

class AccountPlate extends StatelessWidget {
  final Account account;
  final EdgeInsetsGeometry? margin;
  const AccountPlate({super.key, required this.account, this.margin});

  String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(symbol: '₽', decimalDigits: 2);
    return formatter.format(balance);
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить счёт?'),
          content: Text(
            'Вы уверены, что хотите удалить счёт "${account.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AccountProvider>().removeAccount(account.id);
        // Update goals after deleting account
        if (context.mounted) {
          await context.read<GoalProvider>().update();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Счёт удалён')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddGoalBottomSheet(account: account),
    );
  }

  Future<void> _deleteGoal(BuildContext context, int goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить цель?'),
          content: const Text('Вы уверены, что хотите удалить эту цель?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<GoalProvider>().removeGoal(goalId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Цель удалена')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleGoalCompletion(
    BuildContext context,
    int goalId,
    bool isCompleted,
  ) async {
    try {
      final goalProvider = context.read<GoalProvider>();
      if (isCompleted) {
        await goalProvider.markGoalIncomplete(goalId);
      } else {
        await goalProvider.markGoalComplete(goalId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Цель отмечена как незавершённая'
                  : 'Цель достигнута!',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Баланс: ${_formatBalance(account.balance)}',
            style: const TextStyle(fontSize: 14),
          ),

          // Goal information
          Consumer<GoalProvider>(
            builder: (context, goalProvider, child) {
              final goal = goalProvider.getGoalByAccountId(account.id);

              if (goal == null) {
                // Show "Add Goal" button when no goal exists
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddGoalBottomSheet(context),
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('Добавить цель'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final progress = account.balance / goal.targetAmount;
              final progressPercent = (progress * 100).clamp(0, 100);
              final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Цель:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (goal.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Достигнута',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Целевая сумма: ${_formatBalance(goal.targetAmount)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Дедлайн: ${_formatDate(goal.deadline)}${daysLeft >= 0 ? ' ($daysLeft дн.)' : ' (просрочено)'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: daysLeft < 0 ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Прогресс: ${progressPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Осталось: ${_formatBalance(goal.targetAmount - account.balance)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? Colors.green
                                : progress >= 0.75
                                ? Colors.lightGreen
                                : progress >= 0.5
                                ? Colors.orange
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Goal action buttons
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder:
                                (context) => EditGoalBottomSheet(goal: goal),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Изменить'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => _toggleGoalCompletion(
                              context,
                              goal.id,
                              goal.isCompleted,
                            ),
                        icon: Icon(
                          goal.isCompleted
                              ? Icons.check_circle_outline
                              : Icons.check_circle,
                          size: 18,
                        ),
                        label: Text(
                          goal.isCompleted ? 'Не завершена' : 'Завершить',
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteGoal(context, goal.id),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Удалить цель'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (context) => EditAccountBottomSheet(account: account),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Изменить"),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete),
                label: const Text("Удалить счёт"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
