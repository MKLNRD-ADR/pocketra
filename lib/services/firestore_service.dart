import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // USER
  // ─────────────────────────────────────────

  Future<void> createUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data);
  }

  Future<DocumentSnapshot> getUserProfile(
      String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // ─────────────────────────────────────────
  // TOTAL MONEY
  // ─────────────────────────────────────────

  Future<void> setTotalMoney(
      String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': amount,
    }, SetOptions(merge: true));
  }

  Future<void> addMoney(
      String userId, double amount, String note) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': FieldValue.increment(amount),
    }, SetOptions(merge: true));

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

  Future<void> deductFromTotal(
      String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': FieldValue.increment(-amount),
    }, SetOptions(merge: true));
  }

  // Restore money back to total
  // Used when deleting transactions or money history
  Future<void> restoreToTotal(
      String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMoneyHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('moneyHistory')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete money history entry and reverse the money
  Future<void> deleteMoneyHistory(
      String userId, String historyId, double amount, String type) async {
    // Delete the history record
    await _db
        .collection('users')
        .doc(userId)
        .collection('moneyHistory')
        .doc(historyId)
        .delete();

    // Reverse the money effect
    // If it was 'add' type → deduct it back
    // If it was 'set' type → just delete, user must re-set
    if (type == 'add') {
      await _db.collection('users').doc(userId).set({
        'totalMoney': FieldValue.increment(-amount),
      }, SetOptions(merge: true));
    }
  }

  // ─────────────────────────────────────────
  // POCKETS
  // ─────────────────────────────────────────

  Future<void> addPocket(
      String userId, Map<String, dynamic> pocket) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .add(pocket);
  }

  Stream<QuerySnapshot> getPockets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

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

  // Delete pocket AND restore spent money to total
  Future<void> deletePocket(
      String userId, String pocketId) async {
    // Get pocket data first to know how much was spent
    final pocketDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .get();

    if (pocketDoc.exists) {
      final data = pocketDoc.data() as Map<String, dynamic>;
      final spent = (data['spent'] ?? 0).toDouble();

      // Restore the spent amount back to total money
      if (spent > 0) {
        await restoreToTotal(userId, spent);
      }
    }

    // Delete the pocket document
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .delete();
  }

  // Get total reserved budget across all pockets
  // Used to validate new pocket budget
  Future<double> getTotalReserved(String userId) async {
    final pockets = await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .get();

    double total = 0;
    for (var p in pockets.docs) {
      final data = p.data();
      total += (data['budget'] ?? 0).toDouble();
    }
    return total;
  }

  // ─────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────

  Future<void> addTransaction(
      String userId,
      String pocketId,
      Map<String, dynamic> transaction) async {

    // Step 1 — Save transaction
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .add(transaction);

    // Step 2 — Deduct from pocket spent
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update({
      'spent': FieldValue.increment(transaction['amount']),
    });

    // Step 3 — Deduct from total money
    await deductFromTotal(
        userId, transaction['amount'].toDouble());
  }

  // Delete transaction and restore money back
  Future<void> deleteTransaction(
      String userId,
      String pocketId,
      String transactionId,
      double amount) async {

    // Step 1 — Delete the transaction record
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .doc(transactionId)
        .delete();

    // Step 2 — Restore to pocket's spent amount
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update({
      'spent': FieldValue.increment(-amount),
    });

    // Step 3 — Restore to total money
    await restoreToTotal(userId, amount);
  }

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

  // Get recent transactions across ALL pockets
  // Used for dashboard recent spend section
  Stream<QuerySnapshot> getAllRecentTransactions(String userId) {
    return _db
        .collectionGroup('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
  }
}