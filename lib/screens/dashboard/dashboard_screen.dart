import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'pocket_detail_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'manage_money_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  final List<Color> _pocketColors = [
    const Color(0xFF3DDB6F),
    const Color(0xFF60A5FA),
    const Color(0xFFFBBF24),
    const Color(0xFFF87171),
    const Color(0xFFA78BFA),
    const Color(0xFFFB923C),
  ];

  // ✅ Get name from Firestore stream, not from _user
  // This ensures name updates immediately
  String _getFirstName(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }
    if (email != null) return email.split('@').first;
    return 'there';
  }

  // Delete pocket — restores spent money to total
  void _showDeletePocketDialog(BuildContext context,
      String pocketId, String pocketName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Section',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "$pocketName"?\n\nAny money spent in this section will be restored to your total balance.',
          style: const TextStyle(
              color: Color(0xFF6B7C75), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7C75))),
          ),
          ElevatedButton(
            onPressed: () async {
              // deletePocket now restores spent money automatically
              await _firestoreService.deletePocket(
                  _user!.uid, pocketId);
              if (context.mounted) Navigator.pop(context);
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
  }

  // Add pocket with budget validation
  void _showAddPocketSheet(double totalMoney) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    int selectedColor = 0;
    String? errorMessage;

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
              const Text('Add New Section',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              const SizedBox(height: 20),

              const Text('Section Name',
                  style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('e.g. Food & Snacks'),
              ),
              const SizedBox(height: 16),

              const Text('Budget',
                  style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('0.00', prefix: '₱ '),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFF87171), fontSize: 12)),
              ],

              const SizedBox(height: 16),

              const Text('Color',
                  style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pocketColors.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _pocketColors[i],
                        shape: BoxShape.circle,
                        border: selectedColor == i
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        budgetController.text.isNotEmpty) {
                      final newBudget =
                          double.parse(budgetController.text);

                      final totalReserved =
                          await _firestoreService
                              .getTotalReserved(_user!.uid);
                      final available = totalMoney - totalReserved;

                      if (newBudget > available) {
                        setSheetState(() {
                          errorMessage =
                              'Not enough! Available: ₱${available.toStringAsFixed(2)}';
                        });
                        return;
                      }

                      await _firestoreService.addPocket(_user.uid, {
                        'name': nameController.text.trim().toUpperCase(),
                        'budget': newBudget,
                        'spent': 0.0,
                        'colorIndex': selectedColor,
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
                  child: const Text('Create Section',
                      style: TextStyle(fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getUserStream(_user!.uid),
          builder: (context, userSnapshot) {
            final userData =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final totalMoney = (userData['totalMoney'] ?? 0).toDouble();

            // ✅ Get name from Firestore stream
            // so it updates immediately when changed
            final userName = userData['name'] as String?;
            final firstName = _getFirstName(userName, _user.email);
            final initial = firstName.isNotEmpty
                ? firstName[0].toUpperCase()
                : '?';

            return StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getPockets(_user.uid),
              builder: (context, snapshot) {
                final pockets = snapshot.data?.docs ?? [];

                double totalSpent = 0;
                for (var p in pockets) {
                  final data = p.data() as Map<String, dynamic>;
                  totalSpent += (data['spent'] ?? 0).toDouble();
                }

                final totalRemaining = totalMoney - totalSpent;
                final progress = totalMoney > 0
                    ? (totalRemaining / totalMoney).clamp(0.0, 1.0)
                    : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF3DDB6F),
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ Uses real-time name
                                  Text(
                                    'Hey $firstName!',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7C75),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Text(
                                    'Your Wallet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF6B7C75),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileScreen(userId: _user.uid),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _balanceStat(
                                  'TOTAL MONEY',
                                  '₱${totalMoney.toStringAsFixed(2)}',
                                ),
                                _balanceStat(
                                  'LEFT TO SPEND',
                                  '₱${totalRemaining.toStringAsFixed(2)}',
                                  highlight: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SPENT: ₱${totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7C75),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}% REMAINING',
                                  style: const TextStyle(
                                    color: Color(0xFF3DDB6F),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3DDB6F),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // My Pockets header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Pockets',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showAddPocketSheet(totalMoney),
                            child: const Text(
                              'Add Section',
                              style: TextStyle(
                                color: Color(0xFF3DDB6F),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Pockets grid
                      snapshot.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3DDB6F),
                              ),
                            )
                          : pockets.isEmpty
                          ? _emptyPockets()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: pockets.length,
                              itemBuilder: (context, i) {
                                final data =
                                    pockets[i].data() as Map<String, dynamic>;
                                final pocketId = pockets[i].id;
                                final budget =
                                    (data['budget'] ?? 0).toDouble();
                                final spent =
                                    (data['spent'] ?? 0).toDouble();
                                final remaining = budget - spent;
                                final progress = budget > 0
                                    ? (remaining / budget).clamp(0.0, 1.0)
                                    : 0.0;
                                final colorIndex =
                                    (data['colorIndex'] ?? i) %
                                    _pocketColors.length;
                                final color = _pocketColors[colorIndex];

                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PocketDetailScreen(
                                        pocketId: pocketId,
                                        userId: _user.uid,
                                        name: data['name'] ?? '',
                                        color: color,
                                        startingBalance: budget,
                                        spent: spent,
                                      ),
                                    ),
                                  ),
                                  onLongPress: () =>
                                      _showDeletePocketDialog(
                                    context,
                                    pocketId,
                                    data['name'] ?? '',
                                  ),
                                  child: _pocketCard(
                                    data['name'] ?? '',
                                    remaining,
                                    progress.toDouble(),
                                    color,
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 28),

                      // Recent Spend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Spend',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HistoryScreen(userId: _user.uid),
                                ),
                              );
                            },
                            child: const Text(
                              'All Activity',
                              style: TextStyle(
                                color: Color(0xFF3DDB6F),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ✅ Real transactions from all pockets
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService
                            .getAllRecentTransactions(_user.uid),
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
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: Color(0xFF6B7C75),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: txs.map((tx) {
                              final data =
                                  tx.data() as Map<String, dynamic>;
                              final pocketId =
                                  tx.reference.parent.parent?.id ?? '';
                              return _recentTransactionTile(
                                tx.id,
                                pocketId,
                                data['title'] ?? 'Expense',
                                data['pocket'] ?? '',
                                (data['amount'] ?? 0).toDouble(),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _emptyPockets() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A2F)),
      ),
      child: const Column(
        children: [
          Text(
            'No pockets yet',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "Add Section" to create one',
            style: TextStyle(color: Color(0xFF6B7C75), fontSize: 13),
          ),
        ],
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
            color: highlight ? const Color(0xFF3DDB6F) : Colors.white,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _pocketCard(
    String name,
    double remaining,
    double progress,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A2F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '₱${remaining.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'left',
                    style: TextStyle(color: Color(0xFF6B7C75), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF2A3A2F),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent transaction tile with swipe to delete
  Widget _recentTransactionTile(String txId, String pocketId,
      String title, String pocket, double amount) {
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
            content: Text('Delete "$title"?',
                style: const TextStyle(color: Color(0xFF6B7C75))),
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
          _user!.uid,
          pocketId,
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
                  Text(pocket,
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111411),
        border: Border(top: BorderSide(color: Color(0xFF2A3A2F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', true, () {}),
          _navItem(Icons.wallet_outlined, 'Wallet', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageMoneyScreen(userId: _user!.uid),
              ),
            );
          }),
          _navItem(Icons.history, 'History', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(userId: _user!.uid),
              ),
            );
          }),
          _navItem(Icons.person_outline, 'Me', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: _user!.uid),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF3DDB6F) : const Color(0xFF6B7C75),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF3DDB6F) : const Color(0xFF6B7C75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}