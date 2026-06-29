import 'package:flutter_test/flutter_test.dart';

import 'package:bluexsofts_pos/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BluexSoftsPOSApp());
  });
}
