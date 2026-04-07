import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/user.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../widgets/glass_widgets.dart';

// Follow service provider
final followServiceProvider = Provider((ref) => FollowService());

// ── Trendily tokens ──────────────────────────────────────────────────────────
const Color _bg     = Color(0xFF0A0010);
const Color _bgMid  = Color(0xFF110018);
const Color _pink   = Color(0xFFE0389A);
const Color _magenta= Color(0xFFCC2299);
const Color _card   = Color(0xFF1A0830);
const Color _border = Color(0x1AFFFFFF);

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  void _showSearchDialog(BuildContext context, WidgetRef ref, AppUser me) {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(me: me),
    );
  }

  void _showNewChatOptions(BuildContext context, WidgetRef ref, AppUser me) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewChatOptions(me: me),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).value;
    if (me == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
            child: CircularProgressIndicator(color: _pink, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context, ref, me),
            icon: const Icon(Icons.search, color: Colors.white70),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context, ref, me),
        backgroundColor: _pink,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ─────────────────────────────────────────────────
          const _BokehBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _card, shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Messages',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                // ── Chat list ───────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Chat>>(
                    stream: ChatService().chatsStream(me.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: _pink, strokeWidth: 2));
                      }
                      final chats = snap.data ?? [];
                      if (chats.isEmpty) {
                        return _EmptyInbox();
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _ChatTile(chat: chats[i], myUid: me.uid),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bokeh background ──────────────────────────────────────────────────────────
class _BokehBackground extends StatelessWidget {
  const _BokehBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _BokehPainter(),
    );
  }
}

class _BokehPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bg,
    );
    final spots = [
      [0.18, 0.12, 90.0, 0x33CC1177],
      [0.82, 0.08, 70.0, 0x2299007A],
      [0.50, 0.35, 110.0, 0x1A8800AA],
      [0.10, 0.55, 80.0, 0x2ABB0066],
      [0.88, 0.48, 100.0, 0x22990088],
      [0.30, 0.78, 95.0, 0x22CC0055],
      [0.72, 0.72, 85.0, 0x1F9900BB],
      [0.55, 0.92, 75.0, 0x25AA0077],
    ];
    for (final s in spots) {
      final cx = size.width * (s[0] as double);
      final cy = size.height * (s[1] as double);
      final r = s[2] as double;
      final color = Color(s[3] as int);
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74, height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _pink.withValues(alpha: 0.18),
                _magenta.withValues(alpha: 0.08)
              ]),
              shape: BoxShape.circle,
              border: Border.all(color: _pink.withValues(alpha: 0.22)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _pink, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Visit a profile and tap Message to start a chat',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Single chat row ───────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final Chat chat;
  final String myUid;
  const _ChatTile({required this.chat, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final name  = chat.otherName(myUid);
    final photo = chat.otherPhoto(myUid);
    final otherId = chat.otherUid(myUid);
    final hasUnread = chat.unreadCount > 0;

    return GestureDetector(
      onTap: () => context.push('/chat/${chat.chatId}',
          extra: {'otherName': name, 'otherPhoto': photo, 'otherUid': otherId}),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasUnread
                  ? _pink.withValues(alpha: 0.08)
                  : _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUnread
                    ? _pink.withValues(alpha: 0.28)
                    : _border,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [_pink, _magenta],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: photo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _fallbackAvatar(),
                          )
                        : _fallbackAvatar(),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        chat.lastMessage.isEmpty
                            ? 'Start a conversation'
                            : chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread
                              ? Colors.white70
                              : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [_pink, _magenta]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${chat.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() => Container(
        color: const Color(0xFF2A0830),
        child: const Icon(Icons.person, color: Colors.white54, size: 24),
      );
}

// ── Search Dialog ─────────────────────────────────────────────────────────────
class _SearchDialog extends ConsumerStatefulWidget {
  final AppUser me;
  const _SearchDialog({required this.me});

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  final _controller = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() => _searching = true);
    
    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();
      
      setState(() {
        _searchResults = users.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .where((user) => user.uid != widget.me.uid)
            .toList();
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
                const Expanded(
                  child: Text(
                    'Search Users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by username...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                ),
                onChanged: _searchUsers,
              ),
            ),
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator(color: _pink))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _UserSearchResult(user: user, me: widget.me);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User Search Result ───────────────────────────────────────────────────────
class _UserSearchResult extends ConsumerWidget {
  final AppUser user;
  final AppUser me;
  const _UserSearchResult({required this.user, required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _canMessage(ref, me.uid, user.uid),
      builder: (context, snapshot) {
        final canMessage = snapshot.data ?? false;
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: user.profileImage?.isNotEmpty == true
                ? CachedNetworkImageProvider(user.profileImage!)
                : null,
            child: user.profileImage?.isNotEmpty != true
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          subtitle: canMessage
              ? const Text('Tap to message', style: TextStyle(color: Colors.white54))
              : const Text('Follow each other to message', style: TextStyle(color: Colors.red)),
          trailing: canMessage
              ? Icon(Icons.message, color: _pink)
              : Icon(Icons.lock, color: Colors.white54),
          onTap: canMessage ? () => _startChat(context, ref, user, me) : null,
        );
      },
    );
  }

  Future<bool> _canMessage(WidgetRef ref, String myUid, String otherUid) async {
    final followService = ref.read(followServiceProvider);
    final iFollow = await followService.isFollowing(myUid, otherUid);
    final theyFollow = await followService.isFollowing(otherUid, myUid);
    return iFollow && theyFollow;
  }

  void _startChat(BuildContext context, WidgetRef ref, AppUser other, AppUser me) {
    final chatService = ChatService();
    
    chatService.getOrCreateChat(
      myUid: me.uid,
      myName: me.displayName,
      myPhoto: me.profileImage ?? '',
      otherUid: other.uid,
      otherName: other.displayName,
      otherPhoto: other.profileImage ?? '',
    ).then((chatId) {
      Navigator.pop(context); // Close search dialog
      Navigator.pop(context); // Close messages screen
      context.push('/chat/$chatId', extra: {
        'otherName': other.displayName,
        'otherPhoto': other.profileImage ?? '',
        'otherUid': other.uid,
      });
    });
  }
}

// ── New Chat Options Bottom Sheet ─────────────────────────────────────────────
class _NewChatOptions extends ConsumerWidget {
  final AppUser me;
  const _NewChatOptions({required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Start New Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Options
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.search,
                  title: 'Search Users',
                  subtitle: 'Find people to message',
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => _SearchDialog(me: me),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.contacts,
                  title: 'Message Mutual Followers',
                  subtitle: 'Chat with people you follow and who follow you back',
                  onTap: () => _showMutualFollowers(context, ref, me),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.info_outline,
                  title: 'How Messaging Works',
                  subtitle: 'Learn about messaging rules',
                  onTap: () => _showMessagingInfo(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showMutualFollowers(BuildContext context, WidgetRef ref, AppUser me) {
    Navigator.pop(context);
    // TODO: Show mutual followers list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mutual followers feature coming soon!')),
    );
  }

  void _showMessagingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Messaging Rules',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• You can only message users who follow you back',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '• Both users must follow each other (mutual follow)',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '• Visit user profiles and tap "Message" to start chatting',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _pink)),
          ),
        ],
      ),
    );
  }
}

// ── Option Tile ───────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _pink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ── Fallback Avatar ─────────────────────────────────────────────────────────────
Widget _fallbackAvatar() => Container(
      color: const Color(0xFF2A0830),
      child: const Icon(Icons.person, color: Colors.white54, size: 24),
    );
