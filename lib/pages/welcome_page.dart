import 'package:flutter/material.dart';
import 'package:unloque/components/continueButton.dart';
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
      duration: const Duration(milliseconds: 1500), // Increase duration to make animation slower
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 53, 147, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Unloque',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 30,
                      color: Color(0xFF1D1D1D),
                    ),
                  ),
                  SizedBox(height: 40),
                  MyButton(
                    onTap: _toggleSignIn,
                    label: 'Sign In',
                    isLoading: false,
                    isOutlined: true,
                    isEnabled: true,
                  ),
                  SizedBox(height: 20),
                  MyButton(
                    onTap: _toggleSignUp,
                    label: 'Sign Up',
                    isLoading: false,
                    isOutlined: true,
                    isEnabled: true,
                  ),
                ],
              ),
              if (showSignIn || showSignUp)
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (showSignIn) {
                        _toggleSignIn();
                      } else if (showSignUp) {
                        _toggleSignUp();
                      }
                    },
                  ),
                ),
              if (showSignIn || showSignUp)
                SlideTransition(
                  position: _offsetAnimation,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 50) {
                        if (showSignIn) {
                          _toggleSignIn();
                        } else if (showSignUp) {
                          _toggleSignUp();
                        }
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
                                _toggleSignIn();
                              },
                              child: SignInCard(onBack: _toggleSignIn),
                            ),
                          if (showSignUp)
                            Dismissible(
                              key: Key('signUpCard'),
                              direction: DismissDirection.down,
                              onDismissed: (direction) {
                                _toggleSignUp();
                              },
                              child: SignUpCard(onBack: _toggleSignUp),
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
    );
  }
}
