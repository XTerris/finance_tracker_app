import 'package:finance_tracker_app/providers/account_provider.dart';
import 'package:finance_tracker_app/providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'tab_widgets/account_plate.dart';
import 'tab_widgets/add_account_bottom_sheet.dart';
import 'tab_base.dart';

// Вкладка для управления счетами и финансовыми целями
class AccountsAndGoalsTab extends TabBase {
  const AccountsAndGoalsTab({super.key});

  @override
  State<AccountsAndGoalsTab> createState() => _AccountsAndGoalsTabState();
}

class _AccountsAndGoalsTabState extends State<AccountsAndGoalsTab> {
  // Форматирование баланса в российские рубли
  String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(balance);
  }

  // Открытие формы добавления нового счета
  void _showAddAccountBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddAccountBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final accountProvider = context.read<AccountProvider>();
          final goalProvider = context.read<GoalProvider>();

          await accountProvider.init();
          await goalProvider.init();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Накопления и цели',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Consumer<AccountProvider>(
                  builder: (context, accountProvider, child) {
                    final accounts = accountProvider.accounts;
                    final totalBalance = accounts.fold<double>(
                      0,
                      (sum, account) => sum + account.balance.amount,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Общий баланс: ${_formatBalance(totalBalance)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (accounts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Нет счетов',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ...accounts.map(
                            (account) => AccountPlate(account: account),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountBottomSheet,
        tooltip: 'Создать счёт',
        child: const Icon(Icons.add),
      ),
    );
  }
}
