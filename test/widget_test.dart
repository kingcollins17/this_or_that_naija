import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:this_or_that_naija/widgets/choice_panel.dart';

void main() {
  testWidgets('ChoicePanel displays option text and banter properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChoicePanel(
            text: 'Party Jollof',
            banter: 'Bottom pot or nothing',
            percentage: 65.5,
            isSelected: false,
            hasVoted: true,
            baseColor: Color(0xFF007A3D),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Party Jollof'), findsOneWidget);
    expect(find.text('65.5%'), findsOneWidget);
    expect(find.text('Bottom pot or nothing'), findsOneWidget);
  });
}
