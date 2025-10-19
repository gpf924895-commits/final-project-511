import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mock_providers.dart';

void setupFirebaseForTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Note: Firebase initialization is skipped for basic tests
  // Only initialize Firebase when absolutely necessary
}

/// Creates a simple test widget without Firebase dependencies
Widget createTestWidget(Widget child) {
  return MaterialApp(home: child);
}

/// Creates a test widget with mock providers
Widget createTestWidgetWithProviders(
  Widget child, {
  MockAuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MockAuthProvider>(
        create: (context) => authProvider ?? MockAuthProvider(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}
