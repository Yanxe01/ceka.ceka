import 'package:flutter/material.dart';
import 'groups_page.dart';
import 'activity_page.dart';
import 'profile_page.dart'; // Import halaman profile baru
import '../models/group_data.dart';
import 'group_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // --- LOGIKA NAVIGASI UTAMA ---
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
              ? const GroupsPage()
              : _selectedIndex == 2
                  ? const ActivityPage()
                  : const ProfilePage(), // Menampilkan ProfilePage di tab index 3

      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Ringkasan total section
                    Text(
                      'Ringkasan total anda',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: -0.44,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Utang :', 'Rp. 187.500.00')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Piutang :', 'Rp. 87.000.00')),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Grup saya section
                    Text(
                      'Grup saya',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: -0.44,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Group list (MENGGUNAKAN DATA GLOBAL)
                    ...List.generate(globalGroupList.length, (index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildGroupCard(globalGroupList[index]),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF087B42),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Halo, Ian!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 26, 218, 122).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF0DB662).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF087B42),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupItem group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailPage(group: group),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 26, 218, 122).withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF0DB662).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            // GROUP IMAGE
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(group.image),
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 16),

            // GROUP NAME
            Expanded(
              child: Text(
                group.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(23),
        topRight: Radius.circular(23),
      ),
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF087B42),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.group_rounded, 'Group', 1),
            _buildNavItem(Icons.receipt_long_rounded, 'Activity', 2),
            _buildNavItem(Icons.person_rounded, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 28 : 25,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}