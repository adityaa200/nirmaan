// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NirmaanApp());
}

// --- LOCALIZATION DICTIONARY ---
const Map<String, Map<String, String>> t = {
  'en': {
    'home': 'Home',
    'transit': 'Transit',
    'impact': 'Impact',
    'profile': 'Profile',
    'greeting': 'Good Morning,',
    'quick': 'Quick Actions',
    'recent': 'Recent Platform Activity',
    'attendance': 'Attendance',
    'meals': 'Daily Meals',
    'amenities': 'Amenities',
    'needs': 'Needs',
    'partners': 'Partners',
    'maps': 'Maps',
    'reports': 'Reports',
    'support': 'Support',
    'activities': 'Activities',
  },
  'hi': {
    'home': 'होम',
    'transit': 'पारगमन',
    'impact': 'प्रभाव',
    'profile': 'प्रोफ़ाइल',
    'greeting': 'शुभ प्रभात,',
    'quick': 'त्वरित कार्रवाइयां',
    'recent': 'हाल की गतिविधि',
    'attendance': 'उपस्थिति',
    'meals': 'मध्याह्न भोजन',
    'amenities': 'सुविधाएं',
    'needs': 'ज़रूरतें',
    'partners': 'भागीदार',
    'maps': 'नक्शे',
    'reports': 'रिपोर्ट',
    'support': 'सहायता',
    'activities': 'गतिविधियाँ',
  },
  'mr': {
    'home': 'मुख्यपृष्ठ',
    'transit': 'वाहतूक',
    'impact': 'प्रभाव',
    'profile': 'प्रोफाइल',
    'greeting': 'शुभ सकाळ,',
    'quick': 'जलद क्रिया',
    'recent': 'अलीकडील घडामोडी',
    'attendance': 'हजेरी',
    'meals': 'पोषण आहार',
    'amenities': 'सुविधा',
    'needs': 'गरजा',
    'partners': 'भागीदार',
    'maps': 'नकाशे',
    'reports': 'अहवाल',
    'support': 'मदत',
    'activities': 'इतर उपक्रम',
  },
};

class NirmaanApp extends StatelessWidget {
  const NirmaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirmaan Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

// --- 1. AUTH GATE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) return const LoginScreen();
        return const MainScreen();
      },
    );
  }
}

