import 'package:flutter/material.dart';
import 'registration_page.dart';
import 'onboarding_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                left: -70,
                top: 80,
                child: Transform.rotate(
                  angle: 150 * 3.14159 / 180,
                  child: Image.asset(
                    'assets/images/design1.png',
                    width: 220,
                    height: 220,
                    opacity: const AlwaysStoppedAnimation(0.7),
                  ),
                ),
              ),
              Positioned(
                right: -30,
                top: 160,
                child: Transform.rotate(
                  angle: 139.92 * 3.14159 / 180,
                  child: Image.asset(
                    'assets/images/design1.png',
                    width: 220,
                    height: 220,
                    opacity: const AlwaysStoppedAnimation(0.7),
                  ),
                ),
              ),

              // Welcome text
              Positioned(
                top: 170,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Center(
                    child: Text(
                      'Welcome!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF44444C),
                        letterSpacing: 0.32,
                      ),
                    ),
                  ),
                ),
              ),

              // Main login card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 15,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 31),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 72),

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'Email Address',
                              obscureText: false,
                            ),
                            const SizedBox(height: 24),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8F9098),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Forgot password
                            GestureDetector(
                              onTap: () {
                                // Handle forgot password
                              },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0DB662),
                                ),
                              ),
                            ),
                            const SizedBox(height: 21),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to onboarding page
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OnboardingPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0DB662),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 19),

                            // Register link
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF71727A),
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: "Don't Have an Account? "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegistrationPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Register now',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0DB662),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 19),

                            // Divider
                            const Divider(
                              color: Color(0xFF44444C),
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 24),

                            // Social login section
                            const Center(
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF71727A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Social buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  icon: Icons.g_mobiledata,
                                  color: const Color(0xFFA46651),
                                  onTap: () {},
                                ),
                                const SizedBox(width: 12),
                                _buildSocialButton(
                                  icon: Icons.apple,
                                  color: const Color(0xFF087B42),
                                  onTap: () {},
                                ),
                                const SizedBox(width: 12),
                                _buildSocialButton(
                                  icon: Icons.facebook,
                                  color: const Color(0xFF0DB662),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0DB662), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2F3036),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8F9098),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
