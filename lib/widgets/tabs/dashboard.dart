import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import 'tab_widgets/transaction_plate.dart';

/// Dashboard tab displaying financial statistics and recent transactions
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

/// Helper class to hold calculated dashboard statistics
class _DashboardStats {
  final double currentMonthExpenses;
  final double currentMonthIncome;

  _DashboardStats({
    required this.currentMonthExpenses,
    required this.currentMonthIncome,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DashboardStats &&
          runtimeType == other.runtimeType &&
          currentMonthExpenses == other.currentMonthExpenses &&
          currentMonthIncome == other.currentMonthIncome;

  @override
  int get hashCode =>
      currentMonthExpenses.hashCode ^ currentMonthIncome.hashCode;
}

class _DashboardTabState extends State<DashboardTab> {
  // Calculate all dashboard statistics from transactions
  _DashboardStats _calculateDashboardStats(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    double currentMonthExpenses = 0.0;
    double currentMonthIncome = 0.0;

    for (var transaction in transactions) {
      // Current month expenses
      // Use !isBefore to include transactions at exact start of month
      if (!transaction.doneAt.isBefore(currentMonthStart) &&
          transaction.fromAccountId != null &&
          transaction.toAccountId == null) {
        currentMonthExpenses += transaction.amount.abs();
      }

      // Current month income
      // Use !isBefore to include transactions at exact start of month
      if (!transaction.doneAt.isBefore(currentMonthStart) &&
          transaction.toAccountId != null &&
          transaction.fromAccountId == null) {
        currentMonthIncome += transaction.amount.abs();
      }
    }

    return _DashboardStats(
      currentMonthExpenses: currentMonthExpenses,
      currentMonthIncome: currentMonthIncome,
    );
  }

  // Calculate total balance across all accounts
  double _calculateTotalBalance(List<Account> accounts) {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  // Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 12) {
      return 'Доброе утро!';
    } else if (hour >= 12 && hour < 18) {
      return 'Добрый день!';
    } else if (hour >= 18 && hour < 23) {
      return 'Добрый вечер!';
    } else {
      return 'Доброй ночи!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Total Balance Card
            Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                final totalBalance = _calculateTotalBalance(
                  accountProvider.accounts,
                );
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Общий баланс',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalBalance),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 16),

            // Current Month Stats label
            Text(
              'В текущем месяце',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Current Month Stats
            Selector<TransactionProvider, _DashboardStats>(
              selector:
                  (context, transactionProvider) => _calculateDashboardStats(
                    transactionProvider.transactions,
                  ),
              builder: (context, stats, child) {
                final currentMonthExpenses = stats.currentMonthExpenses;
                final currentMonthIncome = stats.currentMonthIncome;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 20,
                                      color: Colors.green[700],
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Доходы',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(currentMonthIncome),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 20,
                                      color: Colors.red[700],
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Расходы',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(currentMonthExpenses),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 24),
            Text(
              'Последние операции',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...context
                .watch<TransactionProvider>()
                .transactions
                .take(5)
                .map(
                  (transaction) => TransactionPlate(
                    transaction: Transaction(
                      id: transaction.id,
                      title: transaction.title,
                      amount: transaction.amount,
                      doneAt: transaction.doneAt,
                      categoryId: transaction.categoryId,
                      fromAccountId: transaction.fromAccountId,
                      toAccountId: transaction.toAccountId,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
