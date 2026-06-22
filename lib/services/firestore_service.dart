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

  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // ─────────────────────────────────────────
  // TOTAL MONEY
  // ─────────────────────────────────────────

  Future<void> setTotalMoney(String userId, double amount) async {
    await _db.collection('users').doc(userId).set({
      'totalMoney': amount,
    }, SetOptions(merge: true));
  }

  Future<void> addMoney(String userId, double amount, String note) async {
  // ✅ Use batch so both writes happen together
  // Works offline — both queued simultaneously
  final batch = _db.batch();

  final userRef = _db.collection('users').doc(userId);
  final historyRef = userRef.collection('moneyHistory').doc();

  batch.set(userRef, {
    'totalMoney': FieldValue.increment(amount),
  }, SetOptions(merge: true));

  batch.set(historyRef, {
    'type': 'add',
    'amount': amount,
    'note': note,
    'createdAt': DateTime.now().toIso8601String(),
  });

  await batch.commit();
}

Stream<QuerySnapshot> getMoneyHistory(String userId) {
  return _db
      .collection('users')
      .doc(userId)
      .collection('moneyHistory')
      .snapshots();
}

  Future<void> deleteMoneyHistory(
    String userId, String historyId, double amount, String type) async {
  // ✅ Use batch so both writes happen together offline
  final batch = _db.batch();

  final historyRef = _db
      .collection('users')
      .doc(userId)
      .collection('moneyHistory')
      .doc(historyId);

  batch.delete(historyRef);

  if (type == 'add') {
    final userRef = _db.collection('users').doc(userId);
    batch.set(userRef, {
      'totalMoney': FieldValue.increment(-amount),
    }, SetOptions(merge: true));
  }

  await batch.commit();
}

  // ─────────────────────────────────────────
  // POCKETS
  // ─────────────────────────────────────────

  Future<void> addPocket(String userId, Map<String, dynamic> pocket) async {
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
      String userId, String pocketId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update(data);
  }

  Future<void> deletePocket(String userId, String pocketId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .delete();
  }

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
      String userId, String pocketId, Map<String, dynamic> transaction) async {
    // ✅ FIX: Store userId + pocketId in the transaction document
    // so collectionGroup queries can filter by user
    final txData = {
      ...transaction,
      'userId': userId,
      'pocketId': pocketId,
    };

    // Use a batch so all 3 writes happen atomically — instant UI update
    final batch = _db.batch();

    final txRef = _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .doc();

    final pocketRef = _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId);

    batch.set(txRef, txData);
    batch.update(pocketRef, {
      'spent': FieldValue.increment(transaction['amount']),
    });

    // ✅ Commit all at once → triggers all streams simultaneously
    await batch.commit();
  }

  Future<void> deleteTransaction(
      String userId,
      String pocketId,
      String transactionId,
      double amount) async {
    // Use a batch for instant coordinated update
    final batch = _db.batch();

    final txRef = _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .doc(transactionId);

    final pocketRef = _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId);

    batch.delete(txRef);
    batch.update(pocketRef, {'spent': FieldValue.increment(-amount)});

    await batch.commit();
  }

  Stream<QuerySnapshot> getTransactions(String userId, String pocketId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ✅ FIX: Fetch transactions per pocket instead of collectionGroup
  // Works with existing data — no userId field required
  Future<List<Map<String, dynamic>>> getRecentTransactionsFromAllPockets(
      String userId) async {
    final pockets = await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .get();

    final List<Map<String, dynamic>> allTxs = [];

    for (final pocket in pockets.docs) {
      final txs = await _db
          .collection('users')
          .doc(userId)
          .collection('pockets')
          .doc(pocket.id)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final tx in txs.docs) {
        allTxs.add({
          'txId': tx.id,
          'pocketId': pocket.id,
          ...tx.data(),
        });
      }
    }

    // Sort all combined transactions by createdAt descending
    allTxs.sort((a, b) {
      final aDate = a['createdAt'] ?? '';
      final bDate = b['createdAt'] ?? '';
      return bDate.compareTo(aDate);
    });

    return allTxs.take(5).toList();
  }
}
