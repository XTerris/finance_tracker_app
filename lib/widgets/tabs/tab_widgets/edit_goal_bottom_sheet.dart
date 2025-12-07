import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/goal.dart';
import '../../../models/money.dart';
import '../../../providers/goal_provider.dart';
import 'add_bottom_sheet_base.dart';

// Форма для редактирования существующей финансовой цели
class EditGoalBottomSheet extends AddBottomSheetBase {
  final Goal goal;

  const EditGoalBottomSheet({super.key, required this.goal});

  @override
  State<EditGoalBottomSheet> createState() => _EditGoalBottomSheetState();
}

class _EditGoalBottomSheetState
    extends AddBottomSheetBaseState<EditGoalBottomSheet> {
  late final TextEditingController _targetAmountController;
  late DateTime _selectedDeadline;

  @override
  void initState() {
    super.initState();
    // Заполнение полей текущими значениями цели
    _targetAmountController = TextEditingController(
      text: widget.goal.targetAmount.amount.toStringAsFixed(2),
    );
    _selectedDeadline = widget.goal.deadline;
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  // Выбор нового срока достижения цели
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  String get title => 'Изменить цель';

  @override
  String get submitButtonText => 'Сохранить изменения';

  @override
  Future<void> submitForm() async {
    final navigator = Navigator.of(context);

    try {
      final goalProvider = context.read<GoalProvider>();

      await goalProvider.updateGoal(
        id: widget.goal.id,
        targetAmount: Money.rub(double.parse(_targetAmountController.text.trim())),
        deadline: _selectedDeadline,
      );

      if (mounted) {
        navigator.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Цель успешно обновлена')));
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
          controller: _targetAmountController,
          decoration: const InputDecoration(
            labelText: 'Целевая сумма',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.onetwothree),
            suffixText: '₽',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Пожалуйста, введите целевую сумму';
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
        OutlinedButton.icon(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.calendar_today),
          label: Text(
            'Дедлайн: ${DateFormat('dd.MM.yyyy').format(_selectedDeadline)}',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}
