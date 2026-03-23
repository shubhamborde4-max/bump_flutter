import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BumpApp()));
    await tester.pump();
    // App should render without crashing
    expect(find.text('Bump'), findsWidgets);
  });
}
