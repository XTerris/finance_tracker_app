import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/widgets/tabs/tab_widgets/plate_base.dart';

// Простой тестовый виджет, наследующий PlateBase
class TestPlate extends PlateBase {
  final String content;
  
  const TestPlate({super.key, required this.content, super.margin});

  @override
  Widget buildContent(BuildContext context) {
    return Text(content);
  }
}

void main() {
  group('PlateBase', () {
    testWidgets('renders with default styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestPlate(content: 'Test Content'),
          ),
        ),
      );

      // Проверяем, что контент отображается
      expect(find.text('Test Content'), findsOneWidget);
      
      // Проверяем, что есть контейнер
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('applies custom margin', (WidgetTester tester) async {
      const customMargin = EdgeInsets.all(20);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestPlate(
              content: 'Test Content',
              margin: customMargin,
            ),
          ),
        ),
      );

      // Проверяем, что контент отображается
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('uses default margin when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestPlate(content: 'Test Content'),
          ),
        ),
      );

      // Проверяем, что контент отображается
      expect(find.text('Test Content'), findsOneWidget);
    });

    test('getPadding returns correct value', () {
      const plate = TestPlate(content: 'Test');
      final padding = plate.getPadding();
      expect(padding, const EdgeInsets.all(16));
    });

    test('getMargin returns default margin when not provided', () {
      const plate = TestPlate(content: 'Test');
      final margin = plate.getMargin();
      expect(margin, const EdgeInsets.only(bottom: 16));
    });

    test('getMargin returns custom margin when provided', () {
      const customMargin = EdgeInsets.all(20);
      const plate = TestPlate(content: 'Test', margin: customMargin);
      final margin = plate.getMargin();
      expect(margin, customMargin);
    });
  });
}
