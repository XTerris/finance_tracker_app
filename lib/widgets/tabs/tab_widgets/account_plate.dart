import 'package:finance_tracker_app/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/account.dart';

class AccountPlate extends StatelessWidget {
  final Account account;
  final EdgeInsetsGeometry? margin;
  const AccountPlate({super.key, required this.account, this.margin});

  String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
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
      context.read<AccountProvider>().removeAccount(account.id);
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
          Text(
            'Баланс: ${_formatBalance(account.balance)}',
            style: const TextStyle(fontSize: 14),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmation(context),
            child: const Text("Удалить"),
          ),
        ],
      ),
    );
  }
}
