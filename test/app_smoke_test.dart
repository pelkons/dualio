import 'package:dualio/app/dualio_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Dualio app renders the feed shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DualioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dualio'), findsOneWidget);
    expect(find.text('Find anything you saved...'), findsOneWidget);
  });
}
