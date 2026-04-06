import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/collaboration.dart';
import '../../../core/services/collaboration_service.dart';
import '../../../core/services/auth_service.dart';

class CollaborationInvitesScreen extends StatefulWidget {
  const CollaborationInvitesScreen({super.key});

  @override
  State<CollaborationInvitesScreen> createState() => _CollaborationInvitesScreenState();
}

class _CollaborationInvitesScreenState extends State<CollaborationInvitesScreen> {
  final CollaborationService _collaborationService = CollaborationService();
  final AuthService _authService = AuthService();
  List<Collaboration> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingInvites();
  }

  Future<void> _loadPendingInvites() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final invites = await _collaborationService.getPendingInvites(user.uid);
        setState(() {
          _pendingInvites = invites;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invites: $e')),
        );
      }
    }
  }

  Future<void> _acceptInvite(Collaboration invite) async {
    try {
      await _collaborationService.acceptCollaborationInvite(invite.collaborationId);
      setState(() {
        _pendingInvites.removeWhere((i) => i.collaborationId == invite.collaborationId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaboration accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvite(Collaboration invite) async {
    try {
      await _collaborationService.rejectCollaborationInvite(invite.collaborationId);
      setState(() {
        _pendingInvites.removeWhere((i) => i.collaborationId == invite.collaborationId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collaboration declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a0033),
        title: const Text(
          'Collaboration Invites',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _pendingInvites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_add_outlined,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending collaboration invites',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When someone invites you to collaborate,\nit will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.white,
                  onRefresh: _loadPendingInvites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingInvites.length,
                    itemBuilder: (context, index) {
                      final invite = _pendingInvites[index];
                      return _buildInviteCard(invite);
                    },
                  ),
                ),
    );
  }

  Widget _buildInviteCard(Collaboration invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D0B73),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inviter info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: invite.postOwnerProfileImage.isNotEmpty
                      ? CachedNetworkImageProvider(invite.postOwnerProfileImage)
                      : null,
                  child: invite.postOwnerProfileImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.postOwnerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Invited you to collaborate',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Message if exists
            if (invite.message != null && invite.message!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${invite.message}"',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (invite.message != null && invite.message!.isNotEmpty)
              const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptInvite(invite),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D0B73),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectInvite(invite),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
