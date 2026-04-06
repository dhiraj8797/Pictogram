import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static late FirebaseAuth _auth;
  static late FirebaseFirestore _firestore;
  static late FirebaseStorage _storage;

  static Future<void> init() async {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
  }

  // Auth
  static FirebaseAuth get auth => _auth;
  
  // Firestore
  static FirebaseFirestore get firestore => _firestore;
  
  // Storage
  static FirebaseStorage get storage => _storage;

  // User reference
  static CollectionReference get usersCollection => _firestore.collection('users');
  
  // Posts reference
  static CollectionReference get postsCollection => _firestore.collection('posts');
  
  // Comments reference
  static CollectionReference get commentsCollection => _firestore.collection('comments');
  
  // Likes reference
  static CollectionReference get likesCollection => _firestore.collection('likes');
  
  // Follows reference
  static CollectionReference get followsCollection => _firestore.collection('follows');
  
  // Stories reference
  static CollectionReference get storiesCollection => _firestore.collection('stories');
  
  // Notifications reference
  static CollectionReference get notificationsCollection => _firestore.collection('notifications');
}
