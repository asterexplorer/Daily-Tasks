import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/task_tile.dart';
import 'package:app/models/task.dart';

void main() {
  testWidgets('TaskTile has a visible delete button',
      (WidgetTester tester) async {
    final task = Task(
      id: '1',
      title: 'Test Task',
      timestamp: DateTime.now(),
    );
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onCheckboxChanged: (_) {},
            onDelete: () {
              deleted = true;
            },
          ),
        ),
      ),
    );

    // Verify the delete icon button is present
    expect(find.byIcon(Icons.delete_rounded), findsOneWidget);

    // Tap the delete button
    await tester.tap(find.byIcon(Icons.delete_rounded));
    await tester.pump();

    // Verify callback was called
    expect(deleted, isTrue);
  });
}
