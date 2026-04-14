import 'package:collectors_catalog/models/collection_model.dart';
import 'package:collectors_catalog/pages/collections_page.dart';
import 'package:collectors_catalog/providers/user_collections_provider.dart';
import 'package:collectors_catalog/repositories/collection_links_repository.dart';
import 'package:collectors_catalog/repositories/collections_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeCollectionsRepo implements CollectionsRepository {
  @override
  Future<List<CollectionModel>> getUserCollections(String userId) async => [];

  @override
  Stream<List<CollectionModel>> watchUserCollections(String userId) =>
      Stream.value([]);

  @override
  Future<CollectionModel> createCollection(CollectionModel collection) async =>
      collection;

  @override
  Future<void> updateCollection(CollectionModel collection) async {}

  @override
  Future<void> deleteCollection(String collectionId) async {}
}

class _FakeLinksRepo implements CollectionLinksRepository {
  @override
  Future<void> addItemToCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {}

  @override
  Future<void> removeItemFromCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {}

  @override
  Future<List<String>> getItemIdsForCollection({
    required String userId,
    required String collectionId,
  }) async => [];
}

/// UserCollectionsProvider whose loadCollections() is a no-op.
/// State is controlled via setForTesting().
class _TestableUCProvider extends UserCollectionsProvider {
  _TestableUCProvider()
    : super(
        firestore: FakeFirebaseFirestore(),
        collectionsRepository: _FakeCollectionsRepo(),
        linksRepository: _FakeLinksRepo(),
      );

  @override
  Future<void> loadCollections() async {
    // No-op: prevents Firebase calls; state is set via setForTesting().
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

CollectionModel _col(String id, String name, {int itemCount = 0}) =>
    CollectionModel(
      id: id,
      name: name,
      userId: 'u1',
      itemCount: itemCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );

Widget _wrap(UserCollectionsProvider provider) => MaterialApp(
  home: ChangeNotifierProvider<UserCollectionsProvider>.value(
    value: provider,
    child: const CollectionsPage(),
  ),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CollectionsPage – header', () {
    testWidgets('shows Collections title', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(state: CollectionsLoadingState.empty, collections: []);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('Collections'), findsWidgets);
    });

    testWidgets('shows add icon button', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(state: CollectionsLoadingState.empty, collections: []);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsWidgets);
    });
  });

  group('CollectionsPage – loading state', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(state: CollectionsLoadingState.loading);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('CollectionsPage – empty state', () {
    testWidgets('shows empty message when no collections', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(state: CollectionsLoadingState.empty, collections: []);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('No collections yet. Add one!'), findsOneWidget);
    });
  });

  group('CollectionsPage – error state', () {
    testWidgets('shows error text and Retry button', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(state: CollectionsLoadingState.error);

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('Failed to load collections'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('CollectionsPage – loaded state', () {
    testWidgets('shows collection names in list', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(
          state: CollectionsLoadingState.loaded,
          collections: [
            _col('c1', 'Coins', itemCount: 5),
            _col('c2', 'Stamps', itemCount: 12),
          ],
        );

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('Coins'), findsOneWidget);
      expect(find.text('Stamps'), findsOneWidget);
    });

    testWidgets('shows item count for each collection', (tester) async {
      final provider = _TestableUCProvider()
        ..setForTesting(
          state: CollectionsLoadingState.loaded,
          collections: [_col('c1', 'Coins', itemCount: 3)],
        );

      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      expect(find.text('3 items'), findsOneWidget);
    });
  });
}
