import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/collection_item_model.dart';
import '../models/collection_model.dart';
import '../providers/collections_provider.dart';
import '../providers/user_collections_provider.dart';
import 'edit_item_page.dart';

class ItemDetailsPage extends StatefulWidget {
  final CollectionItemModel item;
  final String? collectionId; // якщо не null - показуємо edit/delete
  final bool fromSearch; // якщо true - показуємо "додати до колекції"

  const ItemDetailsPage({
    Key? key,
    required this.item,
    this.collectionId,
    this.fromSearch = false,
  }) : super(key: key);

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  bool _isFavorite = false;
  bool _favoriteInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavoriteStatus();
    });
  }

  Future<String?> _getFavoritesCollectionId({
    required bool createIfMissing,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final collectionsProvider = context.read<UserCollectionsProvider>();
    if (collectionsProvider.collections.isEmpty &&
        !collectionsProvider.isLoading) {
      await collectionsProvider.loadCollections();
    }

    CollectionModel? favorites;
    for (final collection in collectionsProvider.collections) {
      final normalized = collection.name.trim().toLowerCase();
      if (normalized == 'favorites' || normalized == 'favourites') {
        favorites = collection;
        break;
      }
    }

    if (favorites == null && createIfMissing) {
      await collectionsProvider.addCollection(name: 'Favorites');
      for (final collection in collectionsProvider.collections) {
        final normalized = collection.name.trim().toLowerCase();
        if (normalized == 'favorites' || normalized == 'favourites') {
          favorites = collection;
          break;
        }
      }
    }

    return favorites?.id;
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final favoritesId = await _getFavoritesCollectionId(
        createIfMissing: false,
      );
      if (favoritesId == null) {
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
        }
        return;
      }

      final existing = await FirebaseFirestore.instance
          .collection('collection_items')
          .where('userId', isEqualTo: user.uid)
          .where('collectionId', isEqualTo: favoritesId)
          .where('itemId', isEqualTo: widget.item.id)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = existing.docs.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteInProgress) return;

    setState(() {
      _favoriteInProgress = true;
    });

    try {
      final favoritesId = await _getFavoritesCollectionId(
        createIfMissing: true,
      );
      if (favoritesId == null) {
        throw Exception('Failed to create Favorites collection');
      }

      final collectionsProvider = context.read<CollectionsProvider>();
      final userCollectionsProvider = context.read<UserCollectionsProvider>();

      if (_isFavorite) {
        await collectionsProvider.removeItemFromCollection(
          widget.item.id,
          favoritesId,
        );
        await userCollectionsProvider.refreshItemCount(favoritesId);
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        try {
          await collectionsProvider.addItemToCollection(
            widget.item.id,
            favoritesId,
          );
        } catch (e) {
          if (!e.toString().toLowerCase().contains('already')) {
            rethrow;
          }
        }

        await userCollectionsProvider.refreshItemCount(favoritesId);

        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _favoriteInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final collectionId = widget.collectionId;
    final fromSearch = widget.fromSearch;
    final hasValidImage = _isValidImageUrl(item.imageUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF4A4A4A),
        ),
        centerTitle: true,
        title: const Text(
          'Item Details',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _favoriteInProgress ? null : _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite
                ? const Color(0xFFEF4444)
                : const Color(0xFF4A4A4A),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality')),
              );
            },
            icon: const Icon(Icons.share),
            color: const Color(0xFF4A4A4A),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Головне зображення
            Container(
              width: double.infinity,
              height: 300,
              color: const Color(0xFFD1D5DB),
              child: hasValidImage
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFD1D5DB),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF9CA3AF),
                            size: 80,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFD1D5DB),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF9CA3AF),
                        size: 80,
                      ),
                    ),
            ),

            // Основна інформація
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Назва
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Тип і рік
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.category,
                        label: _capitalizeType(item.type),
                        color: const Color(0xFF3A5A53),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: item.year,
                        color: const Color(0xFF6B9DAF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Стан
                  const Text(
                    'Condition',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(item.condition),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getConditionIcon(item.condition),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _capitalizeType(item.condition),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Опис
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDescription(item),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Додаткова інформація
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _InfoRow(label: 'Item ID', value: item.id),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Type', value: _capitalizeType(item.type)),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Year', value: item.year),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Condition',
                    value: _capitalizeType(item.condition),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Category', value: _getCategory(item.type)),

                  const SizedBox(height: 32),

                  if (fromSearch)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddToCollectionDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Collection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A5A53),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Показуємо Edit тільки якщо це автор
                        if (item.createdBy ==
                            FirebaseAuth.instance.currentUser?.uid)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditItemPage(
                                      item: item,
                                      collectionId: collectionId,
                                    ),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  if (collectionId != null) {
                                    await context
                                        .read<CollectionsProvider>()
                                        .loadItemsByCollection(collectionId!);
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A5A53),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (item.createdBy ==
                            FirebaseAuth.instance.currentUser?.uid)
                          const SizedBox(width: 12),
                        // Видалити з колекції може будь-хто
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showRemoveFromCollectionDialog(context),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: Text(
                              item.createdBy ==
                                      FirebaseAuth.instance.currentUser?.uid
                                  ? 'Delete'
                                  : 'Remove',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeType(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF10B981);
      case 'good':
        return const Color(0xFF3B82F6);
      case 'fair':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'fair':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  String _getDescription(CollectionItemModel item) {
    if (item.description != null && item.description!.isNotEmpty) {
      return item.description!;
    }

    return 'This is a ${item.condition} condition ${item.type} from ${item.year}. '
        'This collectible item is part of a rare collection and has been carefully '
        'preserved. The item shows authentic characteristics typical of items from this period. '
        'Perfect for collectors interested in ${item.type}s.';
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    final hasProtocol =
        lower.startsWith('http://') || lower.startsWith('https://');
    if (!hasProtocol) return false;
    if (lower.contains('via.placeholder.com')) return false;
    return true;
  }

  String _getCategory(String type) {
    switch (type.toLowerCase()) {
      case 'coin':
        return 'Numismatics';
      case 'stamp':
        return 'Philately';
      case 'figurine':
        return 'Miniatures & Figurines';
      case 'trading card':
        return 'Trading Cards';
      default:
        return 'Collectibles';
    }
  }

  void _showAddToCollectionDialog(BuildContext context) {
    final collectionsProvider = context.read<UserCollectionsProvider>();
    collectionsProvider.loadCollections();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add to Collection'),
        content: Consumer<UserCollectionsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (provider.isEmpty) {
              return const Text(
                'You don\'t have any collections yet.\nCreate one first!',
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.collections.length,
                itemBuilder: (context, index) {
                  final collection = provider.collections[index];
                  return ListTile(
                    title: Text(collection.name),
                    subtitle: Text('${collection.itemCount} items'),
                    leading: const Icon(Icons.folder, color: Color(0xFF3A5A53)),
                    onTap: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      Navigator.pop(dialogContext);

                      debugPrint(
                        '🔵 Starting to add item ${widget.item.id} to collection ${collection.id}',
                      );

                      // Показуємо loading
                      scaffold.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Adding to collection...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      try {
                        await context
                            .read<CollectionsProvider>()
                            .addItemToCollection(widget.item.id, collection.id);

                        debugPrint(
                          '🟢 Successfully added item, showing success message',
                        );
                        scaffold.clearSnackBars();
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '✓ Added to "${collection.name}"',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        debugPrint('🔴 Error adding item: $e');
                        scaffold.clearSnackBars();
                        final errorMessage =
                            e.toString().toLowerCase().contains('already')
                            ? '⚠️ Already in this collection'
                            : '❌ Error: ${e.toString()}';

                        scaffold.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(errorMessage)),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFromCollectionDialog(BuildContext context) {
    final pageContext = context;
    final rootNavigator = Navigator.of(pageContext, rootNavigator: true);
    final isAuthor =
        widget.item.createdBy == FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAuthor ? 'Delete Item' : 'Remove from Collection'),
        content: Text(
          isAuthor
              ? 'Are you sure you want to delete "${widget.item.name}"? This will remove it from all collections and cannot be undone.'
              : 'Remove "${widget.item.name}" from this collection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              var loadingShown = false;
              showDialog(
                context: pageContext,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (ctx) {
                  loadingShown = true;
                  return const Center(child: CircularProgressIndicator());
                },
              );

              try {
                if (isAuthor) {
                  // Видаляємо item повністю (тільки автор)
                  await context.read<CollectionsProvider>().deleteItem(
                    widget.item.id,
                  );
                } else if (widget.collectionId != null) {
                  // Видаляємо зв'язок з колекції
                  await context
                      .read<CollectionsProvider>()
                      .removeItemFromCollection(
                        widget.item.id,
                        widget.collectionId!,
                      );
                }

                if (pageContext.mounted) {
                  if (loadingShown && rootNavigator.canPop()) {
                    rootNavigator.pop();
                  }

                  Navigator.of(pageContext).pop(true);

                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAuthor
                            ? 'Item deleted successfully'
                            : 'Removed from collection',
                      ),
                      backgroundColor: const Color(0xFF3A5A53),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (pageContext.mounted) {
                  if (loadingShown && rootNavigator.canPop()) {
                    rootNavigator.pop();
                  }

                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text(isAuthor ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}