// --- 2. LOGIN SCREEN (PRO UI) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  String _selectedRole = 'School';
  bool _isLoading = false;

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential res = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(res.user!.uid)
            .set({
              'email': _emailController.text.trim(),
              'name': _nameController.text.trim().isEmpty
                  ? "Unknown"
                  : _nameController.text.trim(),
              'role': _selectedRole,
              'phone': '',
              'address': '',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': userCredential.user!.email,
              'name': userCredential.user!.displayName ?? 'Unknown',
              'role': _selectedRole,
              'phone': '',
              'address': '',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In Failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? Icon(Icons.visibility_off, color: Colors.grey.shade400)
                : null,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.handshake, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "Nirmaan",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // ignore: duplicate_ignore
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Building Trust. Funding Education.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _isLogin
                              ? "Welcome to\nNirmaan!"
                              : "Create an Account",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!_isLogin)
                        _buildTextField(
                          "Organization Name",
                          "Enter full name",
                          _nameController,
                        ),
                      _buildTextField(
                        "Email",
                        "email@organization.com",
                        _emailController,
                      ),
                      _buildTextField(
                        "Password",
                        "••••••••",
                        _passwordController,
                        isPassword: true,
                      ),
                      if (!_isLogin) ...[
                        const Text(
                          "Organization Type",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("School"),
                                value: "School",
                                activeColor: const Color(0xFF3B82F6),
                                // ignore: duplicate_ignore
                                // ignore: deprecated_member_use
                                groupValue: _selectedRole,
                                // ignore: duplicate_ignore
                                // ignore: deprecated_member_use
                                onChanged: (v) => setState(
                                  () => _selectedRole = v.toString(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Corporate"),
                                value: "Corporate",
                                activeColor: const Color(0xFF3B82F6),
                                // ignore: duplicate_ignore
                                // ignore: deprecated_member_use
                                groupValue: _selectedRole,
                                // ignore: duplicate_ignore
                                // ignore: duplicate_ignore
                                // ignore: deprecated_member_use
                                onChanged: (v) => setState(
                                  () => _selectedRole = v.toString(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3B82F6),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isLogin ? "Login" : "Create account",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          "Or Sign in with",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.facebook,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: _signInWithGoogle,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                "G",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account?"
                                  : "Already have an account?",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _isLogin = !_isLogin;
                                _passwordController.clear();
                              }),
                              child: Text(
                                _isLogin ? "Sign Up" : "Sign In",
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. CURVED NAVIGATION CONTROLLER WITH CHATBOT FAB ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'Unknown';
  String _userName = 'User';
  String _lang = 'en';
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'Unknown';
          _userName =
              doc.data()?['name'] ?? user.email?.split('@')[0] ?? 'User';
        });
      }
    }
  }

  void _changeLanguage(String newLang) {
    setState(() => _lang = newLang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        physics: const BouncingScrollPhysics(),
        children: [
          _userRole == 'Admin'
              ? AdminDashboardTab(userName: _userName, lang: _lang)
              : AnimatedDashboardTab(
                  userName: _userName,
                  userRole: _userRole,
                  lang: _lang,
                ),
          ActiveMatchesScreen(userRole: _userRole, lang: _lang),
          ImpactReportsScreen(userRole: _userRole, lang: _lang),
          ProfileSettingsScreen(
            currentLang: _lang,
            onLanguageChanged: _changeLanguage,
          ),
        ],
      ),
      extendBody: true,

      // NEW: GLOBALLY ACCESSIBLE AI CHATBOT BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NirmaanBotScreen()),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        backgroundColor: Colors.transparent,
        color: const Color(0xFF0F172A),
        buttonBackgroundColor: const Color(0xFF3B82F6),
        height: 65,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOutCubic,
        items: const <Widget>[
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.local_shipping_rounded, size: 30, color: Colors.white),
          Icon(Icons.analytics_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}

// --- 4. PREMIUM BENTO-BOX DASHBOARD TAB (PRO UI) ---
class AnimatedDashboardTab extends StatelessWidget {
  final String userName;
  final String userRole;
  final String lang;

  const AnimatedDashboardTab({
    super.key,
    required this.userName,
    required this.userRole,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t[lang]!['greeting']!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF3B82F6),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            // ignore: duplicate_ignore
                            // ignore: deprecated_member_use
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Impact",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userRole == 'School' ? "12 Items" : "12 Funded",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 200,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF10B981),
                                    size: 28,
                                  ),
                                  const Spacer(),
                                  Text(
                                    userRole == 'Corporate'
                                        ? "Gold Tier"
                                        : "Verified",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    "Trust Status",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 28,
                                  ),
                                  const Spacer(),
                                  const Text(
                                    "3 Active",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    t[lang]!['needs']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      t[lang]!['quick']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: userRole == 'School'
                          ? [
                              _buildActionPod(
                                context,
                                Icons.co_present_rounded,
                                t[lang]!['attendance']!,
                                const Color(0xFF10B981),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AttendanceScreen(),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.restaurant_rounded,
                                t[lang]!['meals']!,
                                const Color(0xFFF59E0B),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MealTrackerScreen(),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.celebration_rounded,
                                t[lang]!['activities']!,
                                const Color(0xFFEC4899),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ExtraActivitiesScreen(),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.water_drop_rounded,
                                t[lang]!['amenities']!,
                                const Color(0xFF0EA5E9),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AmenitiesScreen(),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.inventory_2_rounded,
                                t[lang]!['needs']!,
                                const Color(0xFF8B5CF6),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SchoolNeedsScreen(userRole: userRole),
                                  ),
                                ),
                              ),
                            ]
                          : [
                              _buildActionPod(
                                context,
                                Icons.business_rounded,
                                t[lang]!['partners']!,
                                const Color(0xFF0EA5E9),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PartnersScreen(),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.inventory_2_rounded,
                                t[lang]!['needs']!,
                                const Color(0xFF3B82F6),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SchoolNeedsScreen(userRole: userRole),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.receipt_long_rounded,
                                t[lang]!['reports']!,
                                const Color(0xFF8B5CF6),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImpactReportsScreen(
                                      userRole: userRole,
                                      lang: lang,
                                    ),
                                  ),
                                ),
                              ),
                              _buildActionPod(
                                context,
                                Icons.support_agent_rounded,
                                t[lang]!['support']!,
                                const Color(0xFFF59E0B),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SupportScreen(),
                                  ),
                                ),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 16,
              ),
              child: Text(
                t[lang]!['recent']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requirements')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "No activity yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              final docs = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  bool isPending = data['status'] == 'Pending';
                  return Container(
                    margin: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isPending
                                ? Icons.pending_actions_rounded
                                : Icons.check_circle_rounded,
                            color: isPending
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['school'] ?? 'School',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPending
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Text(
                            data['status'] ?? 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isPending
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF2563EB),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: docs.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildActionPod(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5A. SCHOOL MODULE: ATTENDANCE TRACKER ---
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Log attendance with a verified classroom photo to maintain transparency for sponsors.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Camera package integration required to take photo.",
                ),
              ),
            ),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.teal,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, size: 40, color: Colors.teal),
                  SizedBox(height: 10),
                  Text(
                    "Click to Capture Classroom Photo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildClassCard("Class 1", "45/50 Present", Colors.green),
          _buildClassCard("Class 2", "48/50 Present", Colors.green),
          _buildClassCard("Class 3", "Pending Logging", Colors.orange),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Log Today's Data"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildClassCard(String cls, String status, Color col) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        title: Text(cls, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: col,
        ),
      ),
    );
  }
}

