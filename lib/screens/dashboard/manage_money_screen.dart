import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ManageMoneyScreen extends StatefulWidget {
  final String userId;

  const ManageMoneyScreen({super.key, required this.userId});

  @override
  State<ManageMoneyScreen> createState() => _ManageMoneyScreenState();
}

class _ManageMoneyScreenState extends State<ManageMoneyScreen> {
  final _firestoreService = FirestoreService();

  void _showSetMoneySheet(double currentAmount) {
    final amountController = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController();
    bool isAdding = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              // Handle bar
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

              // Toggle Add / Set
              // Toggle Add / Set
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          isAdding = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isAdding
                              ? const Color(0xFF3DDB6F)
                              : const Color(0xFF111411),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Add Money',
                            style: TextStyle(
                              color: isAdding
                                  ? Colors.black
                                  : const Color(0xFF6B7C75),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          isAdding = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isAdding
                              ? const Color(0xFF3DDB6F)
                              : const Color(0xFF111411),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Set Amount',
                            style: TextStyle(
                              color: !isAdding
                                  ? Colors.black
                                  : const Color(0xFF6B7C75),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                isAdding ? 'Amount to Add' : 'Set Total Money',
                style: const TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
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
                'Note (optional)',
                style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('e.g. Salary, allowance...'),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      final amount = double.parse(amountController.text);
                      final note = noteController.text.isEmpty
                          ? (isAdding ? 'Added money' : 'Set total money')
                          : noteController.text.trim();

                      if (isAdding) {
                        // Add to existing total
                        await _firestoreService.addMoney(
                          widget.userId,
                          amount,
                          note,
                        );
                      } else {
                        // Set total money directly
                        await _firestoreService.setTotalMoney(
                          widget.userId,
                          amount,
                        );
                        // Save to history
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('moneyHistory')
                            .add({
                              'type': 'set',
                              'amount': amount,
                              'note': note,
                              'createdAt': DateTime.now().toIso8601String(),
                            });
                      }
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
                  child: Text(
                    isAdding ? 'Add Money' : 'Set Amount',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
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
          stream: _firestoreService.getUserStream(widget.userId),
          builder: (context, userSnapshot) {
            final userData =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final totalMoney = (userData['totalMoney'] ?? 0).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                                  color: const Color(0xFF2A3A2F),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'My Money',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showSetMoneySheet(totalMoney),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DDB6F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '+ Add / Set',
                            style: TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Total money card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A1F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2A3A2F)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL MONEY',
                          style: TextStyle(
                            color: Color(0xFF6B7C75),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${totalMoney.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF3DDB6F),
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _quickAction(
                              label: 'Add Money',
                              icon: Icons.add_circle_outline,
                              color: const Color(0xFF3DDB6F),
                              onTap: () => _showSetMoneySheet(totalMoney),
                            ),
                            const SizedBox(width: 12),
                            _quickAction(
                              label: 'Edit Amount',
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF60A5FA),
                              onTap: () => _showSetMoneySheet(totalMoney),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Money History',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),

                const SizedBox(height: 12),

                // Money history list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getMoneyHistory(widget.userId),
                    builder: (context, historySnapshot) {
                      final history = historySnapshot.data?.docs ?? [];

                      if (history.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2A1F),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Color(0xFF3DDB6F),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No money history yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+ Add / Set" to add your money',
                                style: TextStyle(
                                  color: Color(0xFF6B7C75),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: history.length,
                        itemBuilder: (context, i) {
                          final data =
                              history[i].data() as Map<String, dynamic>;
                          final isAdd = data['type'] == 'add';
                          final amount = (data['amount'] ?? 0).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2A1F),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF2A3A2F),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isAdd
                                        ? const Color(
                                            0xFF3DDB6F,
                                          ).withValues(alpha: 0.15)
                                        : const Color(
                                            0xFF60A5FA,
                                          ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isAdd
                                        ? Icons.add_circle_outline
                                        : Icons.edit_outlined,
                                    color: isAdd
                                        ? const Color(0xFF3DDB6F)
                                        : const Color(0xFF60A5FA),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['note'] ??
                                            (isAdd
                                                ? 'Added money'
                                                : 'Set amount'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(data['createdAt']),
                                        style: const TextStyle(
                                          color: Color(0xFF6B7C75),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isAdd
                                      ? '+₱${amount.toStringAsFixed(2)}'
                                      : '₱${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isAdd
                                        ? const Color(0xFF3DDB6F)
                                        : const Color(0xFF60A5FA),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _quickAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
