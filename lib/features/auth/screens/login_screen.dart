// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../services/auth_service.dart';

/// The iOS glassmorphic sign-in screen allowing students to log in via Google OAuth.
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await widget.authService.signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('✓ Welcome back, ${user.displayName}!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Sign in failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF070E0D),
                    Color(0xFF0B1413),
                    Color(0xFF102120),
                  ]
                : const [
                    Color(0xFFF2F7F6),
                    Color(0xFFE6F3F1),
                    Color(0xFFD6EDE9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centered Login Experience
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon / Academic Brand Emblem
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              const Color(0xFF10B981),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header Titles
                      Text(
                        'Syllo',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Academic Portfolio & Schedule Manager',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Feature Highlights Glass Card
                      GlassContainer(
                        borderRadius: 24,
                        blur: 18,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFeatureRow(
                              icon: Icons.calendar_month_outlined,
                              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                              title: 'Class Schedule & Calendar',
                              subtitle: 'View timetable with opt-in calendar sync',
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                height: 1,
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            _buildFeatureRow(
                              icon: Icons.folder_special_outlined,
                              color: const Color(0xFF10B981),
                              title: 'Coursework Portfolio',
                              subtitle: 'Store activities, repos, and video demos',
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                height: 1,
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            _buildFeatureRow(
                              icon: Icons.sync_rounded,
                              color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488),
                              title: 'Cloud Cross-Device Sync',
                              subtitle: 'Switch devices seamlessly with Google login',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // The Google Sign-In Glass Button
                      GlassContainer(
                        borderRadius: 30,
                        blur: 16,
                        color: isDark
                            ? const Color(0xFF162524).withOpacity(0.95)
                            : Colors.white.withOpacity(0.9),
                        borderColor: isDark
                            ? const Color(0xFF2DD4BF).withOpacity(0.3)
                            : Colors.white,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google "G" icon
                                      Image.network(
                                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                        height: 22,
                                        width: 22,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.account_circle,
                                          size: 22,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Privacy / Terms Note
                      Text(
                        'Sign in with your student Google account to sync your schedule and projects securely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-Right Quick Theme Toggle (Sun / Moon) on top of the z-stack
              const Positioned(
                top: 10,
                right: 16,
                child: ThemeToggleButton(showBackground: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

