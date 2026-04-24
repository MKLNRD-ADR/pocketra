import 'package:flutter/material.dart';

class PocketDetailScreen extends StatefulWidget {
  final String name;
  final String emoji;
  final Color color;
  final double startingBalance;
  final double spent;

  const PocketDetailScreen({
    super.key,
    required this.name,
    required this.emoji,
    required this.color,
    required this.startingBalance,
    required this.spent,
  });

  @override
  State<PocketDetailScreen> createState() => _PocketDetailScreenState();
}

class _PocketDetailScreenState extends State<PocketDetailScreen> {
  // Sample transactions per pocket
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Campus Cafeteria',
      'subtitle': 'Food • Today',
      'amount': -4.50,
      'emoji': '🍔',
    },
    {
      'title': 'Jollibee',
      'subtitle': 'Food • Today',
      'amount': -89.00,
      'emoji': '🍗',
    },
    {
      'title': 'Mang Inasal',
      'subtitle': 'Food • Yesterday',
      'amount': -129.00,
      'emoji': '🍖',
    },
  ];

  @override
  Widget build(BuildContext context) {
    double remaining = widget.startingBalance - widget.spent;
    double progress = remaining / widget.startingBalance;

    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: Column(
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
                        border:
                            Border.all(color: const Color(0xFF2A3A2F)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
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
                        border:
                            Border.all(color: const Color(0xFF2A3A2F)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _balanceStat('STARTING BALANCE',
                                  '₱${widget.startingBalance.toStringAsFixed(2)}'),
                              _balanceStat(
                                  'LEFT TO SPEND',
                                  '₱${remaining.toStringAsFixed(2)}',
                                  highlight: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'SPENT: ₱${widget.spent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFF6B7C75),
                                      fontSize: 11)),
                              Text(
                                  '${(progress * 100).toStringAsFixed(1)}% REMAINING',
                                  style: TextStyle(
                                      color: widget.color,
                                      fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  const Color(0xFF2A3A2F),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      widget.color),
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
                        icon: const Icon(Icons.add,
                            color: Colors.black, size: 20),
                        label: const Text('Add what you spent',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3DDB6F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // History header
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('History',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('All Activity',
                              style: TextStyle(
                                  color: Color(0xFF3DDB6F),
                                  fontSize: 13)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Transaction list
                    ..._transactions.map((t) => _transactionTile(
                          t['title'],
                          t['subtitle'],
                          t['amount'],
                          t['emoji'],
                        )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceStat(String label, String amount,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6B7C75), fontSize: 10)),
        const SizedBox(height: 4),
        Text(amount,
            style: TextStyle(
                color: highlight ? widget.color : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _transactionTile(
      String title, String subtitle, double amount, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF6B7C75), fontSize: 12)),
              ],
            ),
          ),
          Text('₱${amount.abs().toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Add expense bottom sheet
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

            Text('Add Expense — ${widget.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),

            const SizedBox(height: 20),

            // Amount
            const Text('Amount',
                style: TextStyle(
                    color: Color(0xFFB0C4B8), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle:
                    const TextStyle(color: Color(0xFF4A5A50)),
                prefixText: '₱ ',
                prefixStyle:
                    const TextStyle(color: Color(0xFF3DDB6F)),
                filled: true,
                fillColor: const Color(0xFF111411),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2A3A2F)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2A3A2F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3DDB6F), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            const Text('Note',
                style: TextStyle(
                    color: Color(0xFFB0C4B8), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Lunch, grab ride...',
                hintStyle:
                    const TextStyle(color: Color(0xFF4A5A50)),
                filled: true,
                fillColor: const Color(0xFF111411),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2A3A2F)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2A3A2F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3DDB6F), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty) {
                    setState(() {
                      _transactions.insert(0, {
                        'title': noteController.text.isEmpty
                            ? 'New Expense'
                            : noteController.text,
                        'subtitle':
                            '${widget.name} • Today',
                        'amount': -double.parse(
                            amountController.text),
                        'emoji': widget.emoji,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DDB6F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Save Expense',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}