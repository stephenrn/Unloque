import 'package:flutter/material.dart';
import 'package:unloque/widgets/username_dialog.dart';
import 'package:unloque/services/auth/google_sign_in_service.dart';
import 'package:unloque/services/users/user_profile_service.dart';
import '../screens/home_page.dart';

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  bool _isLoading = false;

  Future<void> handleGoogleSignIn() async {
    print("Google Sign In button pressed");
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      print("Calling GoogleSignInService.signInWithGoogle()");
      final userCredential = await GoogleSignInService.signInWithGoogle();
      print("Sign in result: ${userCredential?.user?.email ?? 'null'}");

      if (userCredential == null) return;

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google sign-in returned no user');
      }

      if (mounted) {
        final exists = await UserProfileService.userExists(user.uid);
        if (!exists && mounted) {
          // Show username dialog for new users
          final username = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => UsernameDialog(),
          );

          if (username != null && mounted) {
            // Create user profile with custom username and userId
            final userId = user.uid;
            print("Creating user profile with ID: $userId"); // Debug log

            try {
              await UserProfileService.createUserProfile(
                uid: userId,
                email: user.email ?? '',
                username: username,
                photoUrl: user.photoURL,
              );
              print("User profile created successfully"); // Debug log
            } catch (e) {
              print("Error creating user profile: ${e.toString()}");

              // Show error message to user
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Error creating user profile: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          }
        } else if (mounted) {
          Navigator.pushReplacement(
            context,
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : handleGoogleSignIn,
      child: Center(
        child: Container(
          width: 300,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.grey[800]!),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
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
