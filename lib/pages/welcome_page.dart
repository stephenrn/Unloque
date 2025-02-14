import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Add this import
import 'sign_in_card.dart';
import 'sign_up_card.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  bool showSignIn = false;
  bool showSignUp = false;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Increase duration to make animation slower
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _toggleSignIn() {
    setState(() {
      showSignIn = !showSignIn;
      if (showSignIn) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _toggleSignUp() {
    setState(() {
      showSignUp = !showSignUp;
      if (showSignUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _resetView() {
    setState(() {
      showSignIn = false;
      showSignUp = false;
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color.fromARGB(255, 53, 147, 255)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 45),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/images/Logo.png',
                          height: 50,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Unloque',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 50,
                            color: const Color.fromARGB(255, 9, 106, 131),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 80),
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 135, 184, 233),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 10),
                      ),
                      child: Icon(
                        Icons.location_city_outlined,
                        size: 150,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'By tapping "Create account" or "Sign in", you agree to our '),
                            TextSpan(
                              text: 'Terms',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Add your link here
                              },
                            ),
                            TextSpan(text: '. Learn how we process your data in our '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Add your link here
                              },
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Cookies Policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Add your link here
                              },
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    RoundedButton(
                      onTap: _toggleSignUp,
                      label: 'CREATE ACCOUNT',
                      isFilled: true,
                    ),
                    SizedBox(height: 20),
                    RoundedButton(
                      onTap: _toggleSignIn,
                      label: 'SIGN IN',
                      isFilled: false,
                    ),
                  ],
                ),
                if (showSignIn || showSignUp)
                  SlideTransition(
                    position: _offsetAnimation,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 50) {
                          _resetView();
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (showSignIn)
                              Dismissible(
                                key: Key('signInCard'),
                                direction: DismissDirection.down,
                                onDismissed: (direction) {
                                  _resetView();
                                },
                                child: SignInCard(onBack: _resetView),
                              ),
                            if (showSignUp)
                              Dismissible(
                                key: Key('signUpCard'),
                                direction: DismissDirection.down,
                                onDismissed: (direction) {
                                  _resetView();
                                },
                                child: SignUpCard(onBack: _resetView),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isFilled;

  const RoundedButton({
    Key? key,
    required this.onTap,
    required this.label,
    this.isFilled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 50,
        decoration: BoxDecoration(
          color: isFilled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isFilled ? null : Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isFilled ? const Color.fromARGB(255, 80, 151, 243) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
