const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Rate limiting storage (in production, use Redis or similar)
const rateLimits = new Map();

// Helper function to check rate limits
function checkRateLimit(userId, action, limit, windowMs) {
  const now = Date.now();
  const key = `${userId}_${action}`;
  const userLimits = rateLimits.get(key) || [];
  
  // Remove old entries outside the window
  const recentActions = userLimits.filter(timestamp => now - timestamp < windowMs);
  
  if (recentActions.length >= limit) {
    return false; // Rate limited
  }
  
  // Add current action
  recentActions.push(now);
  rateLimits.set(key, recentActions);
  
  return true; // Allowed
}

// Helper function to detect spam
function detectSpam(content, userId) {
  const spamWords = ['free', 'winner', 'congratulations', 'claim', 'prize', 'click here', 'buy now', 'limited offer', 'act now'];
  const lowerContent = content.toLowerCase();
  
  // Check for spam words
  for (const word of spamWords) {
    if (lowerContent.includes(word)) {
      return true;
    }
  }
  
  // Check for repeated characters
  if (/(.)\1{4,}/.test(content)) {
    return true;
  }
  
  // Check for excessive capitalization
  const uppercaseCount = (content.match(/[A-Z]/g) || []).length;
  if (uppercaseCount > content.length * 0.7 && content.length > 10) {
    return true;
  }
  
  return false;
}

// Helper function to log abuse
async function logAbuse(userId, action, reason, metadata = {}) {
  try {
    await admin.firestore().collection('abuse_logs').add({
      userId,
      action,
      reason,
      metadata,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userAgent: metadata.userAgent || 'unknown',
      ip: metadata.ip || 'unknown',
    });
  } catch (error) {
    console.error('Failed to log abuse:', error);
  }
}

// Helper function to check if user is blocked
async function isUserBlocked(userId) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?.isBlocked === true;
    }
    return false;
  } catch (error) {
    console.error('Failed to check block status:', error);
    return false;
  }
}

// Rate limit check for posts
exports.canUserPost = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // Check if user is blocked
  if (await isUserBlocked(userId)) {
    await logAbuse(userId, 'post_attempt', 'blocked_user');
    throw new functions.https.HttpsError('permission-denied', 'User is blocked');
  }
  
  // Check rate limit: 6 posts per hour
  const canPost = checkRateLimit(userId, 'post', 6, 60 * 60 * 1000);
  
  if (!canPost) {
    await logAbuse(userId, 'post_attempt', 'rate_limit_exceeded');
    return { canPost: false, reason: 'Rate limit exceeded' };
  }
  
  return { canPost: true };
});

// Rate limit check for comments
exports.canUserComment = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { content } = data;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // Check if user is blocked
  if (await isUserBlocked(userId)) {
    await logAbuse(userId, 'comment_attempt', 'blocked_user');
    throw new functions.https.HttpsError('permission-denied', 'User is blocked');
  }
  
  // Check rate limit: 10 comments per 5 minutes
  const canComment = checkRateLimit(userId, 'comment', 10, 5 * 60 * 1000);
  
  if (!canComment) {
    await logAbuse(userId, 'comment_attempt', 'rate_limit_exceeded');
    return { canComment: false, reason: 'Rate limit exceeded' };
  }
  
  // Check for spam content
  if (detectSpam(content, userId)) {
    await logAbuse(userId, 'comment_attempt', 'spam_content', { content });
    return { canComment: false, reason: 'Content detected as spam' };
  }
  
  return { canComment: true };
});

// Rate limit check for follows
exports.canUserFollow = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // Check if user is blocked
  if (await isUserBlocked(userId)) {
    await logAbuse(userId, 'follow_attempt', 'blocked_user');
    throw new functions.https.HttpsError('permission-denied', 'User is blocked');
  }
  
  // Check rate limit: 50 follows per hour
  const canFollow = checkRateLimit(userId, 'follow', 50, 60 * 60 * 1000);
  
  if (!canFollow) {
    await logAbuse(userId, 'follow_attempt', 'rate_limit_exceeded');
    return { canFollow: false, reason: 'Rate limit exceeded' };
  }
  
  return { canFollow: true };
});

// Rate limit check for likes
exports.canUserLike = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // Check if user is blocked
  if (await isUserBlocked(userId)) {
    await logAbuse(userId, 'like_attempt', 'blocked_user');
    throw new functions.https.HttpsError('permission-denied', 'User is blocked');
  }
  
  // Check rate limit: 30 likes per minute
  const canLike = checkRateLimit(userId, 'like', 30, 60 * 1000);
  
  if (!canLike) {
    await logAbuse(userId, 'like_attempt', 'rate_limit_exceeded');
    return { canLike: false, reason: 'Rate limit exceeded' };
  }
  
  return { canLike: true };
});

// Spam detection
exports.checkSpam = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { content } = data;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const isSpam = detectSpam(content, userId);
  
  if (isSpam) {
    await logAbuse(userId, 'spam_detection', 'spam_content', { content });
  }
  
  return { isSpam };
});

