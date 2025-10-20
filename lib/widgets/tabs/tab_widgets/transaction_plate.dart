import 'package:finance_tracker_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/goal_provider.dart';
import 'edit_transaction_bottom_sheet.dart';

class TransactionPlate extends StatelessWidget {
  final Transaction transaction;
  final EdgeInsetsGeometry? margin;
  const TransactionPlate({super.key, required this.transaction, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: margin ?? EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('Сумма: ${transaction.amount}', style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          Text('Счет списания: ${transaction.fromAccountId}'),
          Text('Счет зачисления: ${transaction.toAccountId}'),
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
                        (context) => EditTransactionBottomSheet(
                          transaction: transaction,
                        ),
                  );
                },
                icon: Icon(Icons.edit),
                label: Text("Изменить"),
              ),
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final transactionProvider =
                      context.read<TransactionProvider>();
                  final accountProvider = context.read<AccountProvider>();
                  final goalProvider = context.read<GoalProvider>();

                  try {
                    await transactionProvider.removeTransaction(transaction.id);
                    await accountProvider.update();
                    await goalProvider.update();

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Транзакция удалена')),
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
                icon: Icon(Icons.delete),
                label: Text("Удалить"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
