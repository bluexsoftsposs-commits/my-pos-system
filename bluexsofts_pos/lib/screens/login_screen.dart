import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'plans_screen.dart';
import 'super_admin_screen.dart';
import 'sub_admin_screen.dart';
import 'supplier_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController(text: 'BluexSofts Demo Shop');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLeaving = false;

  late AnimationController _animController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _field1Opacity;
  late Animation<double> _field2Opacity;
  late Animation<double> _field3Opacity;
  late Animation<double> _field4Opacity;
  late Animation<double> _field5Opacity;
  late Animation<double> _field6Opacity;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));

    _field1Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.12, 0.5, curve: Curves.easeOut),
    );
    _field2Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.22, 0.55, curve: Curves.easeOut),
    );
    _field3Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.32, 0.6, curve: Curves.easeOut),
    );
    _field4Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.42, 0.65, curve: Curves.easeOut),
    );
    _field5Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.52, 0.7, curve: Curves.easeOut),
    );
    _field6Opacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.62, 0.8, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () => _animController.forward());
  }

  @override
  void dispose() {
    _animController.dispose();
    _shopNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      shopName: _shopNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      setState(() => _isLeaving = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Widget destination;
      if (auth.isSuperAdmin) {
        destination = const SuperAdminScreen();
      } else if (auth.isSubAdmin) {
        destination = const SubAdminScreen();
      } else if (auth.isSupplier) {
        destination = const SupplierScreen();
      } else if (auth.requiresPayment) {
        destination = const PlansScreen();
      } else {
        destination = const DashboardScreen();
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      _showErrorSnack(auth.error ?? 'Authentication failed');
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Row(
              children: [
                Expanded(child: _buildBrandingPanel()),
                Expanded(child: _buildRightPanel()),
              ],
            );
          }

          return _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.loginGradient),
      child: Center(
        child: AnimatedOpacity(
          opacity: _isLeaving ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'BluexSofts POS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete point of sale solution\nfor your retail business.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: AppTheme.darkBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLoginCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.loginGradient),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: AnimatedOpacity(
                  opacity: _isLeaving ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.point_of_sale,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLoginCard(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to your account to continue.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _field1Opacity,
              child: _buildShopField(),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _field2Opacity,
              child: _buildEmailField(),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _field3Opacity,
              child: _buildPasswordField(),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _field4Opacity,
              child: _buildRememberRow(),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _field5Opacity,
              child: _buildSignInButton(),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _field6Opacity,
              child: _buildBottomLinks(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopField() {
    return TextFormField(
      controller: _shopNameCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Shop Name',
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        hintText: 'Enter __super_admin__ for admin panel',
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        prefixIcon: Icon(Icons.store_outlined, size: 20, color: Colors.grey[500]),
        filled: true,
        fillColor: AppTheme.darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(Icons.email_outlined, size: 20, color: Colors.grey[500]),
        filled: true,
        fillColor: AppTheme.darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, size: 20, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey[500],
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: AppTheme.darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
    );
  }

  Widget _buildRememberRow() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (v) => setState(() => _rememberMe = v ?? false),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppTheme.primary;
              return Colors.transparent;
            }),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.grey[600]!, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Remember this device for 30 days',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBottomLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('|', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Don't have an account? Contact Sales",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: Text('Terms of Service', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
        ),
        GestureDetector(
          onTap: () {},
          child: Text('System Status', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ),
      ],
    );
  }
}
