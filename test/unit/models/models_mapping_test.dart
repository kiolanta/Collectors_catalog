import 'package:collectors_catalog/models/collection_item_model.dart';
import 'package:collectors_catalog/models/collection_model.dart';
import 'package:collectors_catalog/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollectionModel', () {
    test('fromMap parses itemCount from string', () {
      final model = CollectionModel.fromMap({
        'name': 'Coins',
        'userId': 'u1',
        'itemCount': '12',
        'imageUrl': 'https://img',
        'createdAt': 1700000000000,
        'updatedAt': 1700001000000,
      }, 'c1');

      expect(model.id, 'c1');
      expect(model.itemCount, 12);
      expect(model.name, 'Coins');
    });

    test('toMap stores timestamp fields as milliseconds', () {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700001000000);
      final model = CollectionModel(
        id: 'c1',
        name: 'Stamps',
        userId: 'u1',
        itemCount: 5,
        imageUrl: null,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = model.toMap();
      expect(map['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(map['updatedAt'], updatedAt.millisecondsSinceEpoch);
      expect(map['itemCount'], 5);
    });

    test('copyWith updates only provided fields', () {
      final original = CollectionModel(
        id: 'c1',
        name: 'Original',
        userId: 'u1',
        itemCount: 1,
        imageUrl: 'https://old',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      final updated = original.copyWith(name: 'Updated', itemCount: 2);
      expect(updated.name, 'Updated');
      expect(updated.itemCount, 2);
      expect(updated.id, 'c1');
      expect(updated.userId, 'u1');
    });
  });

  group('CollectionItemModel', () {
    test('fromMap fills defaults for missing fields', () {
      final model = CollectionItemModel.fromMap({}, 'i1');

      expect(model.id, 'i1');
      expect(model.name, '');
      expect(model.type, '');
      expect(model.isPublic, isTrue);
    });

    test('toMap includes all expected fields', () {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final model = CollectionItemModel(
        id: 'i1',
        name: 'Rare Coin',
        year: '1998',
        type: 'Coin',
        condition: 'Good',
        imageUrl: 'https://img',
        description: 'Desc',
        createdBy: 'u1',
        createdAt: createdAt,
        isPublic: false,
      );

      final map = model.toMap();
      expect(map['name'], 'Rare Coin');
      expect(map['year'], '1998');
      expect(map['isPublic'], isFalse);
      expect(map['createdAt'], createdAt.millisecondsSinceEpoch);
    });

    test('copyWith preserves unspecified fields', () {
      final original = CollectionItemModel(
        id: 'i1',
        name: 'Item 1',
        year: '2000',
        type: 'Card',
        condition: 'Excellent',
        imageUrl: 'https://img',
        description: null,
        createdBy: 'u1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      final updated = original.copyWith(type: 'Coin');
      expect(updated.type, 'Coin');
      expect(updated.name, 'Item 1');
      expect(updated.createdBy, 'u1');
    });
  });

  group('UserModel', () {
    test('toMap and fromMap perform round-trip for ISO dates', () {
      final user = UserModel(
        uid: 'u1',
        email: 'u@example.com',
        displayName: 'User',
        photoURL: 'https://photo',
        createdAt: DateTime.parse('2026-01-01T10:00:00.000Z'),
        lastLogin: DateTime.parse('2026-01-02T10:00:00.000Z'),
      );

      final map = user.toMap();
      final parsed = UserModel.fromMap(map);

      expect(parsed.uid, user.uid);
      expect(parsed.email, user.email);
      expect(
        parsed.createdAt.toIso8601String(),
        user.createdAt.toIso8601String(),
      );
      expect(
        parsed.lastLogin.toIso8601String(),
        user.lastLogin.toIso8601String(),
      );
    });
  });
}
