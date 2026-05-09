import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestoreService = FirestoreService();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  // Formats date string to readable format
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '$diff days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  // Filters transactions based on selected filter
  bool _matchesFilter(String? dateStr) {
    if (_selectedFilter == 'All') return true;
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (_selectedFilter == 'Today') return diff == 0;
      if (_selectedFilter == 'This Week') return diff <= 7;
      if (_selectedFilter == 'This Month') return diff <= 30;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2A1F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF2A3A2F)),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('Transaction History',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20)),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, i) {
                  final isSelected =
                      _selectedFilter == _filters[i];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedFilter = _filters[i]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3DDB6F)
                            : const Color(0xFF1A2A1F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3DDB6F)
                              : const Color(0xFF2A3A2F),
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : const Color(0xFF6B7C75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Transactions list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestoreService.getPockets(widget.userId),
                builder: (context, pocketSnapshot) {
                  if (pocketSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF3DDB6F)),
                    );
                  }

                  final pockets =
                      pocketSnapshot.data?.docs ?? [];

                  if (pockets.isEmpty) {
                    return _emptyState();
                  }

                  // Build a list of all transactions
                  // from all pockets combined
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    itemCount: pockets.length,
                    itemBuilder: (context, i) {
                      final pocketData = pockets[i].data()
                          as Map<String, dynamic>;
                      final pocketId = pockets[i].id;
                      final pocketName =
                          pocketData['name'] ?? '';

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService
                            .getTransactions(
                                widget.userId, pocketId),
                        builder: (context, txSnapshot) {
                          final txs =
                              txSnapshot.data?.docs ?? [];

                          // Filter transactions
                          final filtered = txs.where((tx) {
                            final data = tx.data()
                                as Map<String, dynamic>;
                            return _matchesFilter(
                                data['createdAt']);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const SizedBox();
                          }

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Pocket name header
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                        top: 16, bottom: 8),
                                child: Text(
                                  pocketName,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7C75),
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              // Transactions under this pocket
                              ...filtered.map((tx) {
                                final data = tx.data()
                                    as Map<String, dynamic>;
                                return _transactionTile(
                                  data['title'] ?? 'Expense',
                                  _formatDate(
                                      data['createdAt']),
                                  (data['amount'] ?? 0)
                                      .toDouble(),
                                  pocketName,
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.history,
              color: Color(0xFF3DDB6F),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text('No transactions yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Your spending history will appear here',
              style: TextStyle(
                  color: Color(0xFF6B7C75),
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _transactionTile(
    String title,
    String date,
    double amount,
    String pocket,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3A2F)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2A3A2F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: Color(0xFF3DDB6F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title and pocket name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DDB6F)
                            .withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(pocket,
                          style: const TextStyle(
                              color: Color(0xFF3DDB6F),
                              fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                    Text(date,
                        style: const TextStyle(
                            color: Color(0xFF6B7C75),
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '-₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Color(0xFFF87171),
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}