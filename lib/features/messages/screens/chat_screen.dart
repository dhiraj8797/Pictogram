import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/providers/auth_provider.dart';

// ── Design tokens (matches image) ────────────────────────────────────────────
const Color _bg       = Color(0xFF0A0010);
const Color _bgMid    = Color(0xFF110018);
const Color _bubbleMe = Color(0xFF2D1048);
const Color _bubbleThem = Color(0xFF1C0B30);
const Color _pink     = Color(0xFFE0389A);
const Color _magenta  = Color(0xFFCC2299);
const Color _border   = Color(0x1AFFFFFF);
const Color _iconBg   = Color(0x22FFFFFF);

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherName;
  final String otherPhoto;
  final String otherUid;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherPhoto,
    required this.otherUid,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _chatService = ChatService();
  bool _sending = false;
  bool? _isMutual;
  bool _checkingMutual = true;
  late AnimationController _dotAnim;

  @override
  void initState() {
    super.initState();
    _dotAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
      _checkMutual();
    });
  }

  @override
  void dispose() {
    _dotAnim.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _checkMutual() async {
    final me = ref.read(currentUserProvider).value;
    if (me == null) {
      if (mounted) setState(() { _checkingMutual = false; _isMutual = false; });
      return;
    }
    final fs = FollowService();
    final iFollow = await fs.isFollowing(me.uid, widget.otherUid);
    final theyFollow = await fs.isFollowing(widget.otherUid, me.uid);
    if (mounted) setState(() { _isMutual = iFollow && theyFollow; _checkingMutual = false; });
  }

  void _markRead() {
    final me = ref.read(currentUserProvider).value;
    if (me != null) _chatService.markRead(widget.chatId, me.uid);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(currentUserProvider).value;
    if (me == null) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _chatService.sendMessage(
        chatIdVal: widget.chatId,
        senderId: me.uid,
        text: text,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).value;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BokehBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  name: widget.otherName,
                  photo: widget.otherPhoto,
                  otherUid: widget.otherUid,
                ),
                Expanded(
                  child: _checkingMutual
                      ? const Center(child: CircularProgressIndicator(color: _pink, strokeWidth: 2))
                      : _isMutual == false
                          ? _NotMutualState(name: widget.otherName, otherUid: widget.otherUid)
                          : me == null
                              ? const SizedBox.shrink()
                              : StreamBuilder<List<ChatMessage>>(
                                  stream: _chatService.messagesStream(widget.chatId),
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return const Center(child: CircularProgressIndicator(color: _pink, strokeWidth: 2));
                                    }
                                    final msgs = snap.data!;
                                    if (msgs.isNotEmpty) _scrollToBottom();
                                    return _buildList(msgs, me.uid);
                                  },
                                ),
                ),
                if (_isMutual == true)
                  _InputBar(controller: _controller, sending: _sending, onSend: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ChatMessage> msgs, String myUid) {
    if (msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pink.withValues(alpha: 0.12),
                border: Border.all(color: _pink.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.waving_hand_rounded, color: _pink.withValues(alpha: 0.7), size: 30),
            ),
            const SizedBox(height: 14),
            Text('Say hi to ${widget.otherName}!',
                style: const TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final items = <_ListItem>[];
    String? lastLabel;
    for (int i = 0; i < msgs.length; i++) {
      final label = _timeLabel(msgs[i].timestamp);
      if (label != lastLabel) {
        items.add(_ListItem.separator(label));
        lastLabel = label;
      }
      final isMe = msgs[i].senderId == myUid;
      final showAvatar = !isMe &&
          (i == msgs.length - 1 || msgs[i + 1].senderId != msgs[i].senderId);
      items.add(_ListItem.msg(msgs[i], showAvatar));
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isSeparator) return _TimeSeparator(label: item.separator!);
        return _MessageBubble(
          msg: item.msg!,
          isMe: item.msg!.senderId == myUid,
          showAvatar: item.showAvatar,
          otherPhoto: widget.otherPhoto,
          otherName: widget.otherName,
        );
      },
    );
  }

  static String _timeLabel(Timestamp ts) {
    final dt = ts.toDate();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _ListItem {
  final String? separator;
  final ChatMessage? msg;
  final bool showAvatar;
  _ListItem.separator(this.separator) : msg = null, showAvatar = false;
  _ListItem.msg(this.msg, this.showAvatar) : separator = null;
  bool get isSeparator => separator != null;
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

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String name;
  final String photo;
  final String otherUid;
  const _TopBar(
      {required this.name, required this.photo, required this.otherUid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          // Back
          _iconBtn(Icons.arrow_back_ios_new_rounded, () => context.pop()),
          const SizedBox(width: 10),
          // Avatar with gradient ring
          GestureDetector(
            onTap: () => context.push('/profile/$otherUid'),
            child: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_pink, _magenta],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fb(),
                      )
                    : _fb(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + online indicator
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile/$otherUid'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CD964),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Online',
                          style: TextStyle(
                              color: Color(0xFF4CD964),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _iconBtn(Icons.videocam_outlined, () {}),
          const SizedBox(width: 8),
          _iconBtn(Icons.more_horiz_rounded, () {}),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 0.8)),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      );

  Widget _fb() => Container(
      color: const Color(0xFF1A0028),
      child: const Icon(Icons.person, color: Colors.white38, size: 22));
}

// ── Not-mutual state ──────────────────────────────────────────────────────────
class _NotMutualState extends StatelessWidget {
  final String name;
  final String otherUid;
  const _NotMutualState({required this.name, required this.otherUid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pink.withValues(alpha: 0.10),
                border: Border.all(color: _pink.withValues(alpha: 0.30)),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: _pink, size: 32),
            ),
            const SizedBox(height: 18),
            const Text('Mutual Follow Required',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'You can only message $name if you both follow each other.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/profile/$otherUid'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_pink, _magenta]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Text("View $name's Profile",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time separator ────────────────────────────────────────────────────────────
class _TimeSeparator extends StatelessWidget {
  final String label;
  const _TimeSeparator({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final bool showAvatar;
  final String otherPhoto;
  final String otherName;
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.otherPhoto,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final time = _fmt(msg.timestamp);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 20),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 4, top: showAvatar && !isMe ? 10 : 0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left avatar (them)
          if (!isMe)
            SizedBox(
              width: 40,
              child: showAvatar
                  ? Column(
                      children: [
                        _avatar(otherPhoto),
                        const SizedBox(height: 2),
                        Text(otherName.split(' ').first,
                            style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    )
                  : null,
            ),
          const SizedBox(width: 8),
          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: isMe ? _bubbleMe : _bubbleThem,
                borderRadius: radius,
                border: Border.all(
                    color: isMe
                        ? _pink.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.07),
                    width: 0.7),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.45)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(msg.read ? Icons.done_all_rounded : Icons.check_rounded,
                            color: msg.read ? _pink : Colors.white38, size: 13),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _avatar(String photo) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_pink, _magenta], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: photo.isNotEmpty
              ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fb())
              : _fb(),
        ),
      );
  Widget _fb() => Container(color: const Color(0xFF1A0028), child: const Icon(Icons.person, color: Colors.white38, size: 16));
  static String _fmt(Timestamp ts) {
    final dt = ts.toDate();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.sending, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg.withValues(alpha: 0.95),
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Camera
          _sideBtn(Icons.camera_alt_outlined, () {}),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0830),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: const InputDecoration(
                  hintText: 'Send a message...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14.5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Emoji or spacer
          _hasText ? const SizedBox(width: 0) : _sideBtn(Icons.mood_rounded, () {}),
          const SizedBox(width: 8),
          // Mic / Send
          GestureDetector(
            onTap: _hasText ? widget.onSend : null,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_pink, _magenta], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: widget.sending
                  ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_hasText ? Icons.send_rounded : Icons.mic_none_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle, border: Border.all(color: _border, width: 0.7)),
          child: Icon(icon, color: Colors.white60, size: 20),
        ),
      );
}
