import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _user = FirebaseAuth.instance.currentUser;

  String _getInitials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null) return email[0].toUpperCase();
    return 'U';
  }

  void _showEditNameDialog(String currentName) {
    final nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit Name',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Your name',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: Color(0xFF6B7C75))),
          ),
          ElevatedButton(
            onPressed: () {
  if (nameController.text.trim().isNotEmpty) {
    final newName = nameController.text.trim();

    // ✅ Close dialog first
    Navigator.pop(context);

    // ✅ Write to Firestore in background
    // Works offline — syncs when internet returns
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'name': newName});

    // ✅ Update Firebase Auth display name
    // This may fail offline but that's okay
    // Firestore stream will show correct name
    _user?.updateDisplayName(newName);
  }
},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDB6F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF6B7C75))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: Color(0xFF6B7C75))),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                const Color(0xFF2A3A2F)),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                // ✅ StreamBuilder watches Firestore in real-time
                // Name updates immediately when changed
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data()
                        as Map<String, dynamic>?;

                    // ✅ Always read from Firestore first
                    final name = data?['name'] ??
                        _user?.displayName ??
                        '';
                    final email = data?['email'] ??
                        _user?.email ??
                        '';
                    final createdAt =
                        data?['createdAt'] ?? '';
                    final initials =
                        _getInitials(name, email);

                    return Column(
                      children: [

                        const SizedBox(height: 20),

                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DDB6F),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  const Color(0xFF2A3A2F),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Name from Firestore stream
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22)),

                        const SizedBox(height: 4),

                        Text(email,
                            style: const TextStyle(
                                color: Color(0xFF6B7C75),
                                fontSize: 14)),

                        const SizedBox(height: 8),

                        if (createdAt.isNotEmpty)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF1A2A1F),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(
                                      0xFF2A3A2F)),
                            ),
                            child: Text(
                              'Member since ${_formatJoinDate(createdAt)}',
                              style: const TextStyle(
                                  color: Color(0xFF6B7C75),
                                  fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 32),

                        _sectionLabel('ACCOUNT'),
                        const SizedBox(height: 8),

                        _settingsTile(
                          icon: Icons.person_outline,
                          label: 'Edit Name',
                          value: name,
                          onTap: () =>
                              _showEditNameDialog(name),
                        ),

                        _settingsTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: email,
                          onTap: null,
                        ),

                        const SizedBox(height: 24),

                        _sectionLabel('APP'),
                        const SizedBox(height: 8),

                        _settingsTile(
                          icon: Icons.attach_money,
                          label: 'Currency',
                          value: 'Philippine Peso (₱)',
                          onTap: null,
                        ),

                        _settingsTile(
                          icon:
                              Icons.notifications_outlined,
                          label: 'Notifications',
                          value: 'Coming soon',
                          onTap: null,
                        ),

                        const SizedBox(height: 24),

                        _sectionLabel('ABOUT'),
                        const SizedBox(height: 8),

                        _settingsTile(
                          icon: Icons.info_outline,
                          label: 'App Version',
                          value: '1.0.0',
                          onTap: null,
                        ),

                        _settingsTile(
                          icon: Icons.shield_outlined,
                          label: 'Privacy Policy',
                          value: '',
                          onTap: () {},
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout,
                                color: Colors.white,
                                size: 20),
                            label: const Text('Logout',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF2A1A1A),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                                side: const BorderSide(
                                    color:
                                        Color(0xFFF87171)),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF6B7C75), fontSize: 11)),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A1F),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF2A3A2F)),
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
              child: Icon(icon,
                  color: const Color(0xFF3DDB6F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14)),
                  if (value.isNotEmpty)
                    Text(value,
                        style: const TextStyle(
                            color: Color(0xFF6B7C75),
                            fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF6B7C75), size: 20),
          ],
        ),
      ),
    );
  }
}