// lib/features/landing/screens/landing_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/cinematic_logo.dart';

/// The premier landing page for Syllo.
///
/// Welcomes students with an executive Alabaster Frost & Obsidian Space aesthetic,
/// cinematic multi-phase entrance animation of the 3D brand prism logo, interactive
/// platform showcase, bento grid of core academic pillars, and seamless Google OAuth sign-in.
class LandingScreen extends StatefulWidget {
  final AuthService authService;

  const LandingScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _architectureKey = GlobalKey();

  bool _isSigningIn = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      final user = await widget.authService.signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            content: Text('✓ Welcome to Syllo, ${user.displayName}!'),
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
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _openDedicatedLoginScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return LoginScreen(authService: widget.authService);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AmbientMeshBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable Landing Content
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 80), // Offset for floating navbar
                          _buildHeroSection(theme, isDark),
                          const SizedBox(height: 56),
                          _buildShowcaseSection(theme, isDark),
                          const SizedBox(height: 80),
                          _buildBentoGrid(theme, isDark),
                          const SizedBox(height: 80),
                          _buildArchitectureSection(theme, isDark),
                          const SizedBox(height: 80),
                          _buildBottomCta(theme, isDark),
                          const SizedBox(height: 60),
                          _buildFooter(theme, isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Frosted Navbar
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: _buildNavbar(theme, isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. FLOATING FROSTED NAVBAR
  // ===========================================================================
  Widget _buildNavbar(ThemeData theme, bool isDark) {
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return GlassContainer(
      borderRadius: 20,
      blur: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Brand Emblem + Syllo Title
          BouncyTap(
            onTap: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1211),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: primaryAccent.withOpacity(0.30),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/syllo_logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Syllo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '2026',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: primaryAccent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Desktop Navigation Links
          if (MediaQuery.of(context).size.width >= 880) ...[
            _buildNavLink('Capabilities', () => _scrollTo(_featuresKey), theme, isDark),
            const SizedBox(width: 6),
            _buildNavLink('Architecture', () => _scrollTo(_architectureKey), theme, isDark),
            const SizedBox(width: 16),
          ],

          // Theme Toggle (Night / Day Switcher)
          const ThemeToggleButton(showBackground: false),

          const SizedBox(width: 10),

          // Sign In CTA
          BouncyTap(
            onTap: _openDedicatedLoginScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAccent,
                    const Color(0xFF10B981),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title, VoidCallback onTap, ThemeData theme, bool isDark) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. HERO SECTION WITH CINEMATIC LOGO ENTRANCE
  // ===========================================================================
  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return Column(
      children: [
        const SizedBox(height: 24),

        // Eyebrow Capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primaryAccent.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: primaryAccent.withOpacity(isDark ? 0.35 : 0.22),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryAccent,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STUDENT-FIRST ACADEMIC PORTFOLIO & SCHEDULE MANAGER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: primaryAccent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Cinematic 3D Brand Prism Logo
        CinematicBrandEmblem(
          size: isMobile ? 80 : 104,
          isDark: isDark,
          enableIdleFloat: true,
          interactiveHover: true,
          onTap: _openDedicatedLoginScreen,
        ),

        const SizedBox(height: 28),

        // Monumental Headline
        Text(
          'Master Your Semester.',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: isMobile ? 32 : 46,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.1,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF2DD4BF),
                    const Color(0xFF10B981),
                    const Color(0xFF38BDF8),
                  ]
                : [
                    const Color(0xFF0F766E),
                    const Color(0xFF059669),
                    const Color(0xFF0284C7),
                  ],
          ).createShader(bounds),
          child: Text(
            'With Intelligent Coursework & Timetable Clarity.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: isMobile ? 26 : 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              height: 1.15,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Executive Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Consolidate courses and syllabi, synchronize dynamic schedules with Google & Apple Calendar, track weighted deliverables, and unlock AI study recommendations in one unified workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 15 : 17,
              height: 1.55,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 36),

        // Action Zone (Google Sign-In + Explore Buttons)
        Wrap(
          spacing: 16,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Primary Action: Continue with Google
            BouncyTap(
              onTap: _handleGoogleSignIn,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAccent,
                      const Color(0xFF10B981),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isSigningIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.login_rounded,
                              size: 14,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Secondary Action: Launch Dedicated Portal
            BouncyTap(
              onTap: _openDedicatedLoginScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.12),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dedicated Portal',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Security Footnote
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: primaryAccent.withOpacity(0.85),
            ),
            Text(
              'OAuth 2.0 Encrypted • Real-Time Firestore • SIA Coursework',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. SHOWCASE SECTION (3D PLATFORM ARTWORK & METRICS)
  // ===========================================================================
  Widget _buildShowcaseSection(ThemeData theme, bool isDark) {
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return RepaintBoundary(
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(12),
        borderColor: primaryAccent.withOpacity(isDark ? 0.25 : 0.16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Artwork Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/images/syllo_hero.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0A1211),
                    child: const Center(
                      child: Icon(
                        Icons.laptop_chromebook_rounded,
                        size: 64,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Subtle Glass Vignette Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(isDark ? 0.35 : 0.15),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Floating Feature Badges
            Positioned(
              top: 16,
              left: 16,
              child: _buildShowcaseChip(
                icon: Icons.calendar_today_rounded,
                label: 'Dynamic Timetable Sync',
                isDark: isDark,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildShowcaseChip(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Study Intelligence',
                isDark: isDark,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildShowcaseChip(
                icon: Icons.analytics_outlined,
                label: 'Weighted Deliverables & GPA',
                isDark: isDark,
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildShowcaseChip(
                icon: Icons.cloud_done_rounded,
                label: 'Real-Time Firestore Cache',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1211).withOpacity(0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withOpacity(0.35),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF2DD4BF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. BENTO GRID (4 ARCHITECTURAL PILLARS)
  // ===========================================================================
  Widget _buildBentoGrid(ThemeData theme, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return Column(
      key: _featuresKey,
      children: [
        // Section Header
        Text(
          'ARCHITECTURAL CAPABILITIES',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Engineered for Academic Precision',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            'Four deeply integrated subsystems providing a seamless workflow from syllabus ingestion to automated calendar syncing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Bento Grid Layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildBentoCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Smart Course & Syllabus Hub',
                      description:
                          'Organize course codes, instructors, room venues, and syllabus policies in unified, accessible modules.',
                      tag: 'Syllabus Engine',
                      accentColor: const Color(0xFF0F766E),
                      theme: theme,
                      isDark: isDark,
                      height: 220,
                    ),
                    const SizedBox(height: 20),
                    _buildBentoCard(
                      icon: Icons.assignment_turned_in_rounded,
                      title: 'Weighted Deliverables Tracker',
                      description:
                          'Track assignments, midterms, and finals with automated percentage weight calculations and deadline countdowns.',
                      tag: 'Academic Portfolio',
                      accentColor: const Color(0xFF06B6D4),
                      theme: theme,
                      isDark: isDark,
                      height: 220,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildBentoCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Conflict-Free Weekly Timetable',
                      description:
                          'Interactive visual timetable with real-time conflict detection and 1-click RFC-compliant iCal (.ics) export to Google & Apple Calendar.',
                      tag: 'Schedule Integration',
                      accentColor: const Color(0xFF10B981),
                      theme: theme,
                      isDark: isDark,
                      height: 220,
                    ),
                    const SizedBox(height: 20),
                    _buildBentoCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Academic Study Coach',
                      description:
                          'Intelligent study assistant that breaks down large coursework projects into prioritized daily sprint recommendations.',
                      tag: 'Contextual AI',
                      accentColor: const Color(0xFFF59E0B),
                      theme: theme,
                      isDark: isDark,
                      height: 220,
                    ),
                  ],
                ),
              ),
            ]
          )
        else
          Column(
            children: [
              _buildBentoCard(
                icon: Icons.menu_book_rounded,
                title: 'Smart Course & Syllabus Hub',
                description:
                    'Organize course codes, instructors, room venues, and syllabus policies in unified, accessible modules.',
                tag: 'Syllabus Engine',
                accentColor: const Color(0xFF0F766E),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildBentoCard(
                icon: Icons.calendar_month_rounded,
                title: 'Conflict-Free Weekly Timetable',
                description:
                    'Interactive visual timetable with real-time conflict detection and 1-click RFC-compliant iCal export to Google & Apple Calendar.',
                tag: 'Schedule Integration',
                accentColor: const Color(0xFF10B981),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildBentoCard(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Weighted Deliverables Tracker',
                description:
                    'Track assignments, midterms, and finals with automated percentage weight calculations and deadline countdowns.',
                tag: 'Academic Portfolio',
                accentColor: const Color(0xFF06B6D4),
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildBentoCard(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Academic Study Coach',
                description:
                    'Intelligent study assistant that breaks down large coursework projects into prioritized daily sprint recommendations.',
                tag: 'Contextual AI',
                accentColor: const Color(0xFFF59E0B),
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String title,
    required String description,
    required String tag,
    required Color accentColor,
    required ThemeData theme,
    required bool isDark,
    double? height,
  }) {
    return GlassContainer(
      borderRadius: 22,
      blur: 20,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SYSTEM ARCHITECTURE & ENGINEERING SECTION
  // ===========================================================================
  Widget _buildArchitectureSection(ThemeData theme, bool isDark) {
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return Column(
      key: _architectureKey,
      children: [
        Text(
          'COURSEWORK SPECIFICATION',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'System Integration & Architecture',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Built to demonstrate enterprise multiplatform patterns, stateless OAuth 2.0 PKCE identity, real-time NoSQL streaming, and resilient offline fallbacks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(height: 36),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildArchitectureBadge(
              icon: Icons.flutter_dash_rounded,
              title: 'Flutter 3.24 Multiplatform Engine',
              subtitle: 'GPU-accelerated 60 FPS Web & Mobile pipeline',
              isDark: isDark,
            ),
            _buildArchitectureBadge(
              icon: Icons.lock_outline_rounded,
              title: 'OAuth 2.0 PKCE Security',
              subtitle: 'Google Identity Services stateless token verification',
              isDark: isDark,
            ),
            _buildArchitectureBadge(
              icon: Icons.sync_rounded,
              title: 'Cloud Firestore Reactive Streams',
              subtitle: 'Sub-second real-time sync with local cache persistence',
              isDark: isDark,
            ),
            _buildArchitectureBadge(
              icon: Icons.cloud_upload_outlined,
              title: 'Firebase Multisite Hosting',
              subtitle: 'High-availability global CDN edge distribution',
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArchitectureBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 270),
      child: GlassContainer(
        borderRadius: 18,
        blur: 16,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. BOTTOM CONVERSION CTA
  // ===========================================================================
  Widget _buildBottomCta(ThemeData theme, bool isDark) {
    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return GlassContainer(
      borderRadius: 26,
      blur: 24,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Text(
            'Ready to Streamline Your Academic Journey?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              'Sign in securely with your Google university account and take control of your courses, schedules, and deliverables today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          BouncyTap(
            onTap: _handleGoogleSignIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAccent,
                    const Color(0xFF10B981),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sign In with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. FOOTER
  // ===========================================================================
  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Divider(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2026 Syllo • System Integration & Architecture',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
            BouncyTap(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Back to top',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
