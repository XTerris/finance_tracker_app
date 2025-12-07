import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/goal_provider.dart';
import 'add_bottom_sheet_base.dart';

// Форма для редактирования существующей транзакции
class EditTransactionBottomSheet extends AddBottomSheetBase {
  final Transaction transaction;

  const EditTransactionBottomSheet({super.key, required this.transaction});

  @override
  State<EditTransactionBottomSheet> createState() =>
      _EditTransactionBottomSheetState();
}

class _EditTransactionBottomSheetState
    extends AddBottomSheetBaseState<EditTransactionBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Заполнение полей текущими значениями транзакции
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _selectedCategoryId = widget.transaction.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
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
  String get title => 'Изменить операцию';

  @override
  String get submitButtonText => 'Сохранить изменения';

  @override
  Future<void> submitForm() async {
    if (_selectedCategoryId == null) {
      showSnackBar('Пожалуйста, выберите категорию');
      return;
    }

    final navigator = Navigator.of(context);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      final goalProvider = context.read<GoalProvider>();

      final amount = double.parse(_amountController.text.trim());

      await transactionProvider.updateTransaction(
        id: widget.transaction.id,
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId,
        amount: amount,
      );

      await accountProvider.update();
      await goalProvider.update();

      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Операция успешно обновлена')),
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

  @override
  Widget buildFormContent(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

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
                  suffixText: '₽',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите сумму';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Пожалуйста, введите корректную сумму';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value:
                    categoryProvider.categories.any(
                          (c) => c.id == _selectedCategoryId,
                        )
                        ? _selectedCategoryId
                        : null,
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
            ],
          );
        }
      }
