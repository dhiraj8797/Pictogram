import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // ── Deterministic chat ID (smaller uid first) ─────────────────────────────
  static String chatId(String uidA, String uidB) =>
      uidA.compareTo(uidB) < 0 ? '${uidA}_$uidB' : '${uidB}_$uidA';

  // ── Get or create a chat doc ───────────────────────────────────────────────
  Future<String> getOrCreateChat({
    required String myUid,
    required String myName,
    required String myPhoto,
    required String otherUid,
    required String otherName,
    required String otherPhoto,
  }) async {
    final id = chatId(myUid, otherUid);
    final ref = _db.collection('chats').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [myUid, otherUid],
        'participantNames': {myUid: myName, otherUid: otherName},
        'participantPhotos': {myUid: myPhoto, otherUid: otherPhoto},
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });
    }
    return id;
  }

  // ── Send a message ─────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String chatIdVal,
    required String senderId,
    required String text,
  }) async {
    final batch = _db.batch();
    final msgRef =
        _db.collection('chats').doc(chatIdVal).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    batch.update(_db.collection('chats').doc(chatIdVal), {
      'lastMessage': text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ── Mark all messages as read ──────────────────────────────────────────────
  Future<void> markRead(String chatIdVal, String myUid) async {
    final snaps = await _db
        .collection('chats')
        .doc(chatIdVal)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: myUid)
        .get();
    final batch = _db.batch();
    for (final doc in snaps.docs) {
      batch.update(doc.reference, {'read': true});
    }
    batch.update(_db.collection('chats').doc(chatIdVal), {'unreadCount': 0});
    await batch.commit();
  }

  // ── Stream of messages in a chat ──────────────────────────────────────────
  Stream<List<ChatMessage>> messagesStream(String chatIdVal) => _db
      .collection('chats')
      .doc(chatIdVal)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());

  // ── Stream of all chats for a user ────────────────────────────────────────
  Stream<List<Chat>> chatsStream(String uid) => _db
      .collection('chats')
      .where('participants', arrayContains: uid)
      .orderBy('lastTimestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Chat.fromFirestore).toList());

  // ── Increment post view count (deduplicated per session via Set) ──────────
  Future<void> incrementPostView(String postId, String viewerId) async {
    final postRef = _db.collection('posts').doc(postId);
    final viewRef = postRef.collection('viewers').doc(viewerId);
    final viewSnap = await viewRef.get();
    if (!viewSnap.exists) {
      await _db.runTransaction((tx) async {
        tx.set(viewRef, {'viewedAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'viewsCount': FieldValue.increment(1)});
      });
    }
  }
}
