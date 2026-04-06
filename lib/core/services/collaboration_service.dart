import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collaboration.dart';
import '../models/user.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final NotificationService _notificationService = NotificationService();

  /// Send a collaboration invite to a user for a post
  Future<Collaboration> sendCollaborationInvite({
    required String postId,
    required User postOwner,
    required User invitedUser,
    String? message,
  }) async {
    try {
      // Check if invite already exists
      final existingQuery = await _firestore
          .collection('collaborations')
          .where('postId', isEqualTo: postId)
          .where('invitedUserId', isEqualTo: invitedUser.uid)
          .where('status', isEqualTo: CollaborationStatus.pending)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Collaboration invite already sent to this user');
      }

      // Check if already a collaborator
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final collaborators = List<String>.from(data['collaboratorIds'] ?? []);
        if (collaborators.contains(invitedUser.uid)) {
          throw Exception('User is already a collaborator on this post');
        }
      }

      final collaborationRef = _firestore.collection('collaborations').doc();
      final collaboration = Collaboration(
        collaborationId: collaborationRef.id,
        postId: postId,
        postOwnerId: postOwner.uid,
        postOwnerName: postOwner.displayName,
        postOwnerProfileImage: postOwner.profileImage ?? '',
        invitedUserId: invitedUser.uid,
        invitedUserName: invitedUser.displayName,
        invitedUserProfileImage: invitedUser.profileImage ?? '',
        status: CollaborationStatus.pending,
        createdAt: Timestamp.now(),
        message: message,
      );

      await collaborationRef.set(collaboration.toFirestore());

      // Create notification for invited user
      await _notificationService.createNotification(
        userId: invitedUser.uid,
        type: 'collaboration_invite',
        actorId: postOwner.uid,
        actorName: postOwner.displayName,
        actorProfileImage: postOwner.profileImage ?? '',
        message: '${postOwner.displayName} invited you to collaborate on a post',
        postId: postId,
      );

      return collaboration;
    } catch (e) {
      throw Exception('Failed to send collaboration invite: $e');
    }
  }

  /// Accept a collaboration invite
  Future<void> acceptCollaborationInvite(String collaborationId) async {
    try {
      final collaborationDoc = await _firestore.collection('collaborations').doc(collaborationId).get();
      if (!collaborationDoc.exists) {
        throw Exception('Collaboration invite not found');
      }

      final collaboration = Collaboration.fromFirestore(collaborationDoc);

      if (!collaboration.isPending) {
        throw Exception('Invite is no longer pending');
      }

      // Update collaboration status
      await _firestore.collection('collaborations').doc(collaborationId).update({
        'status': CollaborationStatus.accepted,
        'respondedAt': Timestamp.now(),
      });

      // Add user to post collaborators
      await _firestore.collection('posts').doc(collaboration.postId).update({
        'collaboratorIds': FieldValue.arrayUnion([collaboration.invitedUserId]),
      });

      // Notify post owner
      await _notificationService.createNotification(
        userId: collaboration.postOwnerId,
        type: 'collaboration_accepted',
        actorId: collaboration.invitedUserId,
        actorName: collaboration.invitedUserName,
        actorProfileImage: collaboration.invitedUserProfileImage,
        message: '${collaboration.invitedUserName} accepted your collaboration invite',
        postId: collaboration.postId,
      );
    } catch (e) {
      throw Exception('Failed to accept collaboration invite: $e');
    }
  }

  /// Reject a collaboration invite
  Future<void> rejectCollaborationInvite(String collaborationId) async {
    try {
      final collaborationDoc = await _firestore.collection('collaborations').doc(collaborationId).get();
      if (!collaborationDoc.exists) {
        throw Exception('Collaboration invite not found');
      }

      final collaboration = Collaboration.fromFirestore(collaborationDoc);

      if (!collaboration.isPending) {
        throw Exception('Invite is no longer pending');
      }

      await _firestore.collection('collaborations').doc(collaborationId).update({
        'status': CollaborationStatus.rejected,
        'respondedAt': Timestamp.now(),
      });

      // Optionally notify post owner
      await _notificationService.createNotification(
        userId: collaboration.postOwnerId,
        type: 'collaboration_rejected',
        actorId: collaboration.invitedUserId,
        actorName: collaboration.invitedUserName,
        actorProfileImage: collaboration.invitedUserProfileImage,
        message: '${collaboration.invitedUserName} declined your collaboration invite',
        postId: collaboration.postId,
      );
    } catch (e) {
      throw Exception('Failed to reject collaboration invite: $e');
    }
  }

  /// Cancel a collaboration invite (by post owner)
  Future<void> cancelCollaborationInvite(String collaborationId) async {
    try {
      await _firestore.collection('collaborations').doc(collaborationId).update({
        'status': CollaborationStatus.cancelled,
        'respondedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to cancel collaboration invite: $e');
    }
  }

  /// Remove a collaborator from a post
  Future<void> removeCollaborator(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'collaboratorIds': FieldValue.arrayRemove([userId]),
      });

      // Update any pending/accepted collaboration status
      final collaborationsQuery = await _firestore
          .collection('collaborations')
          .where('postId', isEqualTo: postId)
          .where('invitedUserId', isEqualTo: userId)
          .get();

      for (final doc in collaborationsQuery.docs) {
        await doc.reference.update({
          'status': CollaborationStatus.cancelled,
        });
      }
    } catch (e) {
      throw Exception('Failed to remove collaborator: $e');
    }
  }

  /// Get pending collaboration invites for a user
  Future<List<Collaboration>> getPendingInvites(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('collaborations')
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: CollaborationStatus.pending)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Collaboration.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending invites: $e');
    }
  }

  /// Get sent collaboration invites by post owner
  Future<List<Collaboration>> getSentInvites(String postOwnerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('collaborations')
          .where('postOwnerId', isEqualTo: postOwnerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Collaboration.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sent invites: $e');
    }
  }

  /// Get collaborators for a post
  Future<List<String>> getPostCollaborators(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return [];

      final data = postDoc.data() as Map<String, dynamic>;
      return List<String>.from(data['collaboratorIds'] ?? []);
    } catch (e) {
      throw Exception('Failed to get collaborators: $e');
    }
  }

  /// Real-time stream of pending invites for a user
  Stream<List<Collaboration>> getPendingInvitesStream(String userId) {
    return _firestore
        .collection('collaborations')
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: CollaborationStatus.pending)
        .snapshots()
        .map((snapshot) {
      final collaborations = snapshot.docs
          .map((doc) => Collaboration.fromFirestore(doc))
          .toList();
      collaborations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return collaborations;
    });
  }

  /// Check if a user is a collaborator on a post
  Future<bool> isCollaborator(String postId, String userId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final data = postDoc.data() as Map<String, dynamic>;
      final collaborators = List<String>.from(data['collaboratorIds'] ?? []);
      return collaborators.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Get collaboration details by ID
  Future<Collaboration?> getCollaborationById(String collaborationId) async {
    try {
      final doc = await _firestore.collection('collaborations').doc(collaborationId).get();
      if (!doc.exists) return null;
      return Collaboration.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
