import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unloque/pages/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/pages/terms_and_conditions_page.dart';
import 'package:unloque/pages/faqs_page.dart';
import 'package:unloque/pages/profile_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage()),
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      await user?.delete();
      await signOut(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please log in again before trying this request')),
      );
    }
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 20, bottom: 16),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 4),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            )
          ],
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final username = snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!['username']
                : 'User';

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        spreadRadius: 2,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFF003366),
                    child: CircleAvatar(
                      radius: 53,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person_outline,
                              size: 55, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'User ID: ${user?.uid?.substring(0, 8) ?? ''}...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildNavigationArrow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_outward_rounded,
        color: Colors.grey[200],
        size: 16,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[300]),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 10),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity(vertical: -1),
        leading: Icon(icon, size: 22, color: Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        trailing: _buildNavigationArrow(),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics:
                AlwaysScrollableScrollPhysics(), // Make it always scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header with background
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 65, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                Center(child: _buildProfileCard()),
                _buildSectionTitle('General'),
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Profile Details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailsPage(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsAndConditionsPage(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'FAQs',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaqsPage(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSectionTitle('Account'),
                _buildListTile(
                  icon: Icons.exit_to_app_outlined,
                  title: 'Log Out',
                  onTap: () => signOut(context),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  onTap: () => deleteAccount(context),
                ),
                _buildDivider(),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
