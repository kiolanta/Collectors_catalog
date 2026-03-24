import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/bottom_nav_bar.dart';
import 'collection_items_page.dart';
import '../providers/user_collections_provider.dart';
import '../models/collection_model.dart';
import '../services/supabase_service.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCollectionsProvider>().loadCollections();
    });
  }

  void _showAddCollectionDialog() {
    final nameController = TextEditingController();
    File? selectedImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Collection'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Collection Image (optional)',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8A9D95)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFB5C2BD)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: selectedImage != null
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      selectedImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap to change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A9D95),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Color(0xFF8A9D95),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to select image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A9D95),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    // Show loading
                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      String? imageUrl;

                      // Upload image if selected
                      if (selectedImage != null) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          imageUrl = await SupabaseService.uploadImage(
                            selectedImage!,
                            userId,
                          );
                        }
                      }

                      await this.context
                          .read<UserCollectionsProvider>()
                          .addCollection(name: name, imageUrl: imageUrl);

                      if (this.mounted) {
                        Navigator.pop(this.context); // close loading
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Collection created!'),
                            backgroundColor: Color(0xFF3A5A53),
                          ),
                        );
                      }
                    } catch (e) {
                      if (this.mounted) {
                        Navigator.pop(this.context); // close loading
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleCollectionClick(CollectionModel collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionItemsPage(
          collectionName: collection.name,
          collectionId: collection.id,
        ),
      ),
    ).then((_) {
      // Перезавантажуємо колекції після повернення
      context.read<UserCollectionsProvider>().loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Collections',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                      height: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showAddCollectionDialog,
                        icon: const Icon(Icons.add, size: 28),
                        tooltip: 'Add collection',
                        color: const Color(0xFF4A4A4A),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<UserCollectionsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Failed to load collections'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => provider.loadCollections(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (provider.isEmpty) {
                    return const Center(
                      child: Text(
                        'No collections yet. Add one!',
                        style: TextStyle(color: Color(0xFF4A4A4A)),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.collections.length,
                    itemBuilder: (context, index) {
                      final collection = provider.collections[index];
                      return _CollectionListItem(
                        collection: collection,
                        onTap: () => _handleCollectionClick(collection),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete collection'),
                              content: const Text(
                                'Delete this collection and all its items?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await context
                                  .read<UserCollectionsProvider>()
                                  .deleteCollection(collection.id);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}

class _CollectionListItem extends StatelessWidget {
  final CollectionModel collection;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CollectionListItem({
    required this.collection,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedName = collection.name.trim().toLowerCase();
    final isFavorites =
        normalizedName == 'favorites' || normalizedName == 'favourites';
    final hasCustomImage =
        collection.imageUrl != null &&
        collection.imageUrl!.isNotEmpty &&
        !collection.imageUrl!.contains('via.placeholder.com');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Collection Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: isFavorites
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFD1D5DB),
                child: (!hasCustomImage && isFavorites)
                    ? const Icon(
                        Icons.favorite,
                        color: Color(0xFFEF4444),
                        size: 32,
                      )
                    : Image.network(
                        collection.imageUrl ??
                            'https://via.placeholder.com/128',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFD1D5DB),
                            child: Icon(
                              isFavorites ? Icons.favorite : Icons.image,
                              color: isFavorites
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF9CA3AF),
                              size: 32,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFD1D5DB),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Collection Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isFavorites
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF4A4A4A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${collection.itemCount} items',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8A8A9A),
                          height: 1.5,
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Color(0xFF8A8A9A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