// Create notification (backend only)
exports.createNotification = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { 
    targetUserId, 
    type, 
    actorId, 
    actorUsername, 
    actorProfileImage, 
    message, 
    postId, 
    commentId 
  } = data;
  
  // Validate required fields
  if (!targetUserId || !type || !actorId || !actorUsername || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }
  
  // Prevent self-notifications
  if (targetUserId === actorId) {
    return { success: false, reason: 'Cannot create notification for self' };
  }
  
  // Check for duplicate notifications (for likes and follows)
  if (type === 'like' || type === 'follow') {
    const existingNotification = await admin.firestore()
      .collection('notifications')
      .where('userId', '==', targetUserId)
      .where('type', '==', type)
      .where('actorId', '==', actorId)
      .where('postId', '==', postId || '')
      .where('isRead', '==', false)
      .limit(1)
      .get();
    
    if (!existingNotification.empty) {
      return { success: false, reason: 'Duplicate notification' };
    }
  }
  
  // Create the notification
  try {
    const notificationRef = admin.firestore().collection('notifications').doc();
    await notificationRef.set({
      userId: targetUserId,
      type,
      actorId,
      actorUsername,
      actorProfileImage,
      postId: postId || null,
      commentId: commentId || null,
      message,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true, notificationId: notificationRef.id };
  } catch (error) {
    console.error('Failed to create notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create notification');
  }
});

// Log abuse attempt
exports.logAbuse = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { action, reason, metadata } = data;
  
  await logAbuse(userId, action, reason, {
    ...metadata,
    userAgent: context.rawRequest.headers['user-agent'],
    ip: context.rawRequest.ip,
  });
  
  return { success: true };
});

// Check if user is blocked
exports.isUserBlocked = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { targetUserId } = data;
  const isBlocked = await isUserBlocked(targetUserId || userId);
  
  return { isBlocked };
});

// Get user usage stats
exports.getUserUsageStats = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { targetUserId } = data;
  const queryUserId = targetUserId || userId;
  
  try {
    const now = admin.firestore.Timestamp.now();
    const oneHourAgo = admin.firestore.Timestamp.fromDate(new Date(now.toDate().getTime() - 60 * 60 * 1000));
    const fiveMinutesAgo = admin.firestore.Timestamp.fromDate(new Date(now.toDate().getTime() - 5 * 60 * 1000));
    
    // Get recent posts
    const postsSnapshot = await admin.firestore()
      .collection('posts')
      .where('ownerId', '==', queryUserId)
      .where('createdAt', '>', oneHourAgo)
      .get();
    
    // Get recent comments
    const commentsSnapshot = await admin.firestore()
      .collection('comments')
      .where('userId', '==', queryUserId)
      .where('createdAt', '>', fiveMinutesAgo)
      .get();
    
    // Get recent follows
    const followsSnapshot = await admin.firestore()
      .collection('follows')
      .where('followerId', '==', queryUserId)
      .where('createdAt', '>', oneHourAgo)
      .get();
    
    // Get recent likes (using collection group)
    const likesSnapshot = await admin.firestore()
      .collectionGroup('likes')
      .where('userId', '==', queryUserId)
      .where('createdAt', '>', admin.firestore.Timestamp.fromDate(new Date(Date.now() - 60 * 1000)))
      .get();
    
    const stats = {
      postsLastHour: postsSnapshot.size,
      commentsLast5Minutes: commentsSnapshot.size,
      followsLastHour: followsSnapshot.size,
      likesLastMinute: likesSnapshot.size,
    };
    
    return { stats };
  } catch (error) {
    console.error('Failed to get usage stats:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get usage stats');
  }
});

// Clean up old rate limit entries (run every hour)
exports.cleanupRateLimits = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const now = Date.now();
  const oneHourAgo = now - 60 * 60 * 1000;
  
  for (const [key, timestamps] of rateLimits.entries()) {
    const recentTimestamps = timestamps.filter(timestamp => timestamp > oneHourAgo);
    
    if (recentTimestamps.length === 0) {
      rateLimits.delete(key);
    } else {
      rateLimits.set(key, recentTimestamps);
    }
  }
  
  console.log('Cleaned up rate limits, current entries:', rateLimits.size);
});

// Block user (admin function)
exports.blockUser = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // In production, check if caller is admin
  // For now, allow any authenticated user (for testing)
  
  const { targetUserId, reason } = data;
  
  if (!targetUserId || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing targetUserId or reason');
  }
  
  try {
    await admin.firestore().collection('users').doc(targetUserId).update({
      isBlocked: true,
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
      blockedReason: reason,
    });
    
    await logAbuse(targetUserId, 'user_blocked', reason, { blockedBy: userId });
    
    return { success: true };
  } catch (error) {
    console.error('Failed to block user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to block user');
  }
});
