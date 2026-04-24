import 'package:flutter/material.dart';
import 'pocket_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        child: const Text('M',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey Mike!',
                              style: TextStyle(
                                  color: Color(0xFF6B7C75), fontSize: 12)),
                          Text('Student Wallet',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Color(0xFF6B7C75)),
                    onPressed: () {},
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
                        _balanceStat('TOTAL STARTING BALANCE', '₱900.00'),
                        _balanceStat('TOTAL LEFT TO SPEND', '₱782.50',
                            highlight: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('SPENT: ₱117.50',
                            style: TextStyle(
                                color: Color(0xFF6B7C75), fontSize: 11)),
                        Text('80.4% REMAINING',
                            style: TextStyle(
                                color: Color(0xFF3DDB6F), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.804,
                        backgroundColor: const Color(0xFF2A3A2F),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3DDB6F)),
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
                  const Text('My Pockets',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Add Section',
                        style: TextStyle(
                            color: Color(0xFF3DDB6F), fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pockets grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const PocketDetailScreen(
                            name: 'Food & Snacks',
                            emoji: '🍔',
                            color: Color(0xFF3DDB6F),
                            startingBalance: 600,
                            spent: 117.50,
                          ),
                        )),
                    child: _pocketCard('Food & Snacks', '₱20.00',
                        0.25, const Color(0xFF3DDB6F), '🍔'),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const PocketDetailScreen(
                            name: 'Books & Stationery',
                            emoji: '📚',
                            color: Color(0xFF60A5FA),
                            startingBalance: 200,
                            spent: 93,
                          ),
                        )),
                    child: _pocketCard('Books & Stationery', '₱40.00',
                        0.5, const Color(0xFF60A5FA), '📚'),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const PocketDetailScreen(
                            name: 'Commute',
                            emoji: '🚌',
                            color: Color(0xFFFBBF24),
                            startingBalance: 100,
                            spent: 20,
                          ),
                        )),
                    child: _pocketCard('Commute', '₱20.00',
                        0.4, const Color(0xFFFBBF24), '🚌'),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const PocketDetailScreen(
                            name: 'Hangouts',
                            emoji: '🎉',
                            color: Color(0xFFF87171),
                            startingBalance: 100,
                            spent: 20,
                          ),
                        )),
                    child: _pocketCard('Hangouts', '₱20.00',
                        0.3, const Color(0xFFF87171), '🎉'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Spend header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Spend',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('All Activity',
                        style: TextStyle(
                            color: Color(0xFF3DDB6F), fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Transactions
              _transactionTile('Campus Cafeteria',
                  'Food • Today', '-₱4.50', '🍔'),
              _transactionTile('Transit Reload',
                  'Commute • Yesterday', '-₱20.00', '🚌'),
              _transactionTile('National Bookstore',
                  'Books • Yesterday', '-₱93.00', '📚'),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Bottom nav
      bottomNavigationBar: _buildBottomNav(),
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
                color: highlight
                    ? const Color(0xFF3DDB6F)
                    : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _pocketCard(String name, String amount,
      double progress, Color color, String emoji) {
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
          Text(emoji, style: const TextStyle(fontSize: 18)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Color(0xFF6B7C75), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$amount left',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF2A3A2F),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(String title, String subtitle,
      String amount, String emoji) {
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
                        color: Color(0xFF6B7C75),
                        fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
              style: const TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111411),
        border:
            Border(top: BorderSide(color: Color(0xFF2A3A2F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', true),
          _navItem(Icons.wallet_outlined, 'Pockets', false),
          _navItem(Icons.history, 'History', false),
          _navItem(Icons.person_outline, 'Me', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
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
    );
  }
}