import 'package:flutter/material.dart';
import 'package:finance_tracker_app/widgets/tabs/tab_widgets/plate_base.dart';

/// Пример создания кастомного стиля для карточек
/// путем переопределения методов базового класса PlateBase
class CustomStyledPlate extends PlateBase {
  final Widget child;

  const CustomStyledPlate({
    super.key,
    required this.child,
    super.margin,
  });

  @override
  Widget buildContent(BuildContext context) {
    return child;
  }

  // Пример переопределения стилей декорации
  @override
  BoxDecoration getDecoration(BuildContext context) {
    return BoxDecoration(
      // Используем другой цвет
      color: Theme.of(context).colorScheme.primaryContainer,
      // Используем другой радиус скругления
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          // Более заметная тень
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Пример переопределения внутренних отступов
  @override
  EdgeInsetsGeometry getPadding() {
    return const EdgeInsets.all(24);
  }

  // Пример переопределения внешних отступов
  @override
  EdgeInsetsGeometry getMargin() {
    return margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
}
