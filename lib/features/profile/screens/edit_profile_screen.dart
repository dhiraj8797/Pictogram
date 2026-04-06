import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/models/user.dart';
import '../../../widgets/glass_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeSetup;
  
  const EditProfileScreen({super.key, this.isFirstTimeSetup = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  
  bool _isLoading = false;
  String? _profileImageUrl;
  bool _isPrivate = false;
  bool _verificationBadge = false;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      setState(() {
        _displayNameController.text = currentUser.displayName;
        _bioController.text = currentUser.bio;
        _locationController.text = currentUser.location ?? '';
        _phoneNumberController.text = currentUser.phoneNumber ?? '';
        _dateOfBirth = currentUser.dateOfBirthDateTime;
        _profileImageUrl = currentUser.profileImage;
        _isPrivate = currentUser.isPrivate;
        _verificationBadge = currentUser.verificationBadge;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImageUrl = image.path;
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
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF7A3CFF),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF2D0B73),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'PictoGram needs access to your gallery to update your profile picture. '
          'Please enable gallery access in your device settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _openAppSettings() {
    // Open app settings
  }

  Future<void> _saveProfile() async {
    print('Save profile called');
    print('Display name: "${_displayNameController.text}"');
    print('Is loading: $_isLoading');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    print('Form validation passed');

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        print('No user logged in');
        throw Exception('No user logged in');
      }
      
      print('Current user: ${currentUser.displayName}');

      final authService = ref.read(authServiceProvider);
      
      String? finalProfileImageUrl = _profileImageUrl;
      
      // If profileImage is a local file path, upload to Storage
      if (_profileImageUrl != null && !_profileImageUrl!.startsWith('http')) {
        try {
          print('Uploading new profile image...');
          final result = await authService.updateProfileImage(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim(),
            profileImage: _profileImageUrl,
          ).timeout(const Duration(seconds: 30));
          
          if (result.success) {
            finalProfileImageUrl = _profileImageUrl;
          } else {
            throw Exception(result.error ?? 'Unknown error');
          }
          
          print('Profile image uploaded successfully: $finalProfileImageUrl');
        } catch (e) {
          print('Image upload failed: $e');
          
          if (mounted) {
            String userMessage = 'Profile image upload failed';
            
            if (e.toString().contains('timeout')) {
              userMessage = 'Upload timed out. Using your current profile picture.';
            } else if (e.toString().contains('network')) {
              userMessage = 'Network error. Using your current profile picture.';
            } else if (e.toString().contains('permission')) {
              userMessage = 'Permission denied. Using your current profile picture.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          finalProfileImageUrl = currentUser.profileImage;
        }
      }
      
      print('Updating profile data...');
      await authService.updateProfile(
        uid: currentUser.uid,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: finalProfileImageUrl,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        dateOfBirth: _dateOfBirth,
        isPrivate: _isPrivate,
        phoneNumber: _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
      ).timeout(const Duration(seconds: 15));
      
      print('Profile data updated successfully');

      await ref.refresh(currentUserProvider.future).timeout(const Duration(seconds: 10));

      try {
        await AnalyticsService().trackCustomEvent('profile_updated', {
          'fields_updated': ['display_name', 'bio', 'profile_image', 'location', 'date_of_birth', 'privacy'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Analytics tracking failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('Navigating after save...');
        // For first-time setup, navigate to home, otherwise go back
        if (widget.isFirstTimeSetup) {
          print('First-time setup, navigating to home');
          context.pushReplacement('/home');
        } else {
          print('Regular edit, going back');
          context.pop(true);
        }
      }
    } catch (e) {
      print('Save profile error: $e');
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        
        if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Failed to update profile: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    GlassIconButton(
                      icon: _isLoading ? Icons.refresh : Icons.check_rounded,
                      onTap: _isLoading ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Image
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 58,
                                  backgroundImage: _profileImageUrl != null
                                      ? (_profileImageUrl!.startsWith('http')
                                          ? NetworkImage(_profileImageUrl!)
                                          : FileImage(File(_profileImageUrl!)) as ImageProvider)
                                      : null,
                                  child: _profileImageUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Colors.white70)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7A3CFF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Display Name
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: TextFormField(
                            controller: _displayNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Enter your display name',
                              prefixIcon: Icon(Icons.person, color: Colors.white70),
                              labelStyle: TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Display name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Display name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: TextFormField(
                            controller: _bioController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Bio',
                              hintText: 'Tell us about yourself',
                              prefixIcon: Icon(Icons.info_outline, color: Colors.white70),
                              labelStyle: TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                            maxLength: 150,
                            validator: (value) {
                              if (value != null && value.trim().length > 150) {
                                return 'Bio must be less than 150 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: TextFormField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'Enter your location',
                              prefixIcon: Icon(Icons.location_on_outlined, color: Colors.white70),
                              labelStyle: TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value != null && value.trim().length > 50) {
                                return 'Location must be less than 50 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: TextFormField(
                            controller: _phoneNumberController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              hintText: 'Enter your mobile number',
                              prefixIcon: Icon(Icons.phone_outlined, color: Colors.white70),
                              labelStyle: TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,20}$');
                                if (!phoneRegex.hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: InkWell(
                            onTap: _selectDateOfBirth,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                hintText: 'Select your date of birth',
                                prefixIcon: Icon(Icons.cake_outlined, color: Colors.white70),
                                suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
                                labelStyle: TextStyle(color: Colors.white70),
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                              ),
                              child: Text(
                                _dateOfBirth != null
                                    ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _dateOfBirth != null ? Colors.white : Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Privacy Settings
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline, color: Colors.white70),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Private Account',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isPrivate,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPrivate = value;
                                      });
                                    },
                                    activeColor: const Color(0xFF7A3CFF),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Only approved followers can see your posts',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          onTap: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Saving...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Save Profile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
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
