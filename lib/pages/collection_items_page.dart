import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collections_provider.dart';
import '../models/collection_item_model.dart';
import 'item_details_page.dart';
import 'add_item_page.dart';

class CollectionItemsPage extends StatefulWidget {
  final String collectionName;
  final String collectionId;

  const CollectionItemsPage({
    Key? key,
    required this.collectionName,
    required this.collectionId,
  }) : super(key: key);

  @override
  State<CollectionItemsPage> createState() => _CollectionItemsPageState();
}

class _CollectionItemsPageState extends State<CollectionItemsPage> {
  String _viewMode = 'grid';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionsProvider>().loadItemsByCollection(
        widget.collectionId,
      );
    });
  }

  List<CollectionItemModel> get _collectionItems {
    final provider = context.watch<CollectionsProvider>();
    return provider.items;
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

  void _handleItemClick(CollectionItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ItemDetailsPage(item: item, collectionId: widget.collectionId),
      ),
    ).then((_) {
      // Перезавантажуємо items після повернення
      context.read<CollectionsProvider>().loadItemsByCollection(
        widget.collectionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          widget.collectionName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
              });
            },
            icon: Icon(_viewMode == 'grid' ? Icons.view_list : Icons.grid_view),
            color: const Color(0xFF4A4A4A),
            tooltip: _viewMode == 'grid' ? 'List view' : 'Grid view',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddItemPage(initialCollectionId: widget.collectionId),
                ),
              ).then((_) {
                // refresh after coming back
                context.read<CollectionsProvider>().loadItemsByCollection(
                  widget.collectionId,
                );
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_collectionItems.length} items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<CollectionsProvider>(
              builder: (context, provider, child) {
                Widget content;

                if (provider.isLoading) {
                  content = const Center(
                    key: ValueKey('loading-state'),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3A5A53),
                      ),
                    ),
                  );
                } else if (provider.hasError) {
                  content = Center(
                    key: const ValueKey('error-state'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage ?? 'An error occurred',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => provider.loadItemsByCollection(
                              widget.collectionId,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A5A53),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_collectionItems.isEmpty) {
                  content = Center(
                    key: const ValueKey('empty-state'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first item to this collection',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddItemPage(
                                  initialCollectionId: widget.collectionId,
                                ),
                              ),
                            ).then((_) {
                              context
                                  .read<CollectionsProvider>()
                                  .loadItemsByCollection(widget.collectionId);
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A5A53),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  content = KeyedSubtree(
                    key: ValueKey(
                      'items-${_viewMode}-${_collectionItems.length}',
                    ),
                    child: _viewMode == 'grid'
                        ? _buildGridView()
                        : _buildListView(),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _collectionItems.length,
      itemBuilder: (context, index) {
        final item = _collectionItems[index];
        return _GridItemCard(
          item: item,
          onTap: () => _handleItemClick(item),
          isValidImageUrl: _isValidImageUrl,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _collectionItems.length,
      itemBuilder: (context, index) {
        final item = _collectionItems[index];
        return _ListItemCard(
          item: item,
          onTap: () => _handleItemClick(item),
          isValidImageUrl: _isValidImageUrl,
        );
      },
    );
  }
}

class _GridItemCard extends StatelessWidget {
  final CollectionItemModel item;
  final VoidCallback onTap;
  final bool Function(String url) isValidImageUrl;

  const _GridItemCard({
    required this.item,
    required this.onTap,
    required this.isValidImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Зображення
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFD1D5DB),
                  child: isValidImageUrl(item.imageUrl)
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
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
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFD1D5DB),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF9CA3AF),
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
            // Інформація
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.year,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(
                        item.condition,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.condition.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getConditionColor(item.condition),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}

// Картка елемента для списку
class _ListItemCard extends StatelessWidget {
  final CollectionItemModel item;
  final VoidCallback onTap;
  final bool Function(String url) isValidImageUrl;

  const _ListItemCard({
    required this.item,
    required this.onTap,
    required this.isValidImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Зображення
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFD1D5DB),
                child: isValidImageUrl(item.imageUrl)
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
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
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFD1D5DB),
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF9CA3AF),
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Інформація
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.year,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(
                        item.condition,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.condition.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getConditionColor(item.condition),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
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
}
