import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../navigation/app_navigator.dart';
import 'dart:ui';
import 'dart:async';
import '../components/bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _firebaseUser;
  late final Stream<User?> _authChanges;
  late final StreamSubscription<User?> _authSubscription;
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    _authChanges = FirebaseAuth.instance.authStateChanges();
    _authSubscription = _authChanges.listen((user) {
      setState(() {
        _firebaseUser = user;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  String _displayName() {
    final name = _firebaseUser?.displayName;
    if (name != null && name.isNotEmpty) return name;
    final email = _firebaseUser?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  void _handleEditProfile() {
    final nameController = TextEditingController(
      text: _firebaseUser?.displayName ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final user = FirebaseAuth.instance.currentUser;
                await user?.updateDisplayName(newName);
                await user?.reload();
                await _authService.syncCurrentUserProfile();
                if (mounted) {
                  setState(() {
                    _firebaseUser = FirebaseAuth.instance.currentUser;
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name updated!'),
                      backgroundColor: Color(0xFF3A5A53),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    final user = FirebaseAuth.instance.currentUser;
    final isEmailUser =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    if (!isEmailUser) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change Password'),
          content: const Text(
            'Your account uses Google Sign-In. Password is managed by Google.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isLoading = false;
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final currentPass = currentPasswordController.text
                            .trim();
                        final newPass = newPasswordController.text.trim();
                        final confirmPass = confirmPasswordController.text
                            .trim();

                        if (currentPass.isEmpty || newPass.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'New password must be at least 6 characters',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isLoading = true);
                        try {
                          final u = FirebaseAuth.instance.currentUser!;
                          final credential = EmailAuthProvider.credential(
                            email: u.email!,
                            password: currentPass,
                          );
                          await u.reauthenticateWithCredential(credential);
                          await u.updatePassword(newPass);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated!'),
                                backgroundColor: Color(0xFF3A5A53),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleDeleteAccount();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    final user = FirebaseAuth.instance.currentUser;
    final isEmailUser =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isLoading = false;
          return AlertDialog(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will permanently delete your account and all data. This cannot be undone.',
                ),
                if (isEmailUser) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Enter your password to confirm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          final u = FirebaseAuth.instance.currentUser!;
                          if (isEmailUser) {
                            final credential = EmailAuthProvider.credential(
                              email: u.email!,
                              password: passwordController.text,
                            );
                            await u.reauthenticateWithCredential(credential);
                          }
                          await _authService.deleteCurrentUserData();
                          await u.delete();
                          if (mounted) {
                            Navigator.pop(ctx);
                            AppNavigator.navigateToLogin(this.context);
                          }
                        } catch (e) {
                          if (mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogOut() {
    print('Log out');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          StatefulBuilder(
            builder: (context, setStateDialog) {
              return TextButton(
                onPressed: _isSigningOut
                    ? null
                    : () async {
                        // show a loading spinner in dialog
                        setStateDialog(() => _isSigningOut = true);
                        try {
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.pop(context);
                            AppNavigator.navigateToLogin(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setStateDialog(() => _isSigningOut = false);
                          }
                        }
                      },
                child: _isSigningOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAboutUs() {
    showAboutDialog(
      context: context,
      applicationName: 'Artefacto',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.collections_bookmark_outlined,
        size: 48,
        color: Color(0xFF3A5A53),
      ),
      children: const [
        Text(
          'Artefacto is your personal collectors catalog — organize, track and explore your collections in one place.',
        ),
      ],
    );
  }

  // Test data handler removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Navigator.canPop(context)
                          ? IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              color: const Color.fromARGB(255, 255, 255, 255),
                            )
                          : const SizedBox(width: 48),
                      Text(
                        'Artefacto',
                        style: GoogleFonts.tangerine(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 254, 255, 255),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Avatar with Edit Button
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _handleEditProfile,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF3A5952),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color.fromARGB(255, 59, 87, 80),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Greeting — prefers passed userName, otherwise use signed-in user info
                      Text(
                        'Hello,\n${_displayName()}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 255, 255, 255),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 170),

                      // Menu Card
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF99AF9F),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _ProfileButton(
                                text: 'Change password',
                                onPressed: _handleChangePassword,
                              ),
                              const SizedBox(height: 16),
                              _ProfileButton(
                                text: 'Settings',
                                onPressed: _handleSettings,
                              ),
                              const SizedBox(height: 16),
                              _ProfileButton(
                                text: 'Log out',
                                onPressed: _handleLogOut,
                              ),
                              const SizedBox(height: 16),
                              _ProfileButton(
                                text: 'About us',
                                onPressed: _handleAboutUs,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3, isDark: true),
    );
  }
}

Widget _buildBackground() {
  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Container(color: const Color.fromARGB(255, 97, 93, 93).withOpacity(0.5)),
    ],
  );
}

class _ProfileButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _ProfileButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A5A53),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
