# PlateBase - Базовый класс для карточек

## Обзор

`PlateBase` - это абстрактный базовый класс для создания карточек (plates) в приложении. Он обеспечивает единое место для управления общими стилями всех карточек.

## Преимущества

### 1. Централизованное управление стилями
Все общие стили (цвет фона, тени, скругления, отступы) определены в одном месте - классе `PlateBase`. Это означает, что изменение стиля в одном месте автоматически применяется ко всем карточкам.

### 2. Уменьшение дублирования кода
До рефакторинга классы `TransactionPlate` и `AccountPlate` содержали идентичный код для создания контейнера с декорацией. Теперь этот код находится в базовом классе.

### 3. Простота расширения
Новые типы карточек легко создавать, наследуясь от `PlateBase` и реализуя только метод `buildContent()`.

### 4. Гибкость кастомизации
Методы `getDecoration()`, `getPadding()`, `getMargin()` могут быть переопределены в наследниках для создания кастомных стилей (см. `custom_styled_plate_example.dart`).

## Использование

### Существующие классы

#### TransactionPlate
```dart
class TransactionPlate extends PlateBase {
  final Transaction transaction;
  const TransactionPlate({super.key, required this.transaction, super.margin});
  
  @override
  Widget buildContent(BuildContext context) {
    // Содержимое карточки транзакции
    return Column(...);
  }
}
```

#### AccountPlate
```dart
class AccountPlate extends PlateBase {
  final Account account;
  const AccountPlate({super.key, required this.account, super.margin});
  
  @override
  Widget buildContent(BuildContext context) {
    // Содержимое карточки счёта
    return Column(...);
  }
}
```

### Создание новой карточки

Чтобы создать новый тип карточки:

1. Наследуйтесь от `PlateBase`
2. Реализуйте метод `buildContent()`
3. При необходимости переопределите методы стилизации

```dart
class MyCustomPlate extends PlateBase {
  final MyData data;
  
  const MyCustomPlate({super.key, required this.data, super.margin});
  
  @override
  Widget buildContent(BuildContext context) {
    return Text(data.title);
  }
}
```

### Изменение глобальных стилей

Чтобы изменить стиль всех карточек в приложении, просто отредактируйте методы в классе `PlateBase`:

```dart
// В plate_base.dart
BoxDecoration getDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.secondaryContainer,
    borderRadius: BorderRadius.circular(20), // Изменили с 16 на 20
    // ...
  );
}
```

### Создание карточки с кастомным стилем

Если нужна карточка с уникальным стилем, переопределите нужные методы:

```dart
class HighlightedPlate extends PlateBase {
  // ...
  
  @override
  BoxDecoration getDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.yellow.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.yellow, width: 2),
    );
  }
}
```

## Структура класса

### Поля
- `margin: EdgeInsetsGeometry?` - необязательные внешние отступы карточки

### Методы для переопределения
- `Widget buildContent(BuildContext context)` - **обязательный**, содержимое карточки
- `BoxDecoration getDecoration(BuildContext context)` - декорация контейнера
- `EdgeInsetsGeometry getPadding()` - внутренние отступы
- `EdgeInsetsGeometry getMargin()` - внешние отступы

### Основной метод
- `Widget build(BuildContext context)` - реализован в базовом классе, создаёт контейнер с общими стилями

## Тестирование

См. `test/plate_base_test.dart` для примеров тестов.
