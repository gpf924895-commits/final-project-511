import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/provider/pro_login.dart';

void main() {
  group('AuthProvider Tests', () {
    testWidgets('AuthProvider should initialize with isReady=false', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      // Initially should not be ready
      expect(authProvider.isReady, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.currentRole, null);
    });

    testWidgets('AuthProvider should have proper getters', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      // Test getters
      expect(authProvider.isLoading, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isGuest, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.currentRole, null);
      expect(authProvider.isReady, false);
    });

    testWidgets('AuthProvider should handle logout properly', (
      WidgetTester tester,
    ) async {
      final authProvider = AuthProvider();

      // Simulate logged in state
      authProvider.enterGuestMode();

      // After logout, should reset state
      await authProvider.signOut();

      expect(authProvider.isReady, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.currentRole, null);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isGuest, true);
    });
  });
}