// --- 5B. SCHOOL MODULE: MEAL TRACKER ---
class MealTrackerScreen extends StatelessWidget {
  const MealTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mid-Day Meal Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Today's Menu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Dal, Rice, and Seasonal Vegetable",
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Camera package integration required to take photo.",
                ),
              ),
            ),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.fastfood, size: 40, color: Colors.orange),
                  SizedBox(height: 10),
                  Text(
                    "Click to Capture Today's Meal Photo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Recent Logs",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const ListTile(
            leading: Icon(Icons.restaurant, color: Colors.orange),
            title: Text(
              "April 05: 142 Students Fed",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Verified by Principal with Photo"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Log Today's Meal"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// --- 5C. SCHOOL MODULE: EXTRA ACTIVITIES ---
class ExtraActivitiesScreen extends StatelessWidget {
  const ExtraActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Extra Activities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Showcase school spirit! Log sports days, cultural events, or workshops.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Open form to add new activity.")),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pinkAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle, color: Colors.pinkAccent),
                  SizedBox(width: 10),
                  Text(
                    "Add New Event / Activity",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Past Events",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            "Tree Plantation Drive",
            "March 22",
            Icons.nature_people,
            Colors.green,
          ),
          _buildActivityCard(
            "Annual Sports Day",
            "Feb 10",
            Icons.sports_soccer,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String date,
    IconData icon,
    Color col,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: col.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: col),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

// --- 5D. SCHOOL MODULE: AMENITIES AUDIT ---
class AmenitiesScreen extends StatelessWidget {
  const AmenitiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Infrastructure Audit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "If an amenity is broken, marking it here can alert potential corporate sponsors.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildAuditTile(Icons.water_drop, "Drinking Water", true),
          _buildAuditTile(Icons.wc, "Functional Toilets", false),
          _buildAuditTile(Icons.electrical_services, "Electricity/Power", true),
        ],
      ),
    );
  }

  Widget _buildAuditTile(IconData icon, String title, bool isOk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: isOk ? Colors.blue : Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Switch(
          value: isOk,
          onChanged: (val) {},
          activeColor: Colors.green,
        ),
      ),
    );
  }
}

