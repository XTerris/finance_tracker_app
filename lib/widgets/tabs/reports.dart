import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';

enum ChartType {
  none,
  bar,
  pie,
  line,
}

enum ReportView {
  summary,
  chartSelection,
  chartView,
  forecast,
}

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ReportView _currentView = ReportView.summary;
  ChartType _selectedChartType = ChartType.none;

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Map<String, double> _calculateStatistics(List transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in transactions) {
      final date = transaction.doneAt;
      if (date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate.add(const Duration(days: 1)))) {
        if (transaction.amount > 0) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount.abs();
        }
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  String _calculateForecast(double totalBalance, double avgMonthlyExpense) {
    if (avgMonthlyExpense <= 0) {
      return 'Расходы отсутствуют, прогноз не требуется';
    }
    
    final months = (totalBalance / avgMonthlyExpense).floor();
    
    if (months == 0) {
      return 'Текущего баланса недостаточно для покрытия средних месячных расходов';
    } else if (months == 1) {
      return 'Общий баланс счетов позволит сохранить текущий уровень расходов в течение 1 месяца';
    } else if (months < 5) {
      return 'Общий баланс счетов позволит сохранить текущий уровень расходов в течение $months месяцев';
    } else {
      return 'Общий баланс счетов позволит сохранить текущий уровень расходов в течение $months месяцев';
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Экспорт отчёта в PDF (функция в разработке)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Отправка отчёта (функция в разработке)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportChartImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Экспорт диаграммы (функция в разработке)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSummaryView() {
    return Consumer3<TransactionProvider, CategoryProvider, AccountProvider>(
      builder: (context, transactionProvider, categoryProvider,
          accountProvider, child) {
        final transactions = transactionProvider.transactions;
        final stats = _calculateStatistics(transactions);
        final accounts = accountProvider.accounts;
        final totalBalance = accounts.fold<double>(
          0,
          (sum, account) => sum + account.balance,
        );

        // Calculate average monthly expense
        final daysDiff = _endDate.difference(_startDate).inDays;
        final monthsDiff = daysDiff / 30.0;
        final avgMonthlyExpense = monthsDiff > 0 ? stats['expense']! / monthsDiff : 0.0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Отчёты',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Period selection
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Период: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статистика',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Всего доходов: ${_formatCurrency(stats['income']!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Всего расходов: ${_formatCurrency(stats['expense']!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Баланс: ${_formatCurrency(stats['balance']!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stats['balance']! >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Charts button
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentView = ReportView.chartSelection;
                    });
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Построить диаграмму'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),

                // Forecast button and card
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentView = ReportView.forecast;
                    });
                  },
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Просмотр прогноза'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),

                // Export options
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Экспорт отчёта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _exportReport,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Сохранить PDF'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _shareReport,
                        icon: const Icon(Icons.share),
                        label: const Text('Отправить в сообщении'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSelectionView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentView = ReportView.summary;
                  });
                },
              ),
              const Text(
                'Выбор типа диаграммы',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartTypeCard(
            ChartType.bar,
            'Столбчатая диаграмма',
            'Расходы по категориям',
            Icons.bar_chart,
          ),
          const SizedBox(height: 16),
          _buildChartTypeCard(
            ChartType.pie,
            'Круговая диаграмма',
            'Распределение расходов',
            Icons.pie_chart,
          ),
          const SizedBox(height: 16),
          _buildChartTypeCard(
            ChartType.line,
            'Линейная диаграмма',
            'Динамика расходов',
            Icons.show_chart,
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeCard(
    ChartType type,
    String title,
    String description,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = type;
          _currentView = ReportView.chartView;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _buildChartView() {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        final transactions = transactionProvider.transactions;
        final categories = categoryProvider.categories;

        // Filter transactions by date range
        final filteredTransactions = transactions.where((t) {
          return t.doneAt.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.doneAt.isBefore(_endDate.add(const Duration(days: 1)));
        }).toList();

        // Calculate expenses by category
        Map<String, double> expensesByCategory = {};
        for (var transaction in filteredTransactions) {
          if (transaction.amount < 0) {
            String categoryName = 'Неизвестная категория';
            
            if (categories.isNotEmpty) {
              try {
                final category = categories.firstWhere(
                  (c) => c.id == transaction.categoryId,
                );
                categoryName = category.name;
              } catch (e) {
                // Category not found, use default name
                categoryName = 'Неизвестная категория';
              }
            }
            
            expensesByCategory[categoryName] =
                (expensesByCategory[categoryName] ?? 0) +
                    transaction.amount.abs();
          }
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _currentView = ReportView.summary;
                        });
                      },
                    ),
                    const Text(
                      'Диаграмма',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getChartTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Simple text-based chart representation
                      if (expensesByCategory.isEmpty)
                        const Text('Нет данных для отображения')
                      else
                        ...expensesByCategory.entries.map((entry) {
                          final total = expensesByCategory.values
                              .fold<double>(0, (sum, val) => sum + val);
                          final percentage = (entry.value / total * 100);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key),
                                    Text(_formatCurrency(entry.value)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _exportChartImage,
                  icon: const Icon(Icons.download),
                  label: const Text('Экспорт изображения'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getChartTitle() {
    switch (_selectedChartType) {
      case ChartType.bar:
        return 'Столбчатая диаграмма расходов по категориям';
      case ChartType.pie:
        return 'Круговая диаграмма распределения расходов';
      case ChartType.line:
        return 'Линейная диаграмма динамики расходов';
      case ChartType.none:
        return 'Диаграмма';
    }
  }

  Widget _buildForecastView() {
    return Consumer2<TransactionProvider, AccountProvider>(
      builder: (context, transactionProvider, accountProvider, child) {
        final transactions = transactionProvider.transactions;
        final accounts = accountProvider.accounts;
        final totalBalance = accounts.fold<double>(
          0,
          (sum, account) => sum + account.balance,
        );

        // Calculate average monthly expense
        final stats = _calculateStatistics(transactions);
        final daysDiff = _endDate.difference(_startDate).inDays;
        final monthsDiff = daysDiff / 30.0;
        final avgMonthlyExpense =
            monthsDiff > 0 ? stats['expense']! / monthsDiff : 0.0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _currentView = ReportView.summary;
                        });
                      },
                    ),
                    const Text(
                      'Прогноз',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Финансовый прогноз',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Текущий баланс: ${_formatCurrency(totalBalance)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Средние расходы в месяц: ${_formatCurrency(avgMonthlyExpense)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _calculateForecast(totalBalance, avgMonthlyExpense),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case ReportView.summary:
        return _buildSummaryView();
      case ReportView.chartSelection:
        return _buildChartSelectionView();
      case ReportView.chartView:
        return _buildChartView();
      case ReportView.forecast:
        return _buildForecastView();
    }
  }
}
