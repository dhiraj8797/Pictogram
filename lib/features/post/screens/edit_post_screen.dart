import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/post.dart';
import '../../../core/models/user.dart';
import '../../../core/services/post_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../widgets/glass_widgets.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _captionController.text = widget.post.caption;
    _locationController.text = widget.post.location ?? '';
    _tags = List.from(widget.post.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    print('DEBUG: Updating post - PostId: ${widget.post.postId}');

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('DEBUG: Current user: ${currentUser.displayName}');

      // Parse tags
      final tagsInput = _tagsController.text.trim();
      final List<String> tags = tagsInput.isNotEmpty
          ? tagsInput.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
          : [];

      print('DEBUG: New caption: ${_captionController.text.trim()}');
      print('DEBUG: New location: ${_locationController.text.trim()}');
      print('DEBUG: New tags: $tags');

      await PostService().updatePost(
        postId: widget.post.postId,
        caption: _captionController.text.trim(),
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        tags: tags,
      );

      print('DEBUG: Post updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Auto-redirect to home after update
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pushReplacement('/home');
          }
        });
      }
    } catch (e) {
      print('DEBUG: Error updating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PostService().deletePost(widget.post.postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Auto-redirect to home after delete
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
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Edit Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: GlassIconButton(
              icon: Icons.close,
              onTap: () => context.pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GlassCard(
                  onTap: _isLoading ? null : _updatePost,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  radius: 20,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post image preview
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          widget.post.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.1),
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50, color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Caption field
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Caption',
                        hintText: 'Write a caption for your post...',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location field
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        hintText: 'Add location',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.white54),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tags field
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _tagsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tags (Optional)',
                        hintText: 'Add tags separated by commas',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.tag_outlined, color: Colors.white54),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Separate tags with commas (e.g., travel, nature, photography)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Delete post button
                  GlassCard(
                    onTap: _deletePost,
                    padding: const EdgeInsets.all(16),
                    backgroundOpacity: 0.1,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Post',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
