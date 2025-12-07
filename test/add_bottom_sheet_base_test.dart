import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/widgets/tabs/tab_widgets/add_bottom_sheet_base.dart';

// Simple test widget extending AddBottomSheetBase
class TestBottomSheet extends AddBottomSheetBase {
  const TestBottomSheet({super.key});

  @override
  State<TestBottomSheet> createState() => _TestBottomSheetState();
}

class _TestBottomSheetState extends AddBottomSheetBaseState<TestBottomSheet> {
  @override
  String get title => 'Test Title';

  @override
  String get submitButtonText => 'Submit Test';

  @override
  Future<void> submitForm() async {
    // Simple implementation for testing
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.of(context).pop('success');
    }
  }

  @override
  Widget buildFormContent(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Test Field'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required field';
            }
            return null;
          },
        ),
      ],
    );
  }
}

void main() {
  group('AddBottomSheetBase', () {
    testWidgets('renders with title and close button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('Test Title'), findsOneWidget);

      // Verify close button is displayed
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify submit button is displayed
      expect(find.text('Submit Test'), findsOneWidget);
    });

    testWidgets('renders form content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify form content is displayed
      expect(find.text('Test Field'), findsOneWidget);
    });

    testWidgets('closes when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is open
      expect(find.text('Test Title'), findsOneWidget);

      // Tap the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify bottom sheet is closed
      expect(find.text('Test Title'), findsNothing);
    });

    testWidgets('validates form before submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Try to submit form without filling it
      await tester.tap(find.text('Submit Test'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Required field'), findsOneWidget);

      // Bottom sheet should not close
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows loading indicator during submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill the field
      await tester.enterText(find.byType(TextFormField), 'Test Value');

      // Tap submit button
      await tester.tap(find.text('Submit Test'));
      await tester.pump(); // Only one pump to see the loading indicator

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();
    });

    testWidgets('submits form successfully when valid',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    builder: (_) => const TestBottomSheet(),
                  );
                  if (result == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Success')),
                    );
                  }
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill the field
      await tester.enterText(find.byType(TextFormField), 'Test Value');

      // Tap submit button
      await tester.tap(find.text('Submit Test'));
      await tester.pumpAndSettle();

      // Bottom sheet should close
      expect(find.text('Test Title'), findsNothing);
    });
  });
}
