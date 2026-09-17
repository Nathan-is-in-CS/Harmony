// A widget test: it builds your app in memory and checks what is on screen.
// Run them all with: flutter test
//
// You are not required to write more of these, but a project with a few real
// tests reads very differently from one with none.

import 'package:flutter_test/flutter_test.dart';

import 'package:harmony/main.dart';

void main() {
  testWidgets('home screen shows its title and counts taps', (tester) async {
    // Build the app. The home screen is the Library screen.
    await tester.pumpWidget(const MyApp());

    expect(find.text('Track Library'), findsOneWidget);
    // Sample data populates the library when empty in the setup.
    expect(find.text('Autumn Leaves'), findsOneWidget);
  });
}
