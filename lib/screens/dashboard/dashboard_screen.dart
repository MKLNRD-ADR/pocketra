import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import 'pocket_detail_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
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

  String _getFirstName(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }
    if (email != null) return email.split('@').first;
    return 'there';
  }

  void _showAddPocketSheet() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    int selectedColor = 0;

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
              const Text(
                'Add New Pocket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),

              // Pocket name
              const Text(
                'Pocket Name',
                style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('e.g. Food & Snacks'),
              ),
              const SizedBox(height: 16),

              // Budget
              const Text(
                'Budget',
                style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('0.00', prefix: '₱ '),
              ),
              const SizedBox(height: 16),

              // Color picker
              const Text(
                'Color',
                style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
              ),
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

              // Create button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        budgetController.text.isNotEmpty) {
                      await _firestoreService.addPocket(_user!.uid, {
                        'name': nameController.text.trim().toUpperCase(),
                        'budget': double.parse(budgetController.text),
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
                  child: const Text(
                    'Create Pocket',
                    style: TextStyle(fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final firstName = _getFirstName(_user?.displayName, _user?.email);

    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getPockets(_user!.uid),
          builder: (context, snapshot) {
            final pockets = snapshot.data?.docs ?? [];

            double totalBudget = 0;
            double totalSpent = 0;
            for (var p in pockets) {
              final data = p.data() as Map<String, dynamic>;
              totalBudget += (data['budget'] ?? 0).toDouble();
              totalSpent += (data['spent'] ?? 0).toDouble();
            }
            final totalRemaining = totalBudget - totalSpent;
            final progress = totalBudget > 0
                ? totalRemaining / totalBudget
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                              firstName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
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
                              'TOTAL STARTING BALANCE',
                              '₱${totalBudget.toStringAsFixed(2)}',
                            ),
                            _balanceStat(
                              'TOTAL LEFT TO SPEND',
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
                            value: progress.toDouble(),
                            backgroundColor: const Color(0xFF2A3A2F),
                            // ✅ Correct
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddPocketSheet,
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
                            final budget = (data['budget'] ?? 0).toDouble();
                            final spent = (data['spent'] ?? 0).toDouble();
                            final remaining = budget - spent;
                            final progress = budget > 0
                                ? remaining / budget
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
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

                  pockets.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Color(0xFF6B7C75),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Column(
                          children: pockets.take(3).map((p) {
                            final data = p.data() as Map<String, dynamic>;
                            final spent = (data['spent'] ?? 0).toDouble();
                            if (spent == 0) {
                              return const SizedBox();
                            }
                            return _transactionTile(
                              data['name'] ?? '',
                              '${data['name']} • Recent',
                              '-₱${spent.toStringAsFixed(2)}',
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 100),
                ],
              ),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
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

  // Pocket card — no emoji, bold text like your UI
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
          // Bold large pocket name — matches your UI
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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

  Widget _transactionTile(String title, String subtitle, String amount) {
    return Container(
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
            child: const Icon(
              Icons.wallet_outlined,
              color: Color(0xFF6B7C75),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7C75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 14,
            ),
          ),
        ],
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
        _navItem(Icons.wallet_outlined, 'Pockets', false, () {}),
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

Widget _navItem(IconData icon, String label, bool active,
    VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: active
                ? const Color(0xFF3DDB6F)
                : const Color(0xFF6B7C75),
            size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: active
                    ? const Color(0xFF3DDB6F)
                    : const Color(0xFF6B7C75),
                fontSize: 11)),
      ],
    ),
  );
}
}
