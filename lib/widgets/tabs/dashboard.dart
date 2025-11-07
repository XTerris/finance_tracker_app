import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import 'tab_widgets/transaction_plate.dart';

/// Dashboard tab displaying financial statistics and recent transactions
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Calculate expenses for last month
  double _calculateLastMonthExpenses(List<Transaction> transactions) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    
    double total = 0.0;
    for (var transaction in transactions) {
      // Expense is when money goes out from an account (has fromAccountId but no toAccountId, or amount is negative)
      if (transaction.doneAt.isAfter(lastMonth) && 
          transaction.doneAt.isBefore(lastMonthEnd) &&
          transaction.fromAccountId != null && 
          transaction.toAccountId == null) {
        total += transaction.amount.abs();
      }
    }
    return total;
  }

  // Calculate current month expenses
  double _calculateCurrentMonthExpenses(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    
    double total = 0.0;
    for (var transaction in transactions) {
      if (transaction.doneAt.isAfter(currentMonthStart) &&
          transaction.fromAccountId != null && 
          transaction.toAccountId == null) {
        total += transaction.amount.abs();
      }
    }
    return total;
  }

  // Calculate current month income
  double _calculateCurrentMonthIncome(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    
    double total = 0.0;
    for (var transaction in transactions) {
      // Income is when money comes into an account (has toAccountId but no fromAccountId)
      if (transaction.doneAt.isAfter(currentMonthStart) &&
          transaction.toAccountId != null && 
          transaction.fromAccountId == null) {
        total += transaction.amount.abs();
      }
    }
    return total;
  }

  // Calculate total balance across all accounts
  double _calculateTotalBalance(List accounts) {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
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
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) => Text(
                      'Добрый день, ${userProvider.currentUser!.name}!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Total Balance Card
            Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                final totalBalance = _calculateTotalBalance(accountProvider.accounts);
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
            
            // Last Month Expenses & Current Month Stats
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final lastMonthExpenses = _calculateLastMonthExpenses(transactionProvider.transactions);
                final currentMonthExpenses = _calculateCurrentMonthExpenses(transactionProvider.transactions);
                final currentMonthIncome = _calculateCurrentMonthIncome(transactionProvider.transactions);
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 20, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Прошлый месяц',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Расходы',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(lastMonthExpenses),
                                  style: TextStyle(
                                    fontSize: 20,
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward, size: 20, color: Colors.green[700]),
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
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, size: 20, color: Colors.red[700]),
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
                    SizedBox(height: 16),
                    // Net balance for current month
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Баланс за текущий месяц',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(currentMonthIncome - currentMonthExpenses),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (currentMonthIncome - currentMonthExpenses) >= 0 
                                ? Colors.green[700] 
                                : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
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
