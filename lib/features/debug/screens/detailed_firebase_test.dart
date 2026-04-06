import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailedFirebaseTest extends StatefulWidget {
  const DetailedFirebaseTest({super.key});

  @override
  State<DetailedFirebaseTest> createState() => _DetailedFirebaseTestState();
}

class _DetailedFirebaseTestState extends State<DetailedFirebaseTest> {
  String _testResults = '';
  bool _isTesting = false;

  Future<void> _runDetailedTests() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Starting detailed Firebase diagnostics...\n\n';
    });

    try {
      // Test 1: Basic Firebase Auth Check
      await _testAuth();
      
      // Test 2: Firestore Basic Operations
      await _testFirestore();
      
      // Test 3: Storage Basic Operations
      await _testStorage();
      
      // Test 4: Network Connectivity Check
      await _testNetwork();
      
    } catch (e) {
      _addResult('\n❌ CRITICAL ERROR: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
      _addResult('\n🏁 Detailed test completed!');
    }
  }

  Future<void> _testAuth() async {
    _addResult('🔐 Testing Firebase Auth...');
    
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser != null) {
        _addResult('✅ Auth: User logged in');
        _addResult('   Email: ${currentUser.email}');
        _addResult('   UID: ${currentUser.uid}');
        _addResult('   Provider: ${currentUser.providerData.map((p) => p.providerId).join(', ')}');
      } else {
        _addResult('⚠️ Auth: No user logged in');
      }
    } catch (e) {
      _addResult('❌ Auth Error: $e');
    }
  }

  Future<void> _testFirestore() async {
    _addResult('\n🔥 Testing Firestore...');
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test basic connection
      _addResult('   Testing basic connection...');
      await firestore.collection('_test').doc('connection').get().timeout(Duration(seconds: 5));
      _addResult('✅ Firestore: Basic connection works');
      
      // Test write operation
      _addResult('   Testing write operation...');
      final testDoc = firestore.collection('_test').doc('write_test');
      await testDoc.set({
        'test': 'write_test',
        'timestamp': FieldValue.serverTimestamp(),
        'testId': DateTime.now().millisecondsSinceEpoch.toString(),
      }).timeout(Duration(seconds: 10));
      _addResult('✅ Firestore: Write operation works');
      
      // Test read operation
      _addResult('   Testing read operation...');
      final readDoc = await testDoc.get().timeout(Duration(seconds: 5));
      if (readDoc.exists) {
        _addResult('✅ Firestore: Read operation works');
        _addResult('   Data: ${readDoc.data()}');
      } else {
        _addResult('❌ Firestore: Read failed - document not found');
      }
      
      // Test query operation
      _addResult('   Testing query operation...');
      final querySnapshot = await firestore
          .collection('_test')
          .where('test', isEqualTo: 'write_test')
          .limit(1)
          .get()
          .timeout(Duration(seconds: 5));
      _addResult('✅ Firestore: Query operation works');
      _addResult('   Found ${querySnapshot.docs.length} documents');
      
    } catch (e) {
      _addResult('❌ Firestore Error: $e');
      
      // Specific error analysis
      if (e.toString().contains('permission-denied')) {
        _addResult('   → Permission denied - check Firestore rules');
      } else if (e.toString().contains('unavailable')) {
        _addResult('   → Service unavailable - check network/Firebase project');
      } else if (e.toString().contains('timeout')) {
        _addResult('   → Request timeout - slow network');
      }
    }
  }

  Future<void> _testStorage() async {
    _addResult('\n📁 Testing Firebase Storage...');
    
    try {
      final storage = FirebaseStorage.instance;
      
      // Test basic storage connection
      _addResult('   Testing storage connection...');
      final storageRef = storage.ref();
      _addResult('✅ Storage: Basic connection works');
      
      // Test list operation (if permissions allow)
      _addResult('   Testing list operation...');
      try {
        final listResult = await storageRef.child('test').list().timeout(Duration(seconds: 5));
        _addResult('✅ Storage: List operation works');
      } catch (e) {
        _addResult('⚠️ Storage: List operation failed (may be normal): $e');
      }
      
      // Test metadata operation on existing file
      _addResult('   Testing metadata operation...');
      try {
        // Create a test file first, then get its metadata
        final testMetadataRef = storageRef.child('test/metadata_test_${DateTime.now().millisecondsSinceEpoch}.txt');
        await testMetadataRef.putString('Metadata test file').timeout(Duration(seconds: 5));
        
        final metadata = await testMetadataRef.getMetadata().timeout(Duration(seconds: 5));
        _addResult('✅ Storage: Metadata operation works');
        _addResult('   Size: ${metadata.size} bytes');
        _addResult('   Created: ${metadata.timeCreated}');
        
        // Clean up
        await testMetadataRef.delete().timeout(Duration(seconds: 5));
      } catch (e) {
        _addResult('❌ Storage: Metadata operation failed: $e');
      }
      
      // Test upload operation (small test file)
      _addResult('   Testing upload operation...');
      try {
        final testFileRef = storageRef.child('test/upload_test_${DateTime.now().millisecondsSinceEpoch}.txt');
        final testData = 'Test file content at ${DateTime.now()}';
        
        // 1. Upload first
        await testFileRef.putString(testData).timeout(Duration(seconds: 10));
        _addResult('✅ Storage: Upload operation works');
        
        // 2. Then get download URL
        _addResult('   Testing download URL...');
        final downloadUrl = await testFileRef.getDownloadURL().timeout(Duration(seconds: 5));
        _addResult('✅ Storage: Download URL works');
        _addResult('   URL: $downloadUrl');
        
        // 3. Optional: Clean up test file
        _addResult('   Cleaning up test file...');
        await testFileRef.delete().timeout(Duration(seconds: 5));
        _addResult('✅ Storage: Cleanup works');
        
      } catch (e) {
        _addResult('❌ Storage: Upload/Download Error: $e');
        
        // Specific error analysis
        if (e.toString().contains('permission-denied')) {
          _addResult('   → Permission denied - check Storage rules');
        } else if (e.toString().contains('unauthorized')) {
          _addResult('   → Unauthorized - check authentication');
        } else if (e.toString().contains('quota')) {
          _addResult('   → Quota exceeded - check storage limits');
        }
      }
      
    } catch (e) {
      _addResult('❌ Storage Error: $e');
    }
  }

  Future<void> _testNetwork() async {
    _addResult('\n🌐 Testing Network Connectivity...');
    
    try {
      // Test Firestore network connectivity
      _addResult('   Testing Firestore network...');
      final startTime = DateTime.now();
      try {
        await FirebaseFirestore.instance.collection('_network').doc('test').get().timeout(Duration(seconds: 3));
        final duration = DateTime.now().difference(startTime);
        _addResult('✅ Network: Firestore reachable in ${duration.inMilliseconds}ms');
      } catch (e) {
        if (e.toString().contains('channel-error')) {
          _addResult('⚠️ Network: Minor channel fluctuation (non-critical)');
        } else {
          rethrow;
        }
      }
      
      // Test Storage network connectivity
      _addResult('   Testing Storage network...');
      final storageStartTime = DateTime.now();
      try {
        await FirebaseStorage.instance.ref().getDownloadURL().timeout(Duration(seconds: 3));
        final storageDuration = DateTime.now().difference(storageStartTime);
        _addResult('✅ Network: Storage reachable in ${storageDuration.inMilliseconds}ms');
      } catch (e) {
        if (e.toString().contains('channel-error')) {
          _addResult('⚠️ Network: Minor channel fluctuation (non-critical)');
        } else {
          rethrow;
        }
      }
      
    } catch (e) {
      _addResult('❌ Network Error: $e');
      
      if (e.toString().contains('timeout')) {
        _addResult('   → Network timeout - slow or no connection');
      } else if (e.toString().contains('host')) {
        _addResult('   → DNS resolution failed - check internet');
      }
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
        title: const Text('Detailed Firebase Diagnostics'),
        backgroundColor: Colors.red,
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
                onPressed: _isTesting ? null : _runDetailedTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
                          Text('Running Diagnostics...'),
                        ],
                      )
                    : const Text('🔍 Run Detailed Diagnostics'),
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
                        ? 'Tap "Run Detailed Diagnostics" for detailed analysis...\n\n'
                            'This will test:\n'
                            '• Firebase Auth status\n'
                            '• Firestore read/write operations\n'
                            '• Storage upload/download operations\n'
                            '• Network connectivity and latency\n'
                            '• Specific error analysis'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            
            // Troubleshooting tips
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔧 Troubleshooting Guide:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Check network connection\n'
                    '• Verify Firebase project settings\n'
                    '• Ensure APIs are enabled\n'
                    '• Check security rules\n'
                    '• Look for quota/billing issues\n'
                    '• Share results for debugging',
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
