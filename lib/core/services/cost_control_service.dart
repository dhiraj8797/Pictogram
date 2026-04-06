import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CostControlService {
  static final CostControlService _instance = CostControlService._internal();
  factory CostControlService() => _instance;
  CostControlService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track user's daily usage
  Future<Map<String, int>> getDailyUsage(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startTimestamp = Timestamp.fromDate(startOfDay);

      // Get today's reads (estimated)
      final readsQuery = await _firestore
          .collection('usage_logs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'read')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();

      // Get today's writes
      final writesQuery = await _firestore
          .collection('usage_logs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'write')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();

      // Get today's storage
      final storageQuery = await _firestore
          .collection('usage_logs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'storage')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();

      return {
        'reads': readsQuery.docs.length,
        'writes': writesQuery.docs.length,
        'storage': storageQuery.docs.length,
        'total': readsQuery.docs.length + writesQuery.docs.length + storageQuery.docs.length,
      };
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return {'reads': 0, 'writes': 0, 'storage': 0, 'total': 0};
    }
  }

  // Check if user exceeded daily limits
  Future<bool> isUserOverLimit(String userId) async {
    final usage = await getDailyUsage(userId);
    
    // Daily limits (adjust based on your pricing tier)
    const dailyReadLimit = 1000;    // Free tier
    const dailyWriteLimit = 100;    // Free tier
    const dailyStorageLimit = 10;    // Free tier (MB)

    return usage['reads']! > dailyReadLimit ||
           usage['writes']! > dailyWriteLimit ||
           usage['storage']! > dailyStorageLimit;
  }

  // Log usage for cost tracking
  Future<void> logUsage({
    required String userId,
    required String type, // 'read', 'write', 'storage'
    required String operation,
    int? cost, // Estimated cost in cents
  }) async {
    try {
      await _firestore.collection('usage_logs').add({
        'userId': userId,
        'type': type,
        'operation': operation,
        'cost': cost ?? 0,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to log usage: $e');
    }
  }

  // Get system-wide cost metrics
  Future<Map<String, dynamic>> getSystemCostMetrics() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startTimestamp = Timestamp.fromDate(startOfDay);

      // Today's total operations
      final todayOps = await _firestore
          .collection('usage_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();

      // Cost breakdown by type
      final reads = todayOps.docs.where((doc) => doc['type'] == 'read').length;
      final writes = todayOps.docs.where((doc) => doc['type'] == 'write').length;
      final storage = todayOps.docs.where((doc) => doc['type'] == 'storage').length;

      // Estimated costs (Firebase pricing)
      const readCostPer100K = 0.06;      // $0.06 per 100k reads
      const writeCostPer20K = 0.18;     // $0.18 per 20k writes
      const storageCostPerGB = 0.13;    // $0.13 per GB storage

      final estimatedReadCost = (reads / 100000) * readCostPer100K;
      final estimatedWriteCost = (writes / 20000) * writeCostPer20K;
      final estimatedStorageCost = (storage / 1000) * storageCostPerGB; // Assuming 1MB per storage op

      return {
        'date': today.toIso8601String(),
        'totalOperations': todayOps.docs.length,
        'reads': reads,
        'writes': writes,
        'storage': storage,
        'estimatedDailyCost': estimatedReadCost + estimatedWriteCost + estimatedStorageCost,
        'estimatedMonthlyCost': (estimatedReadCost + estimatedWriteCost + estimatedStorageCost) * 30,
      };
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return {
        'error': 'Failed to get cost metrics',
        'date': DateTime.now().toIso8601String(),
      };
    }
  }

  // Check if system is over budget
  Future<bool> isSystemOverBudget() async {
    final metrics = await getSystemCostMetrics();
    final dailyCost = metrics['estimatedDailyCost'] ?? 0;
    
    // Set daily budget limit (e.g., $10/day = $300/month)
    const dailyBudget = 10.0;
    
    return dailyCost > dailyBudget;
  }

  // Get user cost tier
  Future<String> getUserTier(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['tier'] ?? 'free';
      }
      return 'free';
    } catch (e) {
      return 'free';
    }
  }

  // Upgrade user tier
  Future<void> upgradeUser(String userId, String tier) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'tier': tier,
        'tierUpdatedAt': Timestamp.now(),
      });

      await FirebaseCrashlytics.instance.log('User upgraded to $tier tier: $userId');
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      throw Exception('Failed to upgrade user: $e');
    }
  }

  // Get tier limits
  Map<String, Map<String, int>> getTierLimits() {
    return {
      'free': {
        'dailyReads': 1000,
        'dailyWrites': 100,
        'dailyStorage': 10, // MB
        'maxImageSize': 5,  // MB
      },
      'pro': {
        'dailyReads': 10000,
        'dailyWrites': 1000,
        'dailyStorage': 100, // MB
        'maxImageSize': 10, // MB
      },
      'enterprise': {
        'dailyReads': 100000,
        'dailyWrites': 10000,
        'dailyStorage': 1000, // MB
        'maxImageSize': 20, // MB
      },
    };
  }

  // Check if user can perform operation based on tier
  Future<bool> canPerformOperation(String userId, String operation) async {
    final tier = await getUserTier(userId);
    final usage = await getDailyUsage(userId);
    final limits = getTierLimits()[tier] ?? getTierLimits()['free']!;

    switch (operation) {
      case 'read':
        return usage['reads']! < limits['dailyReads']!;
      case 'write':
        return usage['writes']! < limits['dailyWrites']!;
      case 'storage':
        return usage['storage']! < limits['dailyStorage']!;
      default:
        return true;
    }
  }

  // Get cost optimization recommendations
  Future<List<String>> getCostOptimizationRecommendations() async {
    final recommendations = <String>[];
    final metrics = await getSystemCostMetrics();

    if (metrics['reads']! > 50000) {
      recommendations.add('Consider implementing pagination to reduce reads');
    }

    if (metrics['writes']! > 1000) {
      recommendations.add('Batch writes to reduce write operations');
    }

    if (metrics['storage']! > 100) {
      recommendations.add('Implement image compression and cleanup');
    }

    if (metrics['estimatedMonthlyCost']! > 100) {
      recommendations.add('Consider implementing user tiers and usage limits');
    }

    return recommendations;
  }
}
