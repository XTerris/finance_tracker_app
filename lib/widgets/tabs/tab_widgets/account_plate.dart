import 'package:finance_tracker_app/providers/account_provider.dart';
import 'package:finance_tracker_app/providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/account.dart';
import 'add_goal_bottom_sheet.dart';
import 'edit_account_bottom_sheet.dart';
import 'edit_goal_bottom_sheet.dart';
import 'plate_base.dart';

// Карточка для отображения счета с целями и управлением
class AccountPlate extends PlateBase {
  final Account account;
  const AccountPlate({super.key, required this.account, super.margin});

  String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(balance);
  }

  // Показ диалога подтверждения удаления счета
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

    // Удаление счета если подтверждено
    if (confirmed == true && context.mounted) {
      try {
        await context.read<AccountProvider>().removeAccount(account.id);
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
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatBalance(account.balance.amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        Consumer<GoalProvider>(
          builder: (context, goalProvider, child) {
            final goal = goalProvider.getGoalByAccountId(account.id);

            if (goal == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Нет активной цели',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddGoalBottomSheet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Добавить'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final progress = account.balance.amount / goal.targetAmount.amount;
            final progressPercent = (progress * 100).clamp(0, 100);
            final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.flag,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Цель',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Достигнута',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.savings,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Целевая сумма: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatBalance(goal.targetAmount.amount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Дедлайн: ',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  daysLeft < 0 ? Colors.red : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_formatDate(goal.deadline)}${daysLeft >= 0 ? ' ($daysLeft дн.)' : ' (просрочено)'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: daysLeft < 0 ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Осталось: ${_formatBalance(goal.targetAmount.amount - account.balance.amount)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 10,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
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
                                      (context) =>
                                          EditGoalBottomSheet(goal: goal),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 20),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Изменить цель',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  goal.isCompleted
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed:
                                  () => _toggleGoalCompletion(
                                    context,
                                    goal.id,
                                    goal.isCompleted,
                                  ),
                              icon: Icon(
                                goal.isCompleted
                                    ? Icons.replay
                                    : Icons.check_circle,
                                size: 20,
                              ),
                              color:
                                  goal.isCompleted
                                      ? Colors.orange
                                      : Colors.green,
                              tooltip:
                                  goal.isCompleted
                                      ? 'Отметить как незавершённую'
                                      : 'Отметить как завершённую',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _deleteGoal(context, goal.id),
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              tooltip: 'Удалить цель',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
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
                icon: const Icon(Icons.edit, size: 20),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Изменить счёт',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                tooltip: 'Удалить счёт',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