// --- 6. SCHOOL NEEDS (WITH PAYMENT) ---
class SchoolNeedsScreen extends StatefulWidget {
  final String userRole;
  const SchoolNeedsScreen({super.key, required this.userRole});
  @override
  State<SchoolNeedsScreen> createState() => _SchoolNeedsScreenState();
}

class _SchoolNeedsScreenState extends State<SchoolNeedsScreen> {
  final _db = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _schoolController = TextEditingController();

  void _showPaymentGateway(String docId, String itemTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Sponsor: $itemTitle",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              "Select a secure payment method.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildPaymentOption(
              Icons.account_balance_wallet,
              "UPI Payment",
              "Google Pay, PhonePe, Paytm",
              Colors.green,
              () => _processPayment(docId),
            ),
            _buildPaymentOption(
              Icons.credit_card,
              "Credit / Debit Card",
              "Visa, MasterCard",
              Colors.blue,
              () => _processPayment(docId),
            ),
            _buildPaymentOption(
              Icons.account_balance,
              "Net Banking",
              "Direct Bank Transfer",
              Colors.orange,
              () => _processPayment(docId),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _processPayment(String docId) {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Processing securely..."),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      await _db.collection('requirements').doc(docId).update({
        'status': 'Sponsoring',
        'sponsorId': FirebaseAuth.instance.currentUser?.uid,
        'matchDate': FieldValue.serverTimestamp(),
      });

      final String receiptId =
          "TXN${Random().nextInt(999999).toString().padLeft(6, '0')}";
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Payment Successful",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Ref ID: $receiptId",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Thank you! The school has been notified and logistics are now tracking.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform Requirements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('requirements')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              bool isPending = data['status'] == 'Pending';
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              data['status'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: data['status'] == 'Delivered'
                                ? Colors.green
                                : (isPending ? Colors.orange : Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['school'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Maps API required. Opening location data...",
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                      if (widget.userRole == 'Corporate' && isPending) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _showPaymentGateway(docs[i].id, data['title']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Fund This Project",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.userRole == 'School'
          ? FloatingActionButton.extended(
              onPressed: _showForm,
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                "New Need",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  void _showForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Post a Requirement",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "What do you need?",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _schoolController,
              decoration: InputDecoration(
                labelText: "School Name",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _db.collection('requirements').add({
                  'title': _titleController.text,
                  'school': _schoolController.text,
                  'status': 'Pending',
                  'postedBy': FirebaseAuth.instance.currentUser?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text("Publish to Platform"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 7. ACTIVE MATCHES ---
class ActiveMatchesScreen extends StatelessWidget {
  final String userRole;
  final String lang;
  const ActiveMatchesScreen({
    super.key,
    required this.userRole,
    required this.lang,
  });

  void _confirmReceipt(String docId) async {
    await FirebaseFirestore.instance
        .collection('requirements')
        .doc(docId)
        .update({
          'status': 'Delivered',
          'deliveryDate': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Query query = FirebaseFirestore.instance
        .collection('requirements')
        .where('status', isEqualTo: 'Sponsoring');
    if (userRole == 'Corporate') {
      query = query.where('sponsorId', isEqualTo: uid);
    } else {
      query = query.where('postedBy', isEqualTo: uid);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t[lang]!['transit']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No items currently in transit.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.blue),
                  ),
                  title: Text(
                    data['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Destination:\n${data['school']}"),
                  ),
                  trailing: userRole == 'School'
                      ? ElevatedButton(
                          onPressed: () => _confirmReceipt(docs[i].id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Mark Received"),
                        )
                      : const Chip(
                          label: Text("In Transit"),
                          backgroundColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 8. PARTNERS & REPORTS ---
class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Corporate Partners',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Corporate')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3B82F6),
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  title: Text(
                    data['name'] ?? data['email'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Verified CSR Contributor"),
                  trailing: const Icon(Icons.verified, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ImpactReportsScreen extends StatelessWidget {
  final String userRole;
  final String lang;
  const ImpactReportsScreen({
    super.key,
    required this.userRole,
    required this.lang,
  });

  String _getBadge(int count) {
    if (count >= 10) return "👑 Platinum Partner";
    if (count >= 5) return "🥇 Gold Partner";
    if (count >= 2) return "🥈 Silver Partner";
    if (count >= 1) return "🥉 Bronze Partner";
    return "🌱 Rising Partner";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t[lang]!['impact']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Transparency and accountability are the core of Nirmaan. Below are the verified delivery metrics.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),
            StreamBuilder<QuerySnapshot>(
              stream: userRole == 'Corporate'
                  ? db
                        .collection('requirements')
                        .where('sponsorId', isEqualTo: uid)
                        .where('status', isEqualTo: 'Delivered')
                        .snapshots()
                  : db
                        .collection('requirements')
                        .where('postedBy', isEqualTo: uid)
                        .where('status', isEqualTo: 'Delivered')
                        .snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Column(
                  children: [
                    if (userRole == 'Corporate') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          "Status: ${_getBadge(count)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildStatTile(
                      userRole == 'Corporate'
                          ? "Your Total Impact"
                          : "Items Received",
                      count.toString(),
                      "Verified successful deliveries",
                      const Color(0xFF3B82F6),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('requirements')
                  .where('status', isEqualTo: 'Delivered')
                  .snapshots(),
              builder: (context, snapshot) {
                int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatTile(
                  "Global Deliveries",
                  total.toString(),
                  "Items reached schools platform-wide",
                  Colors.purpleAccent,
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String val, String sub, Color col) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: col,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}

// --- 9. SUPPORT SCREEN ---
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Help & Support",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.support_agent, size: 80, color: Color(0xFF3B82F6)),
          const SizedBox(height: 20),
          const Text(
            "How can we help you?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildFaqTile("How do I update my payment method?"),
          _buildFaqTile("How is school data verified?"),
          _buildFaqTile("Where can I download tax exemption forms?"),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Email client opened.")),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Contact Administrator",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Detailed answer goes here based on platform policies.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 10. EDIT PROFILE SCREEN ---
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData['name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.userData['address'] ?? '',
    );
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Organization Name",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Office Address",
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }
}

// --- 11. EXPANDED PROFILE TAB ---
class ProfileSettingsScreen extends StatelessWidget {
  final String currentLang;
  final Function(String) onLanguageChanged;

  const ProfileSettingsScreen({
    super.key,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return ListView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t[currentLang]!['profile']!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF3B82F6),
                      size: 30,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(userData: userData),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF3B82F6),
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData['name'] ?? user?.email?.split('@')[0] ?? "User",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      user?.email ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                "Organization Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                Icons.phone,
                userData['phone']?.isEmpty ?? true
                    ? "Add Phone Number"
                    : userData['phone'],
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userData: userData),
                  ),
                ),
              ),
              _buildSettingsTile(
                Icons.location_city,
                userData['address']?.isEmpty ?? true
                    ? "Add Office Address"
                    : userData['address'],
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userData: userData),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "App Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF0F172A)),
                  ),
                  title: const Text(
                    "Language",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: DropdownButton<String>(
                    value: currentLang,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text("English")),
                      DropdownMenuItem(
                        value: 'hi',
                        child: Text("हिंदी (Hindi)"),
                      ),
                      DropdownMenuItem(
                        value: 'mr',
                        child: Text("मराठी (Marathi)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) onLanguageChanged(val);
                    },
                  ),
                ),
              ),
              _buildSettingsTile(
                Icons.notifications_outlined,
                "Notifications",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                ),
              ),
              _buildSettingsTile(
                Icons.security_outlined,
                "Privacy & Security",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                ),
              ),
              _buildSettingsTile(
                Icons.help_outline,
                "Help & Support",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                ),
              ),

              _buildSettingsTile(
                Icons.info_outline,
                "About Nirmaan",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// --- 12. ABOUT APP SCREEN ---
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "About Nirmaan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.handshake, size: 80, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Nirmaan",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Center(
              child: Text(
                "Building Trust. Funding Education.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Nirmaan is a comprehensive digital platform designed to bridge the gap between Corporate Social Responsibility (CSR) sponsors and under-resourced public schools. It uniquely combines a transparent crowdfunding marketplace with a daily school management system to solve the biggest hurdle in educational funding: trust.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              "By allowing schools to log verifiable daily data—such as student attendance with photo proofs, mid-day meal records, and infrastructure audits—Nirmaan creates a transparent, auditable trail of a school's operations.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              "Corporate sponsors can confidently browse these verified profiles, identify specific infrastructure needs, and fund them directly through an integrated payment gateway. The platform further encourages corporate participation by providing real-time logistics tracking and gamified impact reports.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- 13. MASTER ADMIN DASHBOARD ---
class AdminDashboardTab extends StatelessWidget {
  final String userName;
  final String lang;

  const AdminDashboardTab({
    super.key,
    required this.userName,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Master Control",
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFFEE2E2),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xFFEF4444),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F172A), Color(0xFF334155)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Total Platform Volume",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "₹ 4.2L",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 200,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildAdminStatCard(
                              "Users",
                              "148",
                              Icons.people_alt_rounded,
                              const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildAdminStatCard(
                              "Pending",
                              "12",
                              Icons.pending_actions_rounded,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Admin Tools",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        _buildActionPod(
                          context,
                          Icons.verified_user_rounded,
                          "Verify Users",
                          const Color(0xFF10B981),
                          () {},
                        ),
                        _buildActionPod(
                          context,
                          Icons.receipt_long_rounded,
                          "Audit Logs",
                          const Color(0xFF3B82F6),
                          () {},
                        ),
                        _buildActionPod(
                          context,
                          Icons.flag_rounded,
                          "Reports",
                          const Color(0xFFEF4444),
                          () {},
                        ),
                        _buildActionPod(
                          context,
                          Icons.settings_rounded,
                          "System",
                          const Color(0xFF64748B),
                          () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildAdminStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPod(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 14. NIRMAAN AI CHATBOT (NEW) ---
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class NirmaanBotScreen extends StatefulWidget {
  const NirmaanBotScreen({super.key});

  @override
  State<NirmaanBotScreen> createState() => _NirmaanBotScreenState();
}

class _NirmaanBotScreenState extends State<NirmaanBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I am the Nirmaan AI Support Guide. How can I help you today?",
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _controller.clear();
      _isTyping = true;
    });

    // Simulated AI Delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple keyword-based logic engine
    String botReply =
        "I'm still learning! You can reach a human administrator through the Support tab.";
    String lowerText = userText.toLowerCase();

    if (lowerText.contains("fund") ||
        lowerText.contains("pay") ||
        lowerText.contains("sponsor")) {
      botReply =
          "To fund a school project, go to the 'Needs' tab, select an item, and you can pay securely using UPI, Credit Card, or Net Banking.";
    } else if (lowerText.contains("school") ||
        lowerText.contains("attendance") ||
        lowerText.contains("meal")) {
      botReply =
          "As a school, you can use the Quick Actions on your dashboard to log daily attendance, meals, and infrastructure audits. Make sure to upload photo proof!";
    } else if (lowerText.contains("hello") || lowerText.contains("hi")) {
      botReply =
          "Hello! I am here to help you navigate Nirmaan. Do you need help with funding, school operations, or your profile?";
    } else if (lowerText.contains("profile") ||
        lowerText.contains("password")) {
      botReply =
          "You can update your organization details like phone number and address by clicking the Edit icon in the Profile tab.";
    }

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: botReply, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text(
              'Nirmaan AI Guide',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF3B82F6)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: msg.isUser
                            ? const Radius.circular(20)
                            : const Radius.circular(0),
                        bottomRight: msg.isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        if (!msg.isUser)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nirmaan AI is typing...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask me anything...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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
}
