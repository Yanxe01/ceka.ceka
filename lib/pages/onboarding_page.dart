import 'package:flutter/material.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      image: 'assets/images/gambar1.png',
      title: 'Buat grup serumahmu',
      description:
          'Undang teman satu kos atau kontrakanmu untuk mengelola pengeluaran bersama di ',
      boldText: 'satu tempat.',
      titleFontSize: 31,
      titleTop: 570,
      descriptionTop: 610,
    ),
    OnboardingContent(
      image: 'assets/images/gambar2.png',
      title: 'Catat Bon,\nKami yang Bagi',
      description:
          'Cukup masukkan total tagihan, aplikasi akan menghitung jatah per orang secara ',
      boldText: 'otomatis, adil, dan transparan.',
    ),
    OnboardingContent(
      image: 'assets/images/gambar3.png',
      title: 'Hidup Bareng\nLebih Damai',
      description:
          'Tak ada lagi drama "gak enakan" atau lupa bayar. Semua tahu jatahnya, ',
      boldText: 'pertemanan tetap terjaga.',
      titleFontSize: 32,
      titleTop: 463,
      descriptionTop: 545,
      imageWidth: 319,
      imageHeight: 273,
      imageTop: 164,
      imageLeft: 47,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onMulaiPressed() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _contents.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_contents[index]);
                  },
                ),
              ),

              // Mulai button (only on last page)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentPage == _contents.length - 1
                    ? Padding(
                        key: const ValueKey('mulai_button'),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: 94,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: _onMulaiPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0DB662),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Mulai',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('empty_button'),
                        height: 54,
                      ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _contents.length,
                    (index) => _buildDot(index),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPage(OnboardingContent content) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background decorative element (design1.png)
            Positioned(
              left: 0,
              right: 0,
              top: 120,
              child: Center(
                child: Transform.rotate(
                  angle: 135 * 3.14159 / 180,
                  child: Image.asset(
                    'assets/images/design1.png',
                    width: 380,
                    height: 380,
                    opacity: const AlwaysStoppedAnimation(0.8),
                  ),
                ),
              ),
            ),

            // Main image
            Positioned(
              left: content.imageLeft,
              top: content.imageTop,
              child: Image.asset(
                content.image,
                width: content.imageWidth,
                height: content.imageHeight,
                fit: BoxFit.contain,
              ),
            ),

            // Title
            Positioned(
              left: 25,
              top: content.titleTop,
              right: 25,
              child: Text(
                content.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: content.titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF44444C),
                  height: 1.2,
                  letterSpacing: -0.62,
                ),
              ),
            ),

            // Description
            Positioned(
              left: 29,
              top: content.descriptionTop,
              right: 29,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xCC44444C),
                    height: 1.2,
                    letterSpacing: -0.32,
                  ),
                  children: [
                    TextSpan(text: content.description),
                    TextSpan(
                      text: content.boldText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5.5),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF087B42)
            : const Color(0xFF087B42).withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingContent {
  final String image;
  final String title;
  final String description;
  final String boldText;
  final double titleFontSize;
  final double titleTop;
  final double descriptionTop;
  final double imageWidth;
  final double imageHeight;
  final double imageTop;
  final double imageLeft;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
    required this.boldText,
    this.titleFontSize = 31,
    this.titleTop = 540,
    this.descriptionTop = 620,
    this.imageWidth = 326,
    this.imageHeight = 326,
    this.imageTop = 200,
    this.imageLeft = 42,
  });
}
