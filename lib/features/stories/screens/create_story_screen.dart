import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_settings/app_settings.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/services/story_service.dart';
import '../../../core/providers/auth_provider.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isImageLoading = false;
  bool _showEmojiPicker = false;
  bool _isLocationLoading = false;
  List<String> _locationSuggestions = [];

  @override
  void dispose() {
    _textController.dispose();
    _locationController.dispose();
    _textFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to pick image';
        
        if (e.toString().contains('permanently denied')) {
          errorMessage = 'Permission permanently denied. Please enable gallery access in app settings.';
          _showPermissionDialog();
        } else if (e.toString().contains('permission is required')) {
          errorMessage = 'Gallery permission is required to select photos.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: e.toString().contains('permanently denied')
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: _openAppSettings,
                  )
                : null,
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
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Gallery Permission Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PictoGram needs access to your gallery to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Select photos for stories'),
            Text('• Share visual content'),
            Text('• Create engaging stories'),
            SizedBox(height: 12),
            Text(
              'Please enable gallery access to continue creating stories.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please manually open Settings > Apps > PictoGram > Permissions'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 2) {
      setState(() {
        _locationSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Simulate location search (in real app, use Places API)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final suggestions = [
        '$query, New York, NY',
        '$query, Los Angeles, CA',
        '$query, Chicago, IL',
        '$query, Houston, TX',
        '$query, Phoenix, AZ',
      ].where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase())).toList();
      
      setState(() {
        _locationSuggestions = suggestions.take(5).toList();
      });
    } catch (e) {
      print('Location search error: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji.emoji);
    final newSelection = selection.start + emoji.emoji.length;
    
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelection),
    );
  }

  Future<void> _createStory() async {
    if (_selectedImage == null && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo or text for your story')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create stories')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final storyText = _textController.text.trim();
      final location = _locationController.text.trim();

      final story = await _storyService.createStory(
        userId: currentUser.uid,
        displayName: currentUser.displayName,
        userProfileImage: currentUser.profileImage ?? '',
        imageFile: _selectedImage,
        text: storyText.isNotEmpty ? storyText : null,
        location: location.isNotEmpty ? location : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form and navigate to home
      setState(() {
        _selectedImage = null;
        _textController.clear();
        _locationController.clear();
      });

      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Story creation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Create Story'),
        centerTitle: true,
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createStory,
              child: const Text(
                'Share',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Story Preview Area — 16:9
            Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background Image or Color
                    if (_selectedImage != null)
                      Positioned.fill(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple[400]!,
                              Colors.pink[400]!,
                              Colors.orange[400]!,
                            ],
                          ),
                        ),
                      ),
                    
                    // Text Overlay
                    if (_textController.text.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              _textController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Add Photo Button
                    if (_selectedImage == null)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _isImageLoading ? null : () => _pickImage(),
                              icon: Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

            // Text Input Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                children: [
                  // Text Input
                  TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add text to your story...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  // Emoji Button
                  Container(
                    height: 1,
                    color: Colors.grey[700],
                  ),
                  
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                          if (_showEmojiPicker) {
                            _textFocusNode.unfocus();
                            _locationFocusNode.unfocus();
                          }
                        },
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: _showEmojiPicker ? Colors.blue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Emoji',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Location Input Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add location...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey,
                      ),
                      suffixIcon: _isLocationLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: _searchLocation,
                  ),
                  
                  // Location Suggestions
                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      height: 1,
                      color: Colors.grey[700],
                    ),
                  
                  ..._locationSuggestions.map((suggestion) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _locationController.text = suggestion;
                          _locationSuggestions = [];
                        });
                        _locationFocusNode.unfocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Emoji Picker
            if (_showEmojiPicker)
              Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    _onEmojiSelected(emoji);
                  },
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 32,
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      backgroundColor: Colors.grey[900]!,
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                    skinToneConfig: const SkinToneConfig(
                      enabled: true,
                      dialogBackgroundColor: Color(0xFF2C2C2C),
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: Colors.grey[900]!,
                      iconColorSelected: Colors.blue,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: Colors.grey[900]!,
                      showSearchViewButton: true,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: Colors.grey[900]!,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
