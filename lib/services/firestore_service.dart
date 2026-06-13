import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // USER
  // ─────────────────────────────────────────

  // Creates user profile when they first sign up
  Future<void> createUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data);
  }

  // Gets user profile data once
  Future<DocumentSnapshot> getUserProfile(
      String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  // Real-time stream of user data
  // Used to watch totalMoney changes in dashboard
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // ─────────────────────────────────────────
  // TOTAL MONEY
  // ─────────────────────────────────────────

  // Set total money directly (edit existing amount)
  // Uses merge so it works even if field doesn't exist yet
  Future<void> setTotalMoney(
      String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': amount,
    }, SetOptions(merge: true));

    // Save to history so user can track changes
    await _db
        .collection('users')
        .doc(userId)
        .collection('moneyHistory')
        .add({
      'type': 'set',
      'amount': amount,
      'note': 'Set total money',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Add money to existing total + save to history
  // Example: total is 1000, add 500 → total becomes 1500
  Future<void> addMoney(
      String userId, double amount, String note) async {
    // Increment existing totalMoney
    // merge: true means create field if it doesn't exist
    await _db.collection('users').doc(userId).set({
      'totalMoney': FieldValue.increment(amount),
    }, SetOptions(merge: true));

    // Save to money history
    await _db
        .collection('users')
        .doc(userId)
        .collection('moneyHistory')
        .add({
      'type': 'add',
      'amount': amount,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Deduct from total money when expense is added
  // Called automatically inside addTransaction
  Future<void> deductFromTotal(
      String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': FieldValue.increment(-amount),
    }, SetOptions(merge: true));
  }

  // Real-time stream of money history
  // Shows all add/set operations in Manage Money screen
  Stream<QuerySnapshot> getMoneyHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('moneyHistory')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // POCKETS
  // ─────────────────────────────────────────

  // Creates a new pocket (e.g. Food & Snacks, Commute)
  Future<void> addPocket(
      String userId, Map<String, dynamic> pocket) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .add(pocket);
  }

  // Real-time stream of all pockets
  // Updates instantly when pocket data changes
  Stream<QuerySnapshot> getPockets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Updates pocket data (e.g. name, budget)
  Future<void> updatePocket(
      String userId,
      String pocketId,
      Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update(data);
  }

  // Deletes a pocket
  // Note: spent money stays deducted from total
  Future<void> deletePocket(
      String userId, String pocketId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .delete();
  }

  // ─────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────

  // Adds a new expense to a pocket
  // Automatically deducts from:
  //   1. Pocket's own spent amount
  //   2. User's total money
  Future<void> addTransaction(
      String userId,
      String pocketId,
      Map<String, dynamic> transaction) async {

    // Step 1 — Save transaction record to pocket
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .add(transaction);

    // Step 2 — Deduct from pocket's spent amount
    // So pocket balance updates correctly
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update({
      'spent': FieldValue.increment(transaction['amount']),
    });

    // Step 3 — Deduct from user's total money
    // This is the key — spending affects total balance
    await deductFromTotal(
        userId, transaction['amount'].toDouble());
  }

  // Real-time stream of all transactions for a pocket
  // Ordered by newest first
  Stream<QuerySnapshot> getTransactions(
      String userId, String pocketId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Gets all transactions across ALL pockets
  // Used for dashboard recent spend section
  Stream<QuerySnapshot> getAllTransactions(String userId) {
    return _db
        .collectionGroup('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }
}