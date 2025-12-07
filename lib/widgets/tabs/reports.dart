import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'dart:io';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import 'tab_base.dart';

// Типы диаграмм для визуализации отчетов
enum ChartType { none, bar, pie, line }

// Режимы отображения в разделе отчетов
enum ReportView { summary, chartSelection, chartView, forecast }

// Вкладка отчетов с аналитикой и графиками
class ReportsTab extends TabBase {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ReportView _currentView = ReportView.summary;
  ChartType _selectedChartType = ChartType.none;
  final GlobalKey _chartKey = GlobalKey();

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

  // Выбор диапазона дат для формирования отчета
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
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
        final hasFromAccount = transaction.fromAccountId != null;
        final hasToAccount = transaction.toAccountId != null;

        if (hasToAccount && !hasFromAccount) {
          totalIncome += transaction.amount.amount;
        } else if (hasFromAccount && !hasToAccount) {
          totalExpense += transaction.amount.amount;
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

  String _getChartTypeName() {
    switch (_selectedChartType) {
      case ChartType.pie:
        return 'pie';
      case ChartType.bar:
        return 'bar';
      case ChartType.line:
        return 'line';
      case ChartType.none:
        return 'unknown';
    }
  }

  Future<String?> _getSaveDirectory() async {
    if (kIsWeb) {
      return null;
    }

    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else if (await Permission.photos.request().isGranted) {
          status = PermissionStatus.granted;
        } else if (await Permission.storage.request().isGranted) {
          status = PermissionStatus.granted;
        }
      }

      if (!status.isGranted) {
        throw Exception('Требуется разрешение на сохранение файлов');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Не удалось получить доступ к хранилищу');
      }

      final parts = directory.path.split('/');
      final storageIndex = parts.indexOf('Android');
      if (storageIndex > 0) {
        final basePath = parts.sublist(0, storageIndex).join('/');
        final picturesPath = '$basePath/Pictures/Finance Tracker';
        
        final picturesDir = Directory(picturesPath);
        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }
        
        return picturesPath;
      }
      
      return directory.path;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  void _exportChartImage() async {
    try {
      if (_selectedChartType == ChartType.none) {
        throw Exception('Сначала выберите тип диаграммы');
      }

      final renderObject = _chartKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Не удалось найти диаграмму для экспорта');
      }

      ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Не удалось преобразовать изображение');
      }

      var pngBytes = byteData.buffer.asUint8List();
      var decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      var jpegBytes = img.encodeJpg(decodedImage, quality: 90);

      final directoryPath = await _getSaveDirectory();
      if (directoryPath == null) {
        throw Exception('Не удалось определить путь для сохранения');
      }
      
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final chartTypeName = _getChartTypeName();
      final fileName = 'chart_${chartTypeName}_$timestamp.jpg';
      final filePath = '$directoryPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(jpegBytes);

      if (!mounted) return;
      
