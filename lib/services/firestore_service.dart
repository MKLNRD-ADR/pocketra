import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Firestore instance — the main tool for database operations
  final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // USER
  // ─────────────────────────────────────────

  // Creates user profile when they first sign up
  // Saves name, email, and when they joined
  Future<void> createUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')   // users table
        .doc(userId)           // this specific user
        .set(data);            // save the data
  }

  // Gets user profile data
  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _db
        .collection('users')
        .doc(userId)
        .get();
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
        .collection('pockets')  // pockets sub-collection
        .add(pocket);           // auto generates ID
  }

  // Real-time stream of all pockets
  // Updates instantly when pocket data changes
  Stream<QuerySnapshot> getPockets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .orderBy('createdAt', descending: false)
        .snapshots();  // snapshots = real-time updates
  }

  // Updates pocket data (e.g. name, budget)
  Future<void> updatePocket(String userId, String pocketId,
      Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update(data);
  }

  // Deletes a pocket and all its transactions
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
  // Also automatically deducts from pocket's spent amount
  Future<void> addTransaction(String userId, String pocketId,
      Map<String, dynamic> transaction) async {

    // Step 1 — Save the transaction
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .collection('transactions')
        .add(transaction);

    // Step 2 — Update pocket's spent amount
    // FieldValue.increment adds to existing value
    // So if spent was 100 and we add 50, it becomes 150
    await _db
        .collection('users')
        .doc(userId)
        .collection('pockets')
        .doc(pocketId)
        .update({
      'spent': FieldValue.increment(transaction['amount']),
    });
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
  // Used in the dashboard Recent Spend section
  Stream<QuerySnapshot> getAllTransactions(String userId) {
    return _db
        .collectionGroup('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }
}