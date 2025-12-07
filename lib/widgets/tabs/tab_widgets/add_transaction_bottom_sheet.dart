import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/money.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/goal_provider.dart';
import 'add_bottom_sheet_base.dart';

// Типы транзакций для выбора в форме
enum TransactionType { expense, income, transfer }

// Форма для добавления новой транзакции
class AddTransactionBottomSheet extends AddBottomSheetBase {
  const AddTransactionBottomSheet({super.key});

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends AddBottomSheetBaseState<AddTransactionBottomSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  int? _selectedCategoryId;
  TransactionType _transactionType = TransactionType.expense;
  int? _selectedFromAccountId; // Счет списания
  int? _selectedToAccountId; // Счет зачисления
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Выбор даты транзакции
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Выбор времени транзакции
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  // Создание новой категории через диалог
  Future<void> _createNewCategory(BuildContext context) async {
    final categoryNameController = TextEditingController();
    final categoryProvider = context.read<CategoryProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Новая категория'),
            content: TextField(
              controller: categoryNameController,
              decoration: const InputDecoration(
                labelText: 'Название категории',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = categoryNameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop(name);
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await categoryProvider.addCategory(result);

        if (!mounted) return;

        if (categoryProvider.categories.isNotEmpty) {
          final newCategory = categoryProvider.categories.last;
          setState(() {
            _selectedCategoryId = newCategory.id;
          });
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Категория "$result" создана')),
        );
      } catch (e) {
        if (!mounted) return;
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    categoryNameController.dispose();
  }

  @override
  String get title => 'Добавить операцию';

  @override
  String get submitButtonText => 'Добавить операцию';

  // Валидация и отправка формы создания транзакции
  @override
  Future<void> submitForm() async {
    if (_selectedCategoryId == null) {
      showSnackBar('Пожалуйста, выберите категорию');
      return;
    }

    // Проверка выбора счетов в зависимости от типа транзакции
    if (_transactionType == TransactionType.expense ||
        _transactionType == TransactionType.transfer) {
      if (_selectedFromAccountId == null) {
        showSnackBar('Пожалуйста, выберите счет отправления');
        return;
      }
    }
    if (_transactionType == TransactionType.income ||
        _transactionType == TransactionType.transfer) {
      if (_selectedToAccountId == null) {
        showSnackBar('Пожалуйста, выберите счет назначения');
        return;
      }
    }

    final navigator = Navigator.of(context);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      final goalProvider = context.read<GoalProvider>();

      // Создание транзакции и обновление связанных данных
      await transactionProvider.addTransaction(
        title: _titleController.text.trim(),
        amount: Money.rub(double.parse(_amountController.text.trim())),
        categoryId: _selectedCategoryId!,
        fromAccountId: _selectedFromAccountId,
        toAccountId: _selectedToAccountId,
        doneAt: _selectedDate,
      );

      await accountProvider.update();
      await goalProvider.update();

      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Операция успешно добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Построение содержимого формы
  @override
  Widget buildFormContent(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final accountProvider = context.watch<AccountProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.onetwothree),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите сумму';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  if (amount <= 0) {
                    return 'Сумма должна быть больше нуля';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  ...categoryProvider.categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Создать новую категорию'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == -1) {
                    _createNewCategory(context);
                  } else {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value == -1) {
                    return 'Пожалуйста, выберите категорию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<TransactionType>(
                value: _transactionType,
                decoration: const InputDecoration(
                  labelText: 'Тип операции',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: const [
                  DropdownMenuItem<TransactionType>(
                    value: TransactionType.expense,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Списание'),
                      ],
                    ),
                  ),
                  DropdownMenuItem<TransactionType>(
                    value: TransactionType.income,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Зачисление'),
                      ],
                    ),
                  ),
                  DropdownMenuItem<TransactionType>(
                    value: TransactionType.transfer,
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Перевод между счетами'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _transactionType = value;
                      _selectedFromAccountId = null;
                      _selectedToAccountId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_transactionType != TransactionType.income) ...[
                DropdownButtonFormField<int>(
                  value: _selectedFromAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Счет списания',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call_made),
                  ),
                  items:
                      accountProvider.accounts
                          .where(
                            (account) => account.id != _selectedToAccountId,
                          )
                          .map((account) {
                            return DropdownMenuItem<int>(
                              value: account.id,
                              child: Text(
                                '${account.name} (${account.balance.amount.toStringAsFixed(2)})',
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFromAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (_transactionType == TransactionType.expense ||
                        _transactionType == TransactionType.transfer) {
                      if (value == null) {
                        return 'Пожалуйста, выберите счет списания';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_transactionType != TransactionType.expense) ...[
                DropdownButtonFormField<int>(
                  value: _selectedToAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Счет зачисления',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call_made),
                  ),
                  items:
                      accountProvider.accounts
                          .where(
                            (account) => account.id != _selectedFromAccountId,
                          )
                          .map((account) {
                            return DropdownMenuItem<int>(
                              value: account.id,
                              child: Text(
                                '${account.name} (${account.balance.amount.toStringAsFixed(2)})',
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedToAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (_transactionType == TransactionType.income ||
                        _transactionType == TransactionType.transfer) {
                      if (value == null) {
                        return 'Пожалуйста, выберите счет зачисления';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('dd.MM.yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(DateFormat('HH:mm').format(_selectedDate)),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      }
