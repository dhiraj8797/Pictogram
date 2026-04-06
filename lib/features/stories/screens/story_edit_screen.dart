import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/story_service.dart';
import '../../../core/providers/auth_provider.dart';

class StoryEditScreen extends ConsumerStatefulWidget {
  final File? imageFile;

  const StoryEditScreen({super.key, this.imageFile});

  @override
  ConsumerState<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends ConsumerState<StoryEditScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  File? _selectedImage;
  bool _isUploading = false;
  bool _showEmojiPicker = false;
  bool _showStickers = false;
  bool _showLocation = false;
  List<String> _locationSuggestions = [];
  bool _isLocationLoading = false;

  // Stickers data
  final List<String> _stickers = [
    '❤️', '😂', '🔥', '😍', '👍', '😎', '🎉', '🤔', '😴', '🤗',
    '🎈', '🎨', '🌟', '💫', '✨', '🌈', '☀️', '🌙', '⭐', '💖',
    '🎵', '🎶', '🎧', '🎤', '🎸', '🥁', '🎹', '🎺', '🎷', '🎻',
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓', '🏸', '🥊', '🥋',
    '🍕', '🍔', '🍟', '🌭', '🍿', '🥤', '🍺', '☕', '🍵', '🥛',
    '🌍', '🌎', '🌏', '🗺', '🗽', '🏔', '⛰️', '🏕️', '🏖️', '🏝️'
  ];

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.imageFile;
    if (_selectedImage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImageFromGallery();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _locationController.dispose();
    _textFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to take photo')),
        );
      }
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

  void _onStickerSelected(String sticker) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = text.replaceRange(selection.start, selection.end, sticker);
    final newSelection = selection.start + sticker.length;
    
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
        const SnackBar(content: Text('Please login to create a story')),
      );
      return;
    }

    setState(() => _isUploading = true);

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

      setState(() => _isUploading = false);

      final addAnother = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Story uploaded!', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Do you want to add another story?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Done', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Another', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (addAnother == true) {
        // Reset screen and pick a new image
        _textController.clear();
        _locationController.clear();
        setState(() {
          _selectedImage = null;
          _showEmojiPicker = false;
          _showStickers = false;
          _showLocation = false;
        });
        _pickImageFromGallery();
      } else {
        context.go('/home');
      }
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
      body: SafeArea(
        child: Column(
          children: [
            // Main Content
            Expanded(
              child: Stack(
                children: [
                  // Full-screen image preview
                  Positioned.fill(
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.purple[600]!.withValues(alpha: 0.8),
                                        Colors.pink[600]!.withValues(alpha: 0.8),
                                        Colors.orange[600]!.withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 80, color: Colors.white),
                                        SizedBox(height: 16),
                                        Text('Add Photo',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                        SizedBox(height: 8),
                                        Text('Tap to select from gallery',
                                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                  
                  // Add Photo Button (when no image selected)
                  if (_selectedImage == null)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          color: Colors.transparent,
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
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _textController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Location Overlay
                  if (_locationController.text.isNotEmpty)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _locationController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Top Bar with Navigation
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                          const Spacer(),
                          const Text(
                            'Create Story',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
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
                    ),
                  ),

                  // Bottom Tool Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Text Tool
                          _buildSmallToolButton(
                            icon: Icons.text_fields,
                            onTap: () {
                              setState(() {
                                _showEmojiPicker = false;
                                _showStickers = false;
                                _showLocation = false;
                              });
                              _textFocusNode.requestFocus();
                            },
                            isActive: _textFocusNode.hasFocus,
                          ),

                          // Sticker Tool
                          _buildSmallToolButton(
                            icon: Icons.emoji_emotions_outlined,
                            onTap: () {
                              setState(() {
                                _showEmojiPicker = false;
                                _showStickers = !_showStickers;
                                _showLocation = false;
                                _textFocusNode.unfocus();
                                _locationFocusNode.unfocus();
                              });
                            },
                            isActive: _showStickers,
                          ),

                          // Location Tool
                          _buildSmallToolButton(
                            icon: Icons.location_on_outlined,
                            onTap: () {
                              setState(() {
                                _showEmojiPicker = false;
                                _showStickers = false;
                                _showLocation = !_showLocation;
                                _textFocusNode.unfocus();
                                _locationFocusNode.requestFocus();
                              });
                            },
                            isActive: _showLocation,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Text Input Panel (Overlay)
                  if (_textFocusNode.hasFocus)
                    Positioned(
                      bottom: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Type your story text...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(0),
                          ),
                          onChanged: (value) {
                            setState(() {}); // Rebuild to update text overlay
                          },
                        ),
                      ),
                    ),

                  // Location Search Panel (Overlay)
                  if (_showLocation)
                    Positioned(
                      top: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _locationController,
                              focusNode: _locationFocusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search location...',
                                hintStyle: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(Icons.search, color: Colors.white),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(0),
                              ),
                            ),
                            if (_locationSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _locationSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = _locationSuggestions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.location_on, color: Colors.white, size: 20),
                                      title: Text(
                                        suggestion,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                      onTap: () {
                                        _locationController.text = suggestion;
                                        setState(() {
                                          _showLocation = false;
                                          _locationSuggestions.clear();
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Stickers Panel (Overlay)
                  if (_showStickers)
                    Positioned(
                      bottom: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _stickers.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _onStickerSelected(_stickers[index]),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _stickers[index],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            );
                          },
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

  Widget _buildSmallToolButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.blue.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
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
    );
  }
}
