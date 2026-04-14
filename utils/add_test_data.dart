import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Додає тестові публічні items в глобальну базу Firestore
/// Ці items будуть доступні для пошуку всім користувачам
/// Викличте цю функцію один раз після авторизації
Future<void> addTestData() async {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    print('❌ Error: User not authenticated');
    return;
  }

  print('📦 Adding test data...');

  final testItems = [
    {
      'name': 'Rare Coin',
      'year': '2018',
      'type': 'coin',
      'condition': 'excellent',
      'imageUrl':
          'https://images.unsplash.com/photo-1731119418309-dc32527bf0d8?w=400',
      'description': 'A rare coin from 2018 in excellent condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Vintage Stamp',
      'year': '2020',
      'type': 'stamp',
      'condition': 'good',
      'imageUrl':
          'https://images.unsplash.com/photo-1723400024840-e6d628358b00?w=400',
      'description': 'A vintage stamp from 2020 in good condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Collectible Figurine',
      'year': '2015',
      'type': 'figurine',
      'condition': 'excellent',
      'imageUrl':
          'https://images.unsplash.com/photo-1760189450523-d76219f17cff?w=400',
      'description': 'A collectible figurine from 2015 in excellent condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Gold Trading Card',
      'year': '2019',
      'type': 'trading card',
      'condition': 'fair',
      'imageUrl':
          'https://images.unsplash.com/photo-1622976900792-e37005f55d64?w=400',
      'description': 'A gold trading card from 2019 in fair condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Ancient Coin',
      'year': '1990',
      'type': 'coin',
      'condition': 'good',
      'imageUrl':
          'https://images.unsplash.com/photo-1731119418309-dc32527bf0d8?w=400',
      'description': 'An ancient coin from 1990 in good condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Rare Figurine',
      'year': '2010',
      'type': 'figurine',
      'condition': 'good',
      'imageUrl':
          'https://images.unsplash.com/photo-1760189450523-d76219f17cff?w=400',
      'description': 'A rare figurine from 2010 in good condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Mint Stamp',
      'year': '2005',
      'type': 'stamp',
      'condition': 'excellent',
      'imageUrl':
          'https://images.unsplash.com/photo-1723400024840-e6d628358b00?w=400',
      'description': 'A mint stamp from 2005 in excellent condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Silver Coin',
      'year': '2021',
      'type': 'coin',
      'condition': 'excellent',
      'imageUrl':
          'https://images.unsplash.com/photo-1731119418309-dc32527bf0d8?w=400',
      'description': 'A silver coin from 2021 in excellent condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
    {
      'name': 'Vintage Trading Card',
      'year': '2000',
      'type': 'trading card',
      'condition': 'fair',
      'imageUrl':
          'https://images.unsplash.com/photo-1622976900792-e37005f55d64?w=400',
      'description': 'A vintage trading card from 2000 in fair condition.',
      'createdBy': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPublic': true,
    },
  ];

  try {
    for (var item in testItems) {
      await firestore.collection('items').add(item);
      print('  ✓ Added: ${item['name']}');
    }
    print('✅ Done! Added ${testItems.length} items');
  } catch (e) {
    print('❌ Error: $e');
  }
}