      final locationHint = Platform.isAndroid 
          ? 'Pictures/Finance Tracker/$fileName'
          : fileName;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Диаграмма сохранена: $locationHint'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryView() {
    return Consumer3<TransactionProvider, CategoryProvider, AccountProvider>(
      builder: (
        context,
        transactionProvider,
        categoryProvider,
        accountProvider,
        child,
      ) {
        final transactions = transactionProvider.transactions;
        final stats = _calculateStatistics(transactions);

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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
            ChartType.pie,
            'Круговая диаграмма',
            'Расходы по категориям за выбранный период',
            Icons.pie_chart,
          ),
          const SizedBox(height: 16),
          _buildChartTypeCard(
            ChartType.bar,
            'Столбчатая диаграмма',
            'Расходы по дням',
            Icons.bar_chart,
          ),
          const SizedBox(height: 16),
          _buildChartTypeCard(
            ChartType.line,
            'Линейная диаграмма',
            'Расходы по дням',
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
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  int _calculateOptimalGroupDays(int totalDays) {
    if (totalDays <= 14) {
      return 1;
    }

    for (int groupDays in [2, 3, 4, 5, 6, 7, 10, 14, 21, 28, 30]) {
      final numBars = (totalDays / groupDays).ceil();
      if (numBars >= 5 && numBars <= 14) {
        return groupDays;
      }
    }

    return (totalDays / 10).ceil();
  }

  Widget _buildChartView() {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        final transactions = transactionProvider.transactions;
        final categories = categoryProvider.categories;

        final filteredTransactions =
            transactions.where((t) {
              return t.doneAt.isAfter(
                    _startDate.subtract(const Duration(days: 1)),
                  ) &&
                  t.doneAt.isBefore(_endDate.add(const Duration(days: 1)));
            }).toList();

        Map<String, double> chartData = {};
        Map<String, String> chartDataRanges = {};

        if (_selectedChartType == ChartType.pie) {
          for (var transaction in filteredTransactions) {
            final hasFromAccount = transaction.fromAccountId != null;
            final hasToAccount = transaction.toAccountId != null;

            if (hasFromAccount && !hasToAccount) {
              String categoryName = 'Неизвестная категория';

              if (categories.isNotEmpty) {
                try {
                  final category = categories.firstWhere(
                    (c) => c.id == transaction.categoryId,
                  );
                  categoryName = category.name;
                } catch (e) {
                  categoryName = 'Неизвестная категория';
                }
              }

              chartData[categoryName] =
                  (chartData[categoryName] ?? 0) + transaction.amount.amount;
            }
          }
        } else {
          final Map<String, double> allDaysMap = {};
          DateTime currentDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
          );
          final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

          while (currentDate.isBefore(endDate) ||
              currentDate.isAtSameMomentAs(endDate)) {
            final dateKey = DateFormat('dd.MM.yyyy').format(currentDate);
            allDaysMap[dateKey] = 0.0;
            currentDate = currentDate.add(const Duration(days: 1));
          }

          for (var transaction in filteredTransactions) {
            final hasFromAccount = transaction.fromAccountId != null;
            final hasToAccount = transaction.toAccountId != null;

            if (hasFromAccount && !hasToAccount) {
              final dateKey = DateFormat(
                'dd.MM.yyyy',
              ).format(transaction.doneAt);
              if (allDaysMap.containsKey(dateKey)) {
                allDaysMap[dateKey] = allDaysMap[dateKey]! + transaction.amount.amount;
              }
            }
          }

          final sortedEntries =
              allDaysMap.entries.toList()..sort((a, b) {
                final dateA = DateFormat('dd.MM.yyyy').parse(a.key);
                final dateB = DateFormat('dd.MM.yyyy').parse(b.key);
                return dateA.compareTo(dateB);
              });

          final totalDays = sortedEntries.length;
          final groupDays = _calculateOptimalGroupDays(totalDays);

          if (groupDays == 1) {
            chartData = Map.fromEntries(sortedEntries);
            for (var entry in sortedEntries) {
              final date = DateFormat('dd.MM.yyyy').parse(entry.key);
              chartDataRanges[entry.key] = DateFormat(
                'dd.MM.yyyy',
              ).format(date);
            }
          } else {
            final Map<String, double> groupedData = {};
            final Map<String, DateTime> periodStarts = {};
            final Map<String, DateTime> periodEnds = {};

            DateTime? periodStart;
            String? periodKey;
            int daysInCurrentPeriod = 0;

            for (int i = 0; i < sortedEntries.length; i++) {
              final entry = sortedEntries[i];
              final date = DateFormat('dd.MM.yyyy').parse(entry.key);

              if (periodStart == null || daysInCurrentPeriod >= groupDays) {
                periodStart = date;
                periodKey = DateFormat('dd.MM').format(periodStart);
                periodStarts[periodKey] = periodStart;
                daysInCurrentPeriod = 0;
                groupedData[periodKey] = 0.0;
              }

              groupedData[periodKey!] = groupedData[periodKey]! + entry.value;
              periodEnds[periodKey] = date;
              daysInCurrentPeriod++;
            }

            chartData = groupedData;

            periodStarts.forEach((key, start) {
              final end = periodEnds[key]!;
              if (start == end) {
                chartDataRanges[key] = DateFormat('dd.MM.yyyy').format(start);
              } else {
                chartDataRanges[key] =
                    '${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}';
              }
            });
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
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
                        if (chartData.isEmpty)
                          const Text('Нет данных для отображения')
                        else if (_selectedChartType == ChartType.line)
                          _buildLineChart(chartData, chartDataRanges)
                        else if (_selectedChartType == ChartType.bar)
                          _buildBarChart(chartData, chartDataRanges)
                        else if (_selectedChartType == ChartType.pie)
                          _buildPieChart(chartData)
                        else
                          const Text('Неизвестный тип диаграммы'),
                      ],
                    ),
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
      case ChartType.pie:
        return 'Круговая диаграмма расходов по категориям';
      case ChartType.bar:
        return 'Столбчатая диаграмма расходов по дням';
      case ChartType.line:
        return 'Линейная диаграмма расходов по дням';
      case ChartType.none:
        return 'Диаграмма';
    }
  }

