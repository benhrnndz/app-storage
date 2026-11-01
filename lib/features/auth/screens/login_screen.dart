// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../services/auth_service.dart';

/// The iOS glassmorphic sign-in screen allowing students to log in via Google OAuth.
///
/// Features responsive adaptive layout for mobile and desktop screens, bespoke
/// 3D brand emblem, conceptual platform showcase, and biophilic light/dark mode support.
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
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
              // Responsive Login Experience (Split desktop or centered mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960 && constraints.maxHeight >= 640;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : 24,
                        vertical: 32,
                      ),
                      child: isDesktop
                          ? _buildDesktopLayout(theme, isDark)
                          : _buildMobileLayout(theme, isDark),
                    ),
                  );
                },
              ),

              // Top-Right Quick Theme Toggle (Sun / Moon) on top of the z-stack
              const Positioned(
                top: 14,
                right: 18,
                child: ThemeToggleButton(showBackground: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop two-column split layout with hero showcase and sign-in portal.
  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Hero Showcase
          Expanded(
            flex: 6,
            child: _buildHeroShowcase(theme, isDark),
          ),
          const SizedBox(width: 48),
          // Right Sign-In Portal
          Expanded(
            flex: 5,
            child: _buildSignInCard(theme, isDark),
          ),
        ],
      ),
    );
  }

  /// Mobile single-column centered layout.
  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBrandEmblem(theme, isDark, size: 84),
          const SizedBox(height: 20),
          _buildBrandTitles(theme, isDark),
          const SizedBox(height: 28),
          _buildFeatureCard(theme, isDark),
          const SizedBox(height: 28),
          _buildGoogleSignInButton(isDark),
          const SizedBox(height: 18),
          _buildFootnote(isDark),
        ],
      ),
    );
  }

  /// Left-side desktop hero showcase with 3D conceptual platform artwork.
  Widget _buildHeroShowcase(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Mark & Tagline
        Row(
          children: [
            _buildBrandEmblem(theme, isDark, size: 52),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syllo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Student Academic Hub & Portfolio',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Hero Illustration Card
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2DD4BF).withOpacity(0.3)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF0F766E) : Colors.black).withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/syllo_hero.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    color: isDark ? const Color(0xFF111E1D) : const Color(0xFFE6F3F1),
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          (isDark ? const Color(0xFF0A1211) : Colors.black87).withOpacity(0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Text(
                      'Curate coursework, automate timetables, and showcase your achievements.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Value Proposition Bullets
        Text(
          'Engineered for university students to unify academic schedules, project repositories, and AI-assisted study roadmaps.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// The Right-hand sign-in card container.
  Widget _buildSignInCard(ThemeData theme, bool isDark) {
    return GlassContainer(
      borderRadius: 28,
      blur: 20,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBrandEmblem(theme, isDark, size: 64),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Academic Hub',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
            'Your Academic Portfolio & Timetable Manager',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(theme, isDark),
          const SizedBox(height: 28),
          _buildGoogleSignInButton(isDark),
          const SizedBox(height: 16),
          _buildFootnote(isDark),
        ],
      ),
    );
  }

  /// Bespoke 3D Syllo Brand Emblem Logo with rounded glass frame and glowing halo.
  Widget _buildBrandEmblem(ThemeData theme, bool isDark, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
                .withOpacity(isDark ? 0.35 : 0.22),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2DD4BF).withOpacity(0.4)
                  : Colors.white.withOpacity(0.85),
              width: 1.5,
            ),
          ),
          child: Image.asset(
            'assets/images/syllo_logo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    const Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.school_rounded,
                size: size * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTitles(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Syllo',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary).withOpacity(0.3),
                ),
              ),
              child: Text(
                'v1.2',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your Academic Portfolio & Timetable Manager',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(ThemeData theme, bool isDark) {
    return GlassContainer(
      borderRadius: 22,
      blur: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureRow(
            icon: Icons.calendar_month_outlined,
            color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
            title: 'Class Timetable & Calendar Sync',
            subtitle: 'Export RFC 5545 schedules to Google, Apple & Outlook',
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
          ),
          _buildFeatureRow(
            icon: Icons.folder_special_outlined,
            color: const Color(0xFF10B981),
            title: 'Coursework & Demo Portfolio',
            subtitle: 'Store activities, deliverables, repos, and video submissions',
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
          ),
          _buildFeatureRow(
            icon: Icons.sync_rounded,
            color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488),
            title: 'Cloud Cross-Device Sync',
            subtitle: 'Seamless real-time synchronization backed by Firebase',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(bool isDark) {
    return GlassContainer(
      borderRadius: 30,
      blur: 16,
      color: isDark
          ? const Color(0xFF162524).withOpacity(0.95)
          : Colors.white.withOpacity(0.92),
      borderColor: isDark
          ? const Color(0xFF2DD4BF).withOpacity(0.35)
          : Colors.white,
      child: BouncyTap(
        onTap: _isLoading ? null : _handleGoogleSignIn,
        scaleDown: 0.96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" icon with graceful fallback
                    Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      height: 22,
                      width: 22,
                      errorBuilder: (_, __, ___) => Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFootnote(bool isDark) {
    return Column(
      children: [
        Text(
          'Sign in with your student Google account to sync your schedule and projects securely.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
            ),
            Text(
              'OAuth 2.0 Encrypted • Architecture Coursework',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
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
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
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

