import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/collections_provider.dart';
import '../models/collection_item_model.dart';
import '../components/bottom_nav_bar.dart';
import '../services/supabase_service.dart';

class EditItemPage extends StatefulWidget {
  final CollectionItemModel item;
  final String? collectionId;

  const EditItemPage({Key? key, required this.item, this.collectionId})
    : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedItemType;
  late final TextEditingController _itemNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _yearController;
  late final TextEditingController _conditionController;
  late final TextEditingController _valueController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  final List<String> _itemTypes = [
    'Coin',
    'Stamp',
    'Figurine',
    'Trading Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _yearController = TextEditingController(text: widget.item.year);
    _conditionController = TextEditingController(text: widget.item.condition);
    _valueController = TextEditingController(text: '0');
    _selectedItemType = _capitalizeType(widget.item.type);
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _conditionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  String _capitalizeType(String text) {
    if (text.isEmpty) return 'Other';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
      setState(() => _isSaving = true);

      try {
        String imageUrl = widget.item.imageUrl;

        // Upload new image to Supabase if selected
        if (_selectedImage != null) {
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          if (userId.isEmpty) {
            throw Exception('Not authenticated');
          }
          imageUrl = await SupabaseService.updateImage(
            _selectedImage!,
            widget.item.imageUrl,
            userId,
          );
          print('Image updated: $imageUrl');
        }

        final updatedItem = widget.item.copyWith(
          name: _itemNameController.text.trim(),
          year: _yearController.text.trim(),
          type: _selectedItemType.toLowerCase(),
          condition: _conditionController.text.trim().toLowerCase(),
          imageUrl: imageUrl,
          description: _descriptionController.text.trim(),
        );

        await context.read<CollectionsProvider>().updateItem(updatedItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item updated successfully!'),
              backgroundColor: Color(0xFF3A5A53),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF4A4A4A),
        ),
        title: const Text(
          'Edit Item',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    if (newValue != null) {
                      setState(() {
                        _selectedItemType = newValue;
                      });
                    }
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
              const SizedBox(height: 24),

              const Text(
                'Change Image',
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.item.imageUrl,
                                width: 128,
                                height: 128,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 128,
                                    height: 128,
                                    color: const Color(0xFFD1D5DB),
                                    child: const Icon(
                                      Icons.image,
                                      color: Color(0xFF9CA3AF),
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to change image',
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
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A5A53),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save Changes',
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
