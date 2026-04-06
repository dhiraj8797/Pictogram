import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/notification.dart';
import '../../../core/models/post.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  Stream<List<AppNotification>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initNotificationsStream();
  }

  void _initNotificationsStream() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    print('DEBUG: Initializing real-time notifications stream for user: ${currentUser.uid}');
    
    _notificationsStream = _notificationService.getNotificationsStream(currentUser.uid);
    
    _notificationsStream!.listen(
      (notifications) {
        print('DEBUG: Real-time update - Received ${notifications.length} notifications');
        for (var notification in notifications) {
          print('DEBUG: Notification - Type: ${notification.type}, Message: ${notification.message}, Actor: ${notification.actorName}');
        }
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print('DEBUG: Error in notifications stream: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading notifications: $error')),
          );
        }
      },
    );
  }

  Future<void> _refreshNotifications() async {
    // Stream will auto-update, but we can force a refresh if needed
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      await _notificationService.markAllNotificationsAsRead(currentUser.uid);
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking all notifications as read: $e')),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = Timestamp.now();
    final difference = now.seconds - timestamp.seconds;
    
    if (difference < 60) {
      return 'just now';
    } else if (difference < 3600) {
      final minutes = (difference / 60).floor();
      return '${minutes}m ago';
    } else if (difference < 86400) {
      final hours = (difference / 3600).floor();
      return '${hours}h ago';
    } else {
      final days = (difference / 86400).floor();
      return '${days}d ago';
    }
  }

  Widget _buildNotificationIcon(String type) {
    switch (type) {
      case NotificationType.like:
        return const Icon(Icons.favorite, color: Colors.red, size: 20);
      case NotificationType.comment:
        return const Icon(Icons.mode_comment, color: Colors.blue, size: 20);
      case NotificationType.follow:
        return const Icon(Icons.person_add, color: Colors.purple, size: 20);
      case NotificationType.mention:
        return const Icon(Icons.alternate_email, color: Colors.orange, size: 20);
      default:
        return const Icon(Icons.notifications, color: Colors.grey, size: 20);
    }
  }

  Future<String?> _getPostImageUrl(String? postId) async {
    if (postId == null) return null;
    try {
      final post = await _postService.getPostById(postId);
      return post?.imageUrl;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When people interact with you, you\'ll see it here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification.isRead;

                      return InkWell(
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notification.notificationId);
                          }
                          
                          // Navigate to post if postId exists
                          if (notification.postId != null) {
                            context.push('/post/${notification.postId}');
                          }
                        },
                        child: Container(
                          color: isRead ? Colors.transparent : Colors.white.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Actor avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: notification.actorProfileImage.isNotEmpty
                                    ? CachedNetworkImageProvider(notification.actorProfileImage)
                                    : null,
                                child: notification.actorProfileImage.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Notification content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: notification.actorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' ${notification.message ?? ''}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(notification.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Post thumbnail or icon
                              const SizedBox(width: 12),
                              if (notification.postId != null)
                                FutureBuilder<String?>(
                                  future: _getPostImageUrl(notification.postId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: snapshot.data!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey.shade800,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.grey),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey.shade800,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return _buildNotificationIcon(notification.type);
                                    }
                                  },
                                )
                              else
                                _buildNotificationIcon(notification.type),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
