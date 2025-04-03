import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unloque/pages/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[600]!,
              offset: Offset(0, 1),
              blurRadius: 1.0,
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
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFF003366),
                    child: CircleAvatar(
                      radius: 45,  // Changed from 43 to match parent radius
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person_outline,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
      padding: EdgeInsets.only(left: 10),  // Add left padding for indentation
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity(vertical: -1),
        leading: Icon(icon, size: 22),
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
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 25, top: 48),  // increased left padding from 16 to 24
                  child: Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Center(child: _buildProfileCard()),
                _buildSectionTitle('General'),
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Profile Details',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'FAQs',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSectionTitle('Account'),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {},
                ),
                _buildDivider(),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
