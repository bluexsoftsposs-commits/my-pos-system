import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'plans_screen.dart';
import 'super_admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnim;
  late Animation<double> _textAnim;
  late Animation<double> _spinnerAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    const reveal = Cubic(0.16, 1.0, 0.3, 1.0);

    _logoAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: reveal),
      ),
    );

    _textAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.7, curve: reveal),
      ),
    );

    _spinnerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.85, curve: reveal),
      ),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      if (auth.isSuperAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
        );
      } else if (auth.requiresPayment) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PlansScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF131313), Color(0xFF1A1535)],
          ),
        ),
        child: Stack(
          children: [
            const _PulsingGlow(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildTypography(),
                  const SizedBox(height: 48),
                  _buildSpinner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _logoAnim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _logoAnim.value)),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C5CE7).withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.12),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.desktop_windows,
              size: 56,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypography() {
    return AnimatedBuilder(
      animation: _textAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _textAnim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _textAnim.value)),
            child: child,
          ),
        );
      },
      child: const Column(
        children: [
          Text(
            'BluexSofts POS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE5E2E1),
              height: 32 / 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Modern Retail Solutions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFFC8C4D7),
              height: 24 / 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner() {
    return AnimatedBuilder(
      animation: _spinnerAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _spinnerAnim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _spinnerAnim.value)),
            child: child,
          ),
        );
      },
      child: const Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC6BFFF)),
              backgroundColor: Color(0x1AC6BFFF),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'INITIALIZING SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: Color(0x99C6BFFF),
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingGlow extends StatefulWidget {
  const _PulsingGlow();

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;
  const _GlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final radius = size.width * 0.6 * (0.9 + progress * 0.1);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withOpacity(0.12 + progress * 0.06),
          const Color(0xFF6C5CE7).withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
