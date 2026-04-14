import 'package:collectors_catalog/models/collection_item_model.dart';
import 'package:collectors_catalog/pages/item_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

CollectionItemModel _item({
  String name = 'Rare Coin',
  String year = '1998',
  String type = 'Coin',
  String condition = 'Excellent',
  String? description,
}) => CollectionItemModel(
  id: 'i1',
  name: name,
  year: year,
  type: type,
  condition: condition,
  imageUrl: '',
  description: description,
  createdBy: 'u1',
  createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
);

/// Wrap with fromSearch: true so the build() does NOT evaluate
/// FirebaseAuth.instance.currentUser (that branch is in the else arm).
Widget _wrap(CollectionItemModel item) =>
    MaterialApp(home: ItemDetailsPage(item: item, fromSearch: true));

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ItemDetailsPage – AppBar', () {
    testWidgets('shows Item Details title', (tester) async {
      await tester.pumpWidget(_wrap(_item()));
      await tester.pumpAndSettle();

      expect(find.text('Item Details'), findsOneWidget);
    });

    testWidgets('shows favorite and share action icons', (tester) async {
      await tester.pumpWidget(_wrap(_item()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });

  group('ItemDetailsPage – item data', () {
    testWidgets('displays item name', (tester) async {
      await tester.pumpWidget(_wrap(_item(name: 'Silver Coin')));
      await tester.pumpAndSettle();

      expect(find.text('Silver Coin'), findsOneWidget);
    });

    testWidgets('displays item year', (tester) async {
      await tester.pumpWidget(_wrap(_item(year: '2005')));
      await tester.pumpAndSettle();

      expect(find.text('2005'), findsWidgets);
    });

    testWidgets('shows Condition section', (tester) async {
      await tester.pumpWidget(_wrap(_item(condition: 'good')));
      await tester.pumpAndSettle();

      expect(find.text('Condition'), findsWidgets);
    });

    testWidgets('shows Description section', (tester) async {
      await tester.pumpWidget(_wrap(_item(description: 'A very rare piece.')));
      await tester.pumpAndSettle();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('A very rare piece.'), findsOneWidget);
    });

    testWidgets('shows Add to Collection button when fromSearch is true', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_item()));
      await tester.pumpAndSettle();

      expect(find.text('Add to Collection'), findsOneWidget);
    });
  });
}
