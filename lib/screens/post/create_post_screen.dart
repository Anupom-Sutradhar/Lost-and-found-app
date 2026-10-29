import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';
import '../../services/storage_service.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  PostType _type = PostType.lost;
  String _category = PostCategories.all.first;
  List<File> _images = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final pickedList = await picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (pickedList.isNotEmpty) {
        setState(() {
          _images.addAll(pickedList.map((p) => File(p.path)));
        });
      }
    } else {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _images.add(File(picked.path)));
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add a photo',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      gradient: AppColors.sunsetGradient,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      gradient: AppColors.skyGradient,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final user = auth.appUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      String? imageUrl;
      if (_images.isNotEmpty) {
        final storageService = StorageService();
        final urls = <String>[];
        for (final img in _images) {
          final url = await storageService.uploadPostImage(img, user.uid);
          urls.add(url);
        }
        if (urls.length == 1) {
          imageUrl = urls.first;
        } else {
          imageUrl = jsonEncode(urls);
        }
      }

      final post = Post(
        id: '',
        userId: user.uid,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        type: _type,
        status: PostStatus.active,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        location: _locationCtrl.text.trim(),
        contactInfo: _contactCtrl.text.trim(),
        category: _category,
        createdAt: DateTime.now(),
      );

      await DbService().createPost(post);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_type.label} item posted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TypeSelector(
              value: _type,
              onChange: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 24),
            _ImagePicker(
              images: _images,
              onTapAdd: _showImagePicker,
              onRemove: (index) => setState(() => _images.removeAt(index)),
              type: _type,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  Validators.required(v, field: 'Item title'),
              decoration: const InputDecoration(
                labelText: 'Item title',
                hintText: 'e.g. Black leather wallet',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: PostCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  Validators.required(v, field: 'Description'),
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the item, distinguishing marks, etc.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validators.required(v, field: 'Location'),
              decoration: InputDecoration(
                labelText: _type == PostType.lost
                    ? 'Where did you lose it?'
                    : 'Where did you find it?',
                hintText: 'e.g. Library, 2nd floor',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  Validators.required(v, field: 'Contact info'),
              decoration: const InputDecoration(
                labelText: 'Contact info',
                hintText: 'Phone number or any contact detail',
                prefixIcon:
                    Icon(Icons.call_outlined, color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Post ${_type.label} item',
              icon: Icons.send_rounded,
              loading: _saving,
              onPressed: _submit,
              gradient: _type == PostType.lost
                  ? AppColors.lostGradient
                  : AppColors.foundGradient,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.creamSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.mint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only verified @${AppConstants.universityEmailDomain} '
                      'students see your post.',
                      style: Theme.of(context).textTheme.bodySmall,
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
}

class _TypeSelector extends StatelessWidget {
  final PostType value;
  final ValueChanged<PostType> onChange;

  const _TypeSelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeChip(
            type: PostType.lost,
            selected: value == PostType.lost,
            onTap: () => onChange(PostType.lost),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeChip(
            type: PostType.found,
            selected: value == PostType.found,
            onTap: () => onChange(PostType.found),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final PostType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = type == PostType.lost;
    final gradient = isLost ? AppColors.lostGradient : AppColors.foundGradient;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3F3A5C)
                    : AppColors.border),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              isLost ? Icons.search_off_rounded : Icons.emoji_objects_rounded,
              color: selected
                  ? Colors.white
                  : (isLost ? AppColors.coral : AppColors.mint),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              isLost ? 'I lost something' : 'I found something',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final List<File> images;
  final VoidCallback onTapAdd;
  final ValueChanged<int> onRemove;
  final PostType type;

  const _ImagePicker({
    required this.images,
    required this.onTapAdd,
    required this.onRemove,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: onTapAdd,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.creamSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: type == PostType.lost
                      ? AppColors.lostGradient
                      : AppColors.foundGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Add photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Helps others identify the item (select multiple)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        itemBuilder: (context, index) {
          if (index == images.length) {
            // "Add more" card at the end
            return GestureDetector(
              onTap: onTapAdd,
              child: Container(
                width: 130,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: AppColors.creamSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: type == PostType.lost
                          ? AppColors.coral
                          : AppColors.mint,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add more',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final file = images[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
