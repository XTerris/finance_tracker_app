import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/goal_provider.dart';
import 'tab_widgets/transaction_plate.dart';
import 'tab_widgets/add_transaction_bottom_sheet.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final transactionProvider = context.read<TransactionProvider>();
          final categoryProvider = context.read<CategoryProvider>();
          final accountProvider = context.read<AccountProvider>();
          final goalProvider = context.read<GoalProvider>();

          await transactionProvider.init();
          await categoryProvider.init();
          await accountProvider.init();
          await goalProvider.init();
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  Text(
                    'История',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            if (context.watch<TransactionProvider>().transactions.isEmpty)
              Center(
                child: SizedBox(
                  height: 200,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Нет транзакций',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...context.watch<TransactionProvider>().transactions.map(
                (transaction) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: TransactionPlate(transaction: transaction),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionBottomSheet,
        tooltip: 'Добавить транзакцию',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }
}
