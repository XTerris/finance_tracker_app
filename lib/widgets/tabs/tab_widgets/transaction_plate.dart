import 'package:finance_tracker_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction.dart';
import '../../../providers/account_provider.dart';

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
          TextButton(
            onPressed: () async {
              try {
                await context.read<TransactionProvider>().removeTransaction(
                  transaction.id,
                );
                await context.read<AccountProvider>().update();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Транзакция удалена')),
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
            },
            child: Text("Удалить"),
          ),
        ],
      ),
    );
  }
}
