class AppConstants {
  // App info
  static const String appName = 'PictoGram';
  static const String appVersion = '1.0.0';
  
  // Storage limits
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Story settings
  static const Duration storyDuration = Duration(hours: 24);
  
  // Pagination
  static const int postsPerPage = 10;
  static const int usersPerPage = 20;
  static const int searchResultsLimit = 20;
  static const int profilePostsLimit = 9;
  
  // Character limits
  static const int maxCaptionLength = 2200;
  static const int maxBioLength = 150;
  static const int maxCommentLength = 500;
  static const int maxDisplayNameLength = 50;
  static const int minDisplayNameLength = 2;
  
  // Follow system names
  static const String followersName = 'Supporters';
  static const String followingName = 'Circles';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String followsCollection = 'follows';
  static const String storiesCollection = 'stories';
  static const String notificationsCollection = 'notifications';
  
  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String postImagesPath = 'posts';
  static const String storyImagesPath = 'stories';
  
  // UI Constants
  static const double defaultRadius = 20.0;
  static const double largeRadius = 24.0;
  static const double smallRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Network timeouts
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  
  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String verificationRequired = 'You need to verify your identity to comment.';
  static const String userNotFoundError = 'User not found';
  static const String postNotFoundError = 'Post not found';
  static const String permissionDeniedError = 'Permission denied';
  static const String rateLimitError = 'You have reached your limit. Please try again later.';
  
  // Success messages
  static const String postUploadSuccess = 'Photo uploaded successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String followSuccess = 'Followed successfully!';
  static const String unfollowSuccess = 'Unfollowed successfully!';
  static const String signupSuccess = 'Account created successfully! Let\'s complete your profile.';
  static const String loginSuccess = 'Login successful!';
  
  // UI Text
  static const String followButtonText = 'Follow';
  static const String followingButtonText = 'Following';
  static const String editProfileButtonText = 'Edit Profile';
  static const String saveButtonText = 'Save Profile';
  static const String cancelButtonText = 'Cancel';
  static const String retryButtonText = 'Retry';
  
  // Route names
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String searchRoute = '/search';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  
  // Special users
  static const String officialUserId = 'pictogram_official';
  static const String officialUserKeyword = 'pictogram';
  
  // Image dimensions
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 800;
  static const int imageQuality = 80;
  
  // Demo OTP for testing
  static const String demoOtp = '123456';
  static const int otpLength = 6;
  static const Duration otpResendDelay = Duration(seconds: 60);
}
