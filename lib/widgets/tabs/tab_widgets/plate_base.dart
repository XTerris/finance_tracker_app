import 'package:flutter/material.dart';

/// Базовый класс для карточек (plates) с общими стилями
abstract class PlateBase extends StatelessWidget {
  /// Отступы вокруг карточки
  final EdgeInsetsGeometry? margin;

  const PlateBase({super.key, this.margin});

  /// Метод для построения содержимого карточки
  /// Должен быть реализован в дочерних классах
  Widget buildContent(BuildContext context);

  /// Общие стили для контейнера карточки
  BoxDecoration getDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Отступы внутри карточки
  EdgeInsetsGeometry getPadding() {
    return const EdgeInsets.all(16);
  }

  /// Отступы вокруг карточки
  EdgeInsetsGeometry getMargin() {
    return margin ?? const EdgeInsets.only(bottom: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: getPadding(),
      margin: getMargin(),
      decoration: getDecoration(context),
      child: buildContent(context),
    );
  }
}
