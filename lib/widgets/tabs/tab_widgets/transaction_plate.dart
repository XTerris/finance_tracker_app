import 'package:finance_tracker_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/goal_provider.dart';
import 'edit_transaction_bottom_sheet.dart';
import 'plate_base.dart';

// Карточка для отображения одной транзакции в списке
class TransactionPlate extends PlateBase {
  final Transaction transaction;
  const TransactionPlate({super.key, required this.transaction, super.margin});

  // Получение названия счета по ID
  String _getAccountName(AccountProvider accountProvider, int? accountId) {
    if (accountId == null) return '—';

    try {
      final account = accountProvider.accounts.firstWhere(
        (acc) => acc.id == accountId,
      );
      return account.name;
    } catch (e) {
      // Игнорируем ошибки при получении названий
      return '—';
    }
  }

  // Получение названия категории по ID
  String _getCategoryName(CategoryProvider categoryProvider, int categoryId) {
    try {
      final category = categoryProvider.categories.firstWhere(
        (cat) => cat.id == categoryId,
      );
      return category.name;
    } catch (e) {
      return 'Не указана';
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Создание индикатора типа транзакции (расход/доход/перевод)
  Widget _buildTransactionTypeIndicator() {
    final bool hasFrom = transaction.fromAccountId != null;
    final bool hasTo = transaction.toAccountId != null;

    if (hasFrom && hasTo) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'Перевод',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (hasFrom && !hasTo) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'Списание',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (!hasFrom && hasTo) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Зачисление',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  Widget buildContent(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    String fromAccountName = '—';
    String toAccountName = '—';
    String categoryName = 'Не указана';

    try {
      if (transaction.fromAccountId != null) {
        fromAccountName = _getAccountName(
          accountProvider,
          transaction.fromAccountId,
        );
      }
      if (transaction.toAccountId != null) {
        toAccountName = _getAccountName(
          accountProvider,
          transaction.toAccountId,
        );
      }
      categoryName = _getCategoryName(categoryProvider, transaction.categoryId);
    } catch (e) {
      // Ignore errors when fetching account or category names
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                transaction.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8),
            _buildTransactionTypeIndicator(),
          ],
        ),
        SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatAmount(transaction.amount.amount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        if (transaction.fromAccountId != null) ...[
          Row(
            children: [
              Icon(Icons.call_made, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Счет списания: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  fromAccountName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],

        if (transaction.toAccountId != null) ...[
          Row(
            children: [
              Icon(Icons.call_received, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Счет зачисления: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  toAccountName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  dateFormat.format(transaction.doneAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
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
                            (context) => EditTransactionBottomSheet(
                              transaction: transaction,
                            ),
                      );
                    },
                    icon: Icon(Icons.edit, size: 20),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Изменить',
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final transactionProvider =
                          context.read<TransactionProvider>();
                      final accountProvider = context.read<AccountProvider>();
                      final goalProvider = context.read<GoalProvider>();

                      try {
                        await transactionProvider.removeTransaction(
                          transaction.id,
                        );
                        await accountProvider.update();
                        await goalProvider.update();

                        messenger.showSnackBar(
                          const SnackBar(content: Text('Операция удалена')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Удалить',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
