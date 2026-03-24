import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'collections_page.dart';
import 'package:provider/provider.dart';
import '../providers/collections_provider.dart';
import '../models/collection_item_model.dart';
import '../models/collection_model.dart';
import '../components/bottom_nav_bar.dart';
import '../services/supabase_service.dart';

class AddItemPage extends StatefulWidget {
  final String? initialCollectionId;
  const AddItemPage({Key? key, this.initialCollectionId}) : super(key: key);

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemType;
  String? _selectedCollectionId;
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _conditionController = TextEditingController();
  final _valueController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _itemTypes = [
    'Coin',
    'Stamp',
    'Figurine',
    'Trading Card',
    'Other',
  ];
  List<CollectionModel> _userCollections = [];
  bool _collectionsLoading = false;
  String? _collectionsError;

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _conditionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserCollections();
  }

  Future<void> _loadUserCollections() async {
    setState(() {
      _collectionsLoading = true;
      _collectionsError = null;
    });
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');
      final snapshot = await FirebaseFirestore.instance
          .collection('collections')
          .where('userId', isEqualTo: userId)
          .get();
      _userCollections = snapshot.docs
          .map((doc) => CollectionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _collectionsError = e.toString();
    } finally {
      setState(() {
        _collectionsLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Отримуємо userId поточного користувача
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Upload image to Supabase if selected
        String imageUrl = '';
        if (_selectedImage != null) {
          imageUrl = await SupabaseService.uploadImage(_selectedImage!, userId);
          print('Image uploaded: $imageUrl');
        }

        final provider = context.read<CollectionsProvider>();

        // Створюємо публічний item (доступний всім для пошуку)
        final item = CollectionItemModel(
          id: '',
          name: _itemNameController.text.trim(),
          year: _yearController.text.trim(),
          type: (_selectedItemType ?? 'Other').toLowerCase(),
          condition: _conditionController.text.trim().toLowerCase(),
          imageUrl: imageUrl,
          description: _descriptionController.text.trim(),
          createdBy: userId,
          createdAt: DateTime.now(),
          isPublic: true,
        );

        await provider.addItem(item);

        final collectionId =
            _selectedCollectionId ?? widget.initialCollectionId;
        if (collectionId != null && collectionId.isNotEmpty) {
          final createdItem = provider.items.last;
          await provider.addItemToCollection(createdItem.id, collectionId);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item created and added to collection!'),
            backgroundColor: Color(0xFF3A5A53),
          ),
        );
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(true);
        } else {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const CollectionsPage()),
          );
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox(),
        title: const Text(
          'Add item',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectionsPage(),
                ),
              );
            },
            icon: const Icon(Icons.close),
            color: const Color(0xFF4A4A4A),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown для вибору колекції
              if (widget.initialCollectionId == null) ...[
                if (_collectionsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_collectionsError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Failed to load collections: $_collectionsError',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (_userCollections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "You don't have any collections yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE5E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCollectionId,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Select a collection',
                        hintStyle: TextStyle(color: Color(0xFF8A9D95)),
                      ),
                      icon: const Icon(
                        Icons.unfold_more,
                        color: Color(0xFF8A9D95),
                      ),
                      dropdownColor: const Color(0xFFDDE5E2),
                      items: _userCollections.map((collection) {
                        return DropdownMenuItem<String>(
                          value: collection.id,
                          child: Text(collection.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCollectionId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a collection';
                        }
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              // Select Item Type Dropdown
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedItemType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Select Item Type',
                    hintStyle: TextStyle(color: Color(0xFF8A9D95)),
                  ),
                  icon: const Icon(Icons.unfold_more, color: Color(0xFF8A9D95)),
                  dropdownColor: const Color(0xFFDDE5E2),
                  items: _itemTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItemType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an item type';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _itemNameController,
                hintText: 'Item Name',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                hintText: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _yearController,
                hintText: 'Year',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _conditionController,
                hintText: 'Condition',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _valueController,
                hintText: 'Value',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              const Text(
                'Add Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFB5C2BD),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage != null
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                width: 128,
                                height: 128,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to change image',
                              style: TextStyle(
                                color: Color(0xFF5A7A73),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: Color(0xFF8A9D95),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to upload an image of your item',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8A9D95),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A5A53),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8A9D95)),
        filled: true,
        fillColor: const Color(0xFFDDE5E2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A5A53), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 12 : 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${hintText.toLowerCase()}';
        }

        switch (hintText) {
          case 'Year':
            final year = int.tryParse(value);
            if (year == null) {
              return 'Please enter a valid year';
            }
            if (year < 1000 || year > DateTime.now().year) {
              return 'Please enter a valid year between 1000 and ${DateTime.now().year}';
            }
            break;

          case 'Value':
            final valueNum = double.tryParse(value);
            if (valueNum == null) {
              return 'Please enter a valid number';
            }
            if (valueNum < 0) {
              return 'Value cannot be negative';
            }
            break;

          case 'Item Name':
            if (value.length < 2) {
              return 'Name must be at least 2 characters long';
            }
            break;

          case 'Description':
            if (value.length < 10) {
              return 'Description must be at least 10 characters long';
            }
            break;

          case 'Condition':
            if (value.length < 3) {
              return 'Please describe the condition (min 3 characters)';
            }
            break;
        }
        return null;
      },
    );
  }
}
