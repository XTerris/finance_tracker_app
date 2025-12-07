import 'package:flutter/material.dart';

/// Базовый класс для всех bottom sheet виджетов (Add/Edit)
/// Предоставляет общую структуру и функциональность
abstract class AddBottomSheetBase extends StatefulWidget {
  const AddBottomSheetBase({super.key});
}

abstract class AddBottomSheetBaseState<T extends AddBottomSheetBase>
    extends State<T> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  /// Заголовок bottom sheet
  String get title;

  /// Основное содержимое формы
  Widget buildFormContent(BuildContext context);

  /// Логика отправки формы
  Future<void> submitForm();

  /// Текст кнопки отправки
  String get submitButtonText;

  /// Устанавливает состояние загрузки
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  /// Показывает SnackBar с сообщением
  void showSnackBar(String message, {bool isError = false}) {
    final scaffoldContext =
        context.findAncestorStateOfType<ScaffoldState>()?.context;
    if (scaffoldContext != null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    }
  }

  /// Обработчик отправки формы с обработкой ошибок
  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setLoading(true);

    try {
      await submitForm();
    } finally {
      setLoading(false);
    }
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
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