  Widget _buildLineChart(
    Map<String, double> chartData,
    Map<String, String> chartDataRanges,
  ) {
    if (chartData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет данных для отображения'),
        ),
      );
    }

    final List<FlSpot> spots = [];
    final List<String> labels = [];
    final List<double> amounts = [];

    chartData.forEach((dateStr, amount) {
      labels.add(dateStr);
      amounts.add(amount);
    });

    for (int i = 0; i < labels.length; i++) {
      spots.add(FlSpot(i.toDouble(), amounts[i]));
    }

    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final minY = amounts.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY > 0 ? maxY / 5 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const Text('');
                      }
                      final label = labels[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 0 ? maxY / 5 : 1,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatCurrency(value),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: minY > 0 ? 0 : minY * 1.1,
              maxY: maxY * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= labels.length) {
                        return null;
                      }
                      final label = labels[index];
                      final range = chartDataRanges[label] ?? label;
                      final amount = spot.y;
                      return LineTooltipItem(
                        '$range\n${_formatCurrency(amount)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatChip('Всего периодов', labels.length.toString()),
            _buildStatChip(
              'Средние расходы',
              _formatCurrency(amounts.reduce((a, b) => a + b) / amounts.length),
            ),
            _buildStatChip('Максимум', _formatCurrency(maxY)),
            _buildStatChip('Минимум', _formatCurrency(minY)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildBarChart(
    Map<String, double> chartData,
    Map<String, String> chartDataRanges,
  ) {
    if (chartData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет данных для отображения'),
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> labels = [];
    final List<double> amounts = [];

    chartData.forEach((label, amount) {
      labels.add(label);
      amounts.add(amount);
    });

    for (int i = 0; i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amounts[i],
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final minY = amounts.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 5 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const Text('');
                      }
                      final label = labels[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 0 ? maxY / 5 : 1,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatCurrency(value),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex < 0 || groupIndex >= labels.length) {
                      return null;
                    }
                    final label = labels[groupIndex];
                    final range = chartDataRanges[label] ?? label;
                    final amount = rod.toY;
                    return BarTooltipItem(
                      '$range\n${_formatCurrency(amount)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatChip('Всего периодов', labels.length.toString()),
            _buildStatChip(
              'Средние расходы',
              _formatCurrency(amounts.reduce((a, b) => a + b) / amounts.length),
            ),
            _buildStatChip('Максимум', _formatCurrency(maxY)),
            _buildStatChip('Минимум', _formatCurrency(minY)),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> chartData) {
    if (chartData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет данных для отображения'),
        ),
      );
    }

    final total = chartData.values.fold<double>(0, (sum, val) => sum + val);

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    int colorIndex = 0;
    chartData.forEach((category, amount) {
      final percentage = (amount / total * 100);
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          color: colors[colorIndex % colors.length],
          radius: 110,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children:
              chartData.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final color = colors[index % colors.length];
                final percentage = (mapEntry.value / total * 100);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mapEntry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_formatCurrency(mapEntry.value)} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildForecastView() {
    return Consumer2<TransactionProvider, AccountProvider>(
      builder: (context, transactionProvider, accountProvider, child) {
        final transactions = transactionProvider.transactions;
        final accounts = accountProvider.accounts;
        final totalBalance = accounts.fold<double>(
          0,
          (sum, account) => sum + account.balance.amount,
        );

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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
