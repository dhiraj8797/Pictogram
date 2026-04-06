import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';

class ShareService {
  static Future<void> sharePost(Post post, {String? appDeepLink}) async {
    try {
      // Create shareable content
      String shareText = '';
      
      // Add caption if available
      if (post.caption.isNotEmpty) {
        shareText = '${post.displayName}: ${post.caption}\n\n';
      } else {
        shareText = 'Post by ${post.displayName}\n\n';
      }
      
      // Add app deep link or placeholder
      final deepLink = appDeepLink ?? 'https://pictogram.app/post/${post.postId}';
      shareText += 'View post on PictoGram: $deepLink';
      
      // Add hashtags
      shareText += '\n\n#PictoGram #SocialMedia';
      
      // Share the content
      await Share.share(
        shareText,
        subject: 'Check out this post on PictoGram!',
      );
    } catch (e) {
      // Fallback to clipboard if share fails
      final fallbackText = 'Post by ${post.displayName}: ${post.caption}\n\nView on PictoGram: ${appDeepLink ?? 'https://pictogram.app/post/${post.postId}'}';
      await Clipboard.setData(ClipboardData(text: fallbackText));
      
      // Note: In a real implementation, you'd show a snackbar here
      // For now, the error is silently handled
    }
  }
  
  static Future<void> shareProfile(String userId, String displayName, {String? appDeepLink}) async {
    try {
      final deepLink = appDeepLink ?? 'https://pictogram.app/user/$userId';
      final shareText = 'Follow $displayName on PictoGram!\n\n$deepLink\n\n#PictoGram #SocialMedia';
      
      await Share.share(
        shareText,
        subject: 'Follow $displayName on PictoGram!',
      );
    } catch (e) {
      final fallbackText = 'Follow $displayName on PictoGram!\n\n${appDeepLink ?? 'https://pictogram.app/user/$userId'}';
      await Clipboard.setData(ClipboardData(text: fallbackText));
    }
  }
  
  static Future<void> shareApp({String? appDeepLink}) async {
    try {
      final deepLink = appDeepLink ?? 'https://pictogram.app';
      final shareText = 'Download PictoGram - Amazing social media app!\n\n$deepLink\n\n#PictoGram #SocialMedia #PhotoSharing';
      
      await Share.share(
        shareText,
        subject: 'Download PictoGram!',
      );
    } catch (e) {
      final fallbackText = 'Download PictoGram - Amazing social media app!\n\n${appDeepLink ?? 'https://pictogram.app'}';
      await Clipboard.setData(ClipboardData(text: fallbackText));
    }
  }
}
