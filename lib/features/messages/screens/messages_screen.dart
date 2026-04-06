import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/providers/auth_provider.dart';

// ── Trendily tokens ──────────────────────────────────────────────────────────
const Color _bg     = Color(0xFF0A0010);
const Color _bgMid  = Color(0xFF110018);
const Color _pink   = Color(0xFFE0389A);
const Color _magenta= Color(0xFFCC2299);
const Color _card   = Color(0xFF1A0830);
const Color _border = Color(0x1AFFFFFF);

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).value;
    if (me == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
            child: CircularProgressIndicator(color: _pink, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Start New Chat',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Visit a user\'s profile and tap the Message button to start a conversation. You can only message users who follow you back.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it', style: TextStyle(color: _pink)),
                ),
              ],
            ),
          );
        },
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
