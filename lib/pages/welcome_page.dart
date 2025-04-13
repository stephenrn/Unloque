import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unloque/components/username_dialog.dart';
import '../pages/home_page.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _statusMessage = '';
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  final PageController _programsController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _availablePrograms = [
    {
      'title': 'Social',
      'organization': 'DSWD, DOLE, etc.',
      'color': Colors.blue[700]!,
      'icon': Icons.people_alt_outlined,
    },
    {
      'title': 'Healthcare',
      'organization': 'DOH, PhilHealth, etc.',
      'color': Colors.red[700]!,
      'icon': Icons.local_hospital_outlined,
    },
    {
      'title': 'Education',
      'organization': 'DepEd, CHED, etc.',
      'color': Colors.green[700]!,
      'icon': Icons.school_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn));
    _animationController!.forward();

    // Auto-scroll programs
    _startProgramsAutoScroll();
  }

  void _startProgramsAutoScroll() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        if (_programsController.hasClients) {
          final nextPage = (_currentPage + 1) % _availablePrograms.length;
          _programsController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
        _startProgramsAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _programsController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Google...';
    });

    try {
      // Start Google sign-in process
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

      if (gUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Google account selected, authenticating...';
      });

      // Get authentication details
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Signing in to Firebase...';
      });

      // Sign in with Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        setState(() {
          _statusMessage = 'Checking user profile...';
        });

        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists && mounted) {
          setState(() {
            _statusMessage = 'Setting up your profile...';
          });

          // Show username dialog for new users
          final username = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => UsernameDialog(),
          );

          if (username != null && mounted) {
            // Create user profile with custom username
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'email': userCredential.user!.email!,
              'username': username,
              'photoUrl': userCredential.user!.photoURL,
              'createdAt': Timestamp.now(),
            });

            if (!mounted) return;
            setState(() {
              _statusMessage = 'Profile created successfully!';
            });
          }
        }

        // Important: Remove the Future.delayed to avoid any race conditions
        // and just navigate immediately
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _statusMessage = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final fadeAnimation = _fadeAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
                height: screenHeight *
                    0.03), // Reduced top padding from 0.05 to 0.03

            // Header section - reduced height further to eliminate need for negative margin
            Container(
              height: screenHeight * 0.13, // Further reduced from 0.15 to 0.13
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and app name with subtle animation
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/images/Logo.png',
                          height: 40,
                          width: 40,
                        ),
                        SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Unlo',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 38,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: 'que',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w300,
                                  fontSize: 38,
                                  color: Colors.blue[300],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8), // Reduced from 12 to 8

                  // Tagline with local theme
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Text(
                      'Your Gateway to Government Social Programs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
                height: screenHeight *
                    0.03), // Reduced space between header and slider
            // Programs slider section - use transform instead of negative margin
            Transform.translate(
              offset: Offset(0,
                  -5), // Move up by 5 pixels instead of using negative margin
              child: Container(
                height: screenHeight * 0.33,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                margin:
                    EdgeInsets.symmetric(horizontal: 20), // No negative margin
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text(
                        'Available Programs',
                        style: TextStyle(
                          fontSize: 18, // Slightly bigger
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text
                        ),
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: _programsController,
                        itemCount: _availablePrograms.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final program = _availablePrograms[index];
                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10), // More vertical margin
                            decoration: BoxDecoration(
                              color: Colors
                                  .grey[850], // Slightly darker card background
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey[700]!, width: 1),
                            ),
                            padding: EdgeInsets.all(20), // Increased padding
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                      16), // Larger icon container
                                  decoration: BoxDecoration(
                                    color: program['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    program['icon'],
                                    size: 36, // Larger icon
                                    color: Colors.white, // White icon
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        program[
                                            'title'], // Simplified category titles
                                        style: TextStyle(
                                          fontSize: 24, // Slightly larger text
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white, // White text
                                        ),
                                      ),
                                      SizedBox(height: 8), // More spacing
                                      Text(
                                        program['organization'],
                                        style: TextStyle(
                                          fontSize: 16, // Larger text
                                          color:
                                              Colors.grey[400], // Lighter gray
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Colors.grey[400]), // Larger icon
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Page indicator dots
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 16.0), // More bottom padding
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _availablePrograms.length,
                            (index) => Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 5), // Larger margin
                              width: 10, // Larger dots
                              height: 10, // Larger dots
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors
                                        .blue[300] // Highlight color changed
                                    : Colors.grey[600], // Dimmer inactive dots
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

            // App description section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Unloque',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to light color
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Unloque helps Filipinos easily apply for government programs with transparent resource allocation and data visualization.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400], // Changed to light color
                      ),
                    ),

                    SizedBox(height: 15),

                    // Feature row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureBox(
                          icon: Icons.map_outlined,
                          label: "Map Data",
                        ),
                        _buildFeatureBox(
                          icon: Icons.description_outlined,
                          label: "Easy Apply",
                        ),
                        _buildFeatureBox(
                          icon: Icons.verified_outlined,
                          label: "Verification",
                        ),
                      ],
                    ),

                    Spacer(),

                    // Status message (if any)
                    if (_statusMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(
                              0.2), // More visible on dark background
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue[300]!), // Lighter blue
                                    )
                                  : Icon(Icons.info_outline,
                                      color: Colors.blue[300],
                                      size: 16), // Lighter blue
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[300], // Lighter blue
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Sign-in Button (inverted colors)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // White button
                          foregroundColor: Colors.grey[850], // Dark text
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/images/google.png',
                              height: 22,
                              width: 22,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Version info
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Unloque v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
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
    );
  }

  Widget _buildFeatureBox({required IconData icon, required String label}) {
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800], // Darker box
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!), // Darker border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Darker shadow
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white, // White icon
            size: 24,
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[300], // Light text
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
