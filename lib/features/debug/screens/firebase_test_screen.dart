import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _testResults = '';
  bool _isTesting = false;

  Future<void> _runAllTests() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Starting Firebase tests...\n\n';
    });

    try {
      // Test 1: Firestore Connection
      _addResult('🔥 Testing Firestore Connection...');
      try {
        final testDoc = await FirebaseFirestore.instance
            .collection('test')
            .doc('connection_test')
            .set({
              'timestamp': FieldValue.serverTimestamp(),
              'test': 'connection_check'
            });
        _addResult('✅ Firestore: SUCCESS - Can write data');
        
        // Test reading
        final readTest = await FirebaseFirestore.instance
            .collection('test')
            .doc('connection_test')
            .get();
        _addResult('✅ Firestore: SUCCESS - Can read data');
      } catch (e) {
        _addResult('❌ Firestore: FAILED - $e');
      }

      // Test 2: Storage Connection
      _addResult('\n📁 Testing Firebase Storage...');
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('test/connection_test.txt');
        
        // Try to get metadata (doesn't require actual file)
        await storageRef.getMetadata().timeout(Duration(seconds: 5));
        _addResult('✅ Storage: SUCCESS - Can connect to Storage');
      } catch (e) {
        _addResult('❌ Storage: FAILED - $e');
      }

      // Test 3: Auth Connection
      _addResult('\n👤 Testing Firebase Auth...');
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _addResult('✅ Auth: SUCCESS - User logged in: ${currentUser.email}');
        } else {
          _addResult('⚠️ Auth: No user currently logged in');
        }
      } catch (e) {
        _addResult('❌ Auth: FAILED - $e');
      }

      // Test 4: Check Collections
      _addResult('\n📊 Checking Database Collections...');
      try {
        final collections = ['users', 'posts', 'comments', 'follows', 'stories', 'notifications'];
        
        for (String collectionName in collections) {
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection(collectionName)
                .limit(1)
                .get();
            _addResult('✅ Collection "$collectionName": ${snapshot.docs.length} documents');
          } catch (e) {
            _addResult('❌ Collection "$collectionName": ERROR - $e');
          }
        }
      } catch (e) {
        _addResult('❌ Collections check failed: $e');
      }

    } catch (e) {
      _addResult('\n❌ Overall test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
      _addResult('\n🏁 Test completed!');
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults += '$result\n';
    });
    print(result); // Also print to console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _runAllTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isTesting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                    : const Text('🔥 Run Firebase Tests'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty 
                        ? 'Tap "Run Firebase Tests" to check your connection...\n\n'
                            'This will test:\n'
                            '• Firestore read/write\n'
                            '• Firebase Storage\n'
                            '• Firebase Auth\n'
                            '• Database collections'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            // Instructions
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 How to use this test:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Run the tests above\n'
                    '2. Check results for ✅ or ❌\n'
                    '3. If ❌ appears, check:\n'
                    '   • Internet connection\n'
                    '   • Firebase project settings\n'
                    '   • App configuration\n'
                    '4. Share results for debugging',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
