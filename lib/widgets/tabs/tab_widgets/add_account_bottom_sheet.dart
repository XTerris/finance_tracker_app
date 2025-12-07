import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/money.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/goal_provider.dart';
import 'add_bottom_sheet_base.dart';

// Форма для добавления нового счета
class AddAccountBottomSheet extends AddBottomSheetBase {
  const AddAccountBottomSheet({super.key});

  @override
  State<AddAccountBottomSheet> createState() => _AddAccountBottomSheetState();
}

class _AddAccountBottomSheetState
    extends AddBottomSheetBaseState<AddAccountBottomSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  String get title => 'Создать счёт';

  @override
  String get submitButtonText => 'Создать счёт';

  // Создание нового счета с начальным балансом
  @override
  Future<void> submitForm() async {
    try {
      final accountProvider = context.read<AccountProvider>();
      final goalProvider = context.read<GoalProvider>();

      await accountProvider.addAccount(
        _nameController.text.trim(),
        Money.rub(double.parse(_balanceController.text.trim())),
      );

      await goalProvider.update();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Счёт успешно создан')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название счёта',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Пожалуйста, введите название счёта';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _balanceController,
          decoration: const InputDecoration(
            labelText: 'Начальный баланс',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.onetwothree),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Пожалуйста, введите начальный баланс';
            }
            final balance = double.tryParse(value.trim());
            if (balance == null) {
              return 'Пожалуйста, введите корректное число';
            }
            if (balance < 0) {
              return 'Начальный баланс не может быть отрицательным';
            }
            return null;
          },
        ),
      ],
    );
  }
}
