import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final bool read;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp,
        'read': read,
      };
}

class Chat {
  final String chatId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final Timestamp lastTimestamp;
  final int unreadCount;

  const Chat({
    required this.chatId,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage = '',
    required this.lastTimestamp,
    this.unreadCount = 0,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Chat(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos:
          Map<String, String>.from(data['participantPhotos'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp: data['lastTimestamp'] ?? Timestamp.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  /// The other participant's UID (given current user uid).
  String otherUid(String myUid) =>
      participants.firstWhere((u) => u != myUid, orElse: () => '');

  String otherName(String myUid) => participantNames[otherUid(myUid)] ?? 'User';
  String otherPhoto(String myUid) => participantPhotos[otherUid(myUid)] ?? '';
}
