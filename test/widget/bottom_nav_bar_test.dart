import 'package:collectors_catalog/components/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required int selectedIndex, bool isDark = false}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedIndex,
        isDark: isDark,
      ),
    ),
  );
}

void main() {
  group('BottomNavBar renders correctly', () {
    testWidgets('shows all four tab labels', (tester) async {
      await tester.pumpWidget(_wrap(selectedIndex: 0));

      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows all four tab icons', (tester) async {
      await tester.pumpWidget(_wrap(selectedIndex: 0));

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('selected tab text has bold weight', (tester) async {
      await tester.pumpWidget(_wrap(selectedIndex: 2));
      await tester.pump();

      final searchText = tester.widget<Text>(find.text('Search'));
      expect(searchText.style?.fontWeight, FontWeight.w600);

      // Unselected tabs have normal weight
      final collectionsText = tester.widget<Text>(find.text('Collections'));
      expect(collectionsText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('selected index 0 makes Collections tab bold', (tester) async {
      await tester.pumpWidget(_wrap(selectedIndex: 0));
      await tester.pump();

      final text = tester.widget<Text>(find.text('Collections'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('renders with isDark flag without throwing', (tester) async {
      await tester.pumpWidget(_wrap(selectedIndex: 1, isDark: true));
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('tapping already-selected tab does not push a new route', (
      tester,
    ) async {
      int routeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [_CountingObserver(onPush: () => routeCount++)],
          home: Scaffold(
            bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
          ),
        ),
      );

      await tester.tap(find.text('Collections'));
      await tester.pump();

      // No pushReplacement should happen when tapping the already-active tab
      expect(routeCount, 0);
    });
  });
}

class _CountingObserver extends NavigatorObserver {
  final VoidCallback onPush;
  _CountingObserver({required this.onPush});

  @override
  void didPush(Route route, Route? previousRoute) {
    // Only count pushes that aren't the initial MaterialPageRoute
    if (previousRoute != null) onPush();
    super.didPush(route, previousRoute);
  }
}
