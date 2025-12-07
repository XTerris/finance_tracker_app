import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/account.dart';
import '../../../models/money.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/goal_provider.dart';
import 'add_bottom_sheet_base.dart';

// Форма для редактирования существующего счета
class EditAccountBottomSheet extends AddBottomSheetBase {
  final Account account;

  const EditAccountBottomSheet({super.key, required this.account});

  @override
  State<EditAccountBottomSheet> createState() => _EditAccountBottomSheetState();
}

class _EditAccountBottomSheetState
    extends AddBottomSheetBaseState<EditAccountBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    // Заполнение полей текущими значениями счета
    _nameController = TextEditingController(text: widget.account.name);
    _balanceController = TextEditingController(
      text: widget.account.balance.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  String get title => 'Изменить счёт';

  @override
  String get submitButtonText => 'Сохранить изменения';

  // Сохранение изменений счета
  @override
  Future<void> submitForm() async {
    final navigator = Navigator.of(context);

    try {
      final accountProvider = context.read<AccountProvider>();
      final goalProvider = context.read<GoalProvider>();

      await accountProvider.updateAccount(
        id: widget.account.id,
        name: _nameController.text.trim(),
        balance: Money.rub(double.parse(_balanceController.text.trim())),
      );

      await goalProvider.update();

      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Счёт успешно обновлён')));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название счёта',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance_wallet),
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
          controller: _balanceController,
          decoration: const InputDecoration(
            labelText: 'Баланс',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.onetwothree),
            suffixText: '₽',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Пожалуйста, введите баланс';
            }
            final balance = double.tryParse(value.trim());
            if (balance == null) {
              return 'Пожалуйста, введите корректное число';
            }
            if (balance < 0) {
              return 'Баланс счёта не может быть отрицательным';
            }
            return null;
          },
        ),
      ],
    );
  }
}
