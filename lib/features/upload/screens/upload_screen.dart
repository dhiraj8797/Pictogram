import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/post_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../widgets/glass_widgets.dart';

const Color _pink  = Color.fromRGBO(255, 61,  135, 1.0);
const Color _coral = Color.fromRGBO(255, 106,  92, 1.0);

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen>
    with TickerProviderStateMixin {
  final PostService _postService = PostService();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isImageLoading = false;
  bool _isPosting = false;
  double _uploadProgress = 0.0;
  List<String> _tagChips = [];
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    if (_isImageLoading || _isPosting) return;
    
    setState(() {
      _isImageLoading = true;
    });

    try {
      // Request appropriate permissions first
      Permission permission;
      String permissionType;
      
      if (source == ImageSource.camera) {
        permission = Permission.camera;
        permissionType = 'camera';
      } else {
        // For Android 13+, use photos permission instead of storage
        permission = Permission.photos;
        permissionType = 'photos';
      }
      
      // Check if permission is already granted
      final status = await permission.status;
      
      if (!status.isGranted) {
        // Request permission
        final result = await permission.request();
        
        if (!result.isGranted) {
          if (result.isPermanentlyDenied) {
            // Show dialog to open settings
            _showPermissionDialog();
            return;
          } else if (result.isDenied) {
            // Permission denied but not permanently - show message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$permissionType permission is required to select photos.'),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () => _pickImage(source: source),
                  ),
                ),
              );
            }
            return;
          } else {
            return;
          }
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs access to your photos to upload posts. Please enable permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(source: ImageSource.camera);
                    },
                  ),
                  _ImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(source: ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null || _isPosting) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to upload posts')),
      );
      return;
    }
    
    // If displayName is null or empty, fetch fresh data from Firestore
    String displayName = currentUser.displayName ?? '';
    if (displayName.isEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          displayName = userData?['displayName'] ?? '';
              }
      } catch (e) {
      }
    }
    
    // If displayName is still empty, use email as fallback
    if (displayName.isEmpty && currentUser.email != null) {
      displayName = currentUser.email!.split('@')[0];
    }
    
    // Final fallback to avoid empty name
    if (displayName.isEmpty) {
      displayName = 'User';
    }
    
    setState(() {
      _isPosting = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100.0;
          });
        }
      }

      final post = await _postService.createPost(
        userId: currentUser.uid,
        displayName: displayName, // Use the fetched displayName
        userProfileImage: currentUser.profileImage ?? '',
        imageFile: _selectedImage!,
        caption: _captionController.text.trim(),
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        tags: _tagChips,
      );
      
      // Show success animation
      _successAnimationController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        setState(() {
          _selectedImage = null;
          _captionController.clear();
          _locationController.clear();
          _tagsController.clear();
          _tagChips.clear();
          _isPosting = false;
          _uploadProgress = 0.0;
        });

        // Navigate to homepage immediately after successful upload
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pushReplacement('/home');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading post: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isPosting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _addTagChip(String tag) {
    if (tag.isNotEmpty && !_tagChips.contains(tag)) {
      setState(() {
        _tagChips.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTagChip(int index) {
    setState(() {
      _tagChips.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;
    final currentUser = ref.watch(currentUserProvider).value;

    return GlassBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _isPosting ? 'Posting...' : 'Create Post',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: GlassIconButton(
              icon: Icons.close,
              onTap: _isPosting ? null : () => context.pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _isPosting
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: hasImage && !_isPosting ? _uploadPost : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: hasImage
                                ? const LinearGradient(
                                    colors: [_pink, _coral],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: hasImage ? null : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: hasImage
                                ? [
                                    BoxShadow(
                                      color: _pink.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasImage ? Colors.white : Colors.white38,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          body: currentUser == null
              ? Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login_outlined, size: 64, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(height: 16),
                        Text(
                          'Please login to upload posts',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Progress bar
                    if (_isPosting)
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(_pink),
                            minHeight: 5,
                          ),
                        ),
                      ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image preview area
                            GestureDetector(
                              onTap: _isImageLoading || _isPosting ? null : _showImageSourceSheet,
                              child: Container(
                                width: double.infinity,
                                height: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: _selectedImage != null
                                        ? _pink.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: _isImageLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : _selectedImage != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate_outlined,
                                                size: 64,
                                                color: Colors.white.withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Tap to add photo',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Caption input
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _captionController,
                                enabled: !_isPosting,
                                maxLines: 3,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Write a caption...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Location input
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _locationController,
                                enabled: !_isPosting,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Add location (optional)',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.location_on_outlined, color: Colors.white54),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Tags input
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _tagsController,
                                    enabled: !_isPosting,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Add tags',
                                      hintStyle: const TextStyle(color: Colors.white54),
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(Icons.tag, color: Colors.white54),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        onPressed: _isPosting ? null : () => _addTagChip(_tagsController.text),
                                      ),
                                    ),
                                    onSubmitted: (value) => _addTagChip(value),
                                  ),
                                  
                                  if (_tagChips.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _tagChips.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final tag = entry.value;
                                        return Chip(
                                          label: Text(tag),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () => _removeTagChip(index),
                                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                                          deleteIconColor: Colors.white,
                                          labelStyle: const TextStyle(color: Colors.white),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
