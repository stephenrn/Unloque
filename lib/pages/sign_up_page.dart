import 'package:flutter/material.dart';
import 'package:unloque/components/my_textfield.dart';
import 'package:unloque/components/continueButton.dart';
import 'package:unloque/components/google_button.dart';
import 'home_page.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  //text editing controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                //Sign up txt
                //Create Account
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Up',
                        style: TextStyle(
                            fontSize: 55,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold),
                      ),
                      Text('Create an Account!',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[800])),
                      Row(
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[800]),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 50),
                //Username txtfield
                MyTextfield(
                  controller: usernameController,
                  label: 'Username',
                  hint: 'Enter your username',
                  obscureText: false,
                ),

                const SizedBox(height: 17),
                //Email txtfield
                MyTextfield(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  obscureText: false,
                ),

                const SizedBox(height: 17),
                //Password txtfield
                MyTextfield(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                ),

                const SizedBox(height: 17),
                //Confirm Password txtfield
                MyTextfield(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  obscureText: true,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                //Continue button
                MyButton(
                  route: HomePage(),
                  label: 'Continue',
                ),
                const SizedBox(height: 10),
                //Or line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or', style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                //Google button
                GoogleButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
