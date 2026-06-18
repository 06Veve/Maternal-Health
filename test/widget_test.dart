import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';

void main() {
  testWidgets('BZButton displays its label and handles taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BZButton(label: 'Continue', onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(tapped, isTrue);
  });
}
