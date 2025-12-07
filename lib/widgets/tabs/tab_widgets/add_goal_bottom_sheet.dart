import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/money.dart';
import '../../../providers/goal_provider.dart';
import '../../../models/account.dart';
import 'add_bottom_sheet_base.dart';

// Форма для создания новой финансовой цели для счета
class AddGoalBottomSheet extends AddBottomSheetBase {
  final Account account;

  const AddGoalBottomSheet({super.key, required this.account});

  @override
  State<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState
    extends AddBottomSheetBaseState<AddGoalBottomSheet> {
  final _targetAmountController = TextEditingController();
  DateTime? _selectedDeadline;

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  // Выбор срока достижения цели
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  String get title => 'Создать цель';

  @override
  String get submitButtonText => 'Создать цель';

  @override
  Future<void> submitForm() async {
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дедлайн'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final goalProvider = context.read<GoalProvider>();

      await goalProvider.addGoal(
        accountId: widget.account.id,
        targetAmount: Money.rub(double.parse(_targetAmountController.text.trim())),
        deadline: _selectedDeadline!,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Цель успешно создана')));
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
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Дедлайн',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedDeadline == null
                  ? 'Выберите дату'
                  : _formatDate(_selectedDeadline!),
              style: TextStyle(
                color: _selectedDeadline == null ? Colors.grey[600] : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'для счёта: ${widget.account.name}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildFormContent(context),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(submitButtonText),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
