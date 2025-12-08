import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Profile Management
  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    String? email,
    String? photoURL,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'coins': 0,
        'totalScore': 0,
        'gamesPlayed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint('User profile created: $uid');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  // Story Mode Progress
  Future<void> saveStoryProgress({
    required String uid,
    required int levelNumber,
    required int stars,
    required int score,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('storyProgress')
          .doc('level_$levelNumber')
          .set({
        'levelNumber': levelNumber,
        'stars': stars,
        'highScore': score,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Story progress saved: Level $levelNumber, $stars stars');
    } catch (e) {
      debugPrint('Error saving story progress: $e');
    }
  }

  Future<Map<int, Map<String, dynamic>>> getStoryProgress(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('storyProgress')
          .get();

      final Map<int, Map<String, dynamic>> progress = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final levelNumber = data['levelNumber'] as int;
        progress[levelNumber] = data;
      }
      return progress;
    } catch (e) {
      debugPrint('Error getting story progress: $e');
      return {};
    }
  }

  // Leaderboard Management
  Future<void> submitScore({
    required String uid,
    required String displayName,
    required int score,
    required String gameMode,
  }) async {
    try {
      await _firestore.collection('leaderboard').add({
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'gameMode': gameMode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's total score
      await _firestore.collection('users').doc(uid).update({
        'totalScore': FieldValue.increment(score),
        'gamesPlayed': FieldValue.increment(1),
      });

      debugPrint('Score submitted: $score for $gameMode');
    } catch (e) {
      debugPrint('Error submitting score: $e');
    }
  }

  Stream<QuerySnapshot> getLeaderboard({
    required String gameMode,
    int limit = 100,
  }) {
    return _firestore
        .collection('leaderboard')
        .where('gameMode', isEqualTo: gameMode)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Daily Challenge Management
  Future<Map<String, dynamic>?> getTodayChallenge() async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(dateString)
          .get();

      return doc.data();
    } catch (e) {
      debugPrint('Error getting daily challenge: $e');
      return null;
    }
  }

  Future<void> submitChallengeScore({
    required String uid,
    required String displayName,
    required int score,
    required String challengeDate,
  }) async {
    try {
      await _firestore
          .collection('dailyChallenges')
          .doc(challengeDate)
          .collection('scores')
          .doc(uid)
          .set({
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Challenge score submitted: $score');
    } catch (e) {
      debugPrint('Error submitting challenge score: $e');
    }
  }

  Stream<QuerySnapshot> getChallengeLeaderboard(String challengeDate) {
    return _firestore
        .collection('dailyChallenges')
        .doc(challengeDate)
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(100)
        .snapshots();
  }

  // Coins Management
  Future<void> addCoins(String uid, int amount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'coins': FieldValue.increment(amount),
      });
      debugPrint('Added $amount coins to user $uid');
    } catch (e) {
      debugPrint('Error adding coins: $e');
    }
  }

  Future<void> spendCoins(String uid, int amount) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final currentCoins = doc.data()?['coins'] ?? 0;

      if (currentCoins >= amount) {
        await _firestore.collection('users').doc(uid).update({
          'coins': FieldValue.increment(-amount),
        });
        debugPrint('Spent $amount coins for user $uid');
      } else {
        debugPrint('Insufficient coins: $currentCoins < $amount');
      }
    } catch (e) {
      debugPrint('Error spending coins: $e');
    }
  }

  // User Statistics
  Future<Map<String, dynamic>?> getUserStats(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      return {
        'totalScore': data?['totalScore'] ?? 0,
        'gamesPlayed': data?['gamesPlayed'] ?? 0,
        'coins': data?['coins'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return null;
    }
  }
}
