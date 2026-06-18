import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class PocketDetailScreen extends StatefulWidget {
  final String pocketId;
  final String userId;
  final String name;
  final Color color;
  final double startingBalance;
  final double spent;

  const PocketDetailScreen({
    super.key,
    required this.pocketId,
    required this.userId,
    required this.name,
    required this.color,
    required this.startingBalance,
    required this.spent,
  });

  @override
  State<PocketDetailScreen> createState() => _PocketDetailScreenState();
}

class _PocketDetailScreenState extends State<PocketDetailScreen> {
  final _firestoreService = FirestoreService();

  void _showAddExpenseSheet(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3A2F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add Expense — ${widget.name}',
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(height: 20),

            const Text(
              'Amount',
              style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration('0.00', prefix: '₱ '),
            ),
            const SizedBox(height: 16),

            const Text(
              'Note',
              style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration('e.g. Lunch, grab ride...'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isNotEmpty) {
                    final amount = double.parse(amountController.text);
                    await _firestoreService
                        .addTransaction(widget.userId, widget.pocketId, {
                          'title': noteController.text.isEmpty
                              ? 'New Expense'
                              : noteController.text.trim(),
                          'amount': amount,
                          'pocket': widget.name,
                          'userId': widget.userId,
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DDB6F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A5A50)),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Color(0xFF3DDB6F)),
      filled: true,
      fillColor: const Color(0xFF111411),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A3A2F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A3A2F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3DDB6F), width: 1.5),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '$diff days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('pockets')
              .doc(widget.pocketId)
              .snapshots(),
          builder: (context, snapshot) {
            double budget = widget.startingBalance;
            double spent = widget.spent;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              budget = (data['budget'] ?? budget).toDouble();
              spent = (data['spent'] ?? spent).toDouble();
            }

            final remaining = budget - spent;
            final progress = budget > 0
                ? (remaining / budget).clamp(0.0, 1.0)
                : 0.0;

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                            border: Border.all(color: const Color(0xFF2A3A2F)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2A1F),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A3A2F)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _balanceStat(
                                    'STARTING BALANCE',
                                    '₱${budget.toStringAsFixed(2)}',
                                  ),
                                  _balanceStat(
                                    'LEFT TO SPEND',
                                    '₱${remaining.toStringAsFixed(2)}',
                                    highlight: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SPENT: ₱${spent.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7C75),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}% REMAINING',
                                    style: TextStyle(
                                      color: widget.color,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFF2A3A2F),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.color,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Add expense button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddExpenseSheet(context),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 20,
                            ),
                            label: const Text(
                              'Add what you spent',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3DDB6F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // History header — plain Text, no "All Activity" button
                        const Text(
                          'History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Transactions
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestoreService.getTransactions(
                            widget.userId,
                            widget.pocketId,
                          ),
                          builder: (context, txSnapshot) {
                            if (txSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3DDB6F),
                                ),
                              );
                            }

                            final txs = txSnapshot.data?.docs ?? [];

                            if (txs.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2A1F),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF2A3A2F),
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'No expenses yet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap "Add what you spent" to log one',
                                      style: TextStyle(
                                        color: Color(0xFF6B7C75),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: txs.map((tx) {
                                final data = tx.data() as Map<String, dynamic>;
                                return _transactionTile(
                                  tx.id,
                                  data['title'] ?? 'Expense',
                                  '${widget.name} • ${_formatDate(data['createdAt'])}',
                                  (data['amount'] ?? 0).toDouble(),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balanceStat(String label, String amount, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7C75), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: highlight ? widget.color : Colors.white,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  // Swipe to delete — restores money to pocket and total
  Widget _transactionTile(String txId, String title,
      String subtitle, double amount) {
    return Dismissible(
      key: Key(txId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF87171),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 22),
      ),
      confirmDismiss: (direction) async {
        bool confirm = false;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A2A1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Transaction',
                style: TextStyle(color: Colors.white)),
            content: Text(
                'Delete "$title"?\n\nThis amount will be removed from this section\'s spent total. Your total money will not change.',
                style: const TextStyle(
                    color: Color(0xFF6B7C75),
                    height: 1.5)),
            actions: [
              TextButton(
                onPressed: () {
                  confirm = false;
                  Navigator.pop(context);
                },
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF6B7C75))),
              ),
              ElevatedButton(
                onPressed: () {
                  confirm = true;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF87171),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirm;
      },
      onDismissed: (direction) async {
        await _firestoreService.deleteTransaction(
          widget.userId,
          widget.pocketId,
          txId,
          amount,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A1F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3A2F)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A2F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_outlined,
                  color: Color(0xFF6B7C75), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF6B7C75), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-₱${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFFF87171), fontSize: 14)),
                const SizedBox(height: 2),
                const Text('swipe to delete',
                    style: TextStyle(
                        color: Color(0xFF4A5A50), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
