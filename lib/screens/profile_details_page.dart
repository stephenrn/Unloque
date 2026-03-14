import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unloque/services/auth/auth_user_service.dart';
import 'package:unloque/services/users/user_profile_image_service.dart';
import 'package:unloque/services/users/user_profile_service.dart';
import 'package:unloque/services/auth/auth_session_service.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final User? _user = AuthSessionService.currentUser();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploading = false;
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_user != null) {
        final userData = await UserProfileService.getUserDoc(_user.uid);

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;

          setState(() {
            _usernameController.text = data['username'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            _currentPhotoUrl = data['photoUrl'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: Colors.blue[700]),
              ),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_camera, color: Colors.green[700]),
              ),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_currentPhotoUrl != null)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red[700]),
                ),
                title: Text('Remove Current Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _currentPhotoUrl = null;
                  });
                },
              ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentPhotoUrl;

    setState(() {
      _isUploading = true;
    });

    try {
      return await UserProfileImageService.uploadProfileImage(
        uid: _user!.uid,
        imageFile: _imageFile!,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_user != null) {
        // Upload image if there is one selected
        String? photoUrl = await _uploadImage();

        // Update user profile data
        await UserProfileService.updateProfile(
          uid: _user.uid,
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          photoUrl: photoUrl,
        );

        await AuthUserService.updateDisplayNameAndPhotoUrl(
          user: _user,
          displayName: _usernameController.text.trim(),
          photoUrl: photoUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );

        setState(() {
          _isEditing = false;
          _currentPhotoUrl = photoUrl;
          _imageFile = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Text(
          'Profile Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Section with colored background
                    Container(
                      color: Colors.grey[850],
                      padding: EdgeInsets.only(bottom: 30),
                      child: _buildUserAvatar(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Personal Information'),
                            SizedBox(height: 15),
                            _buildTextField(
                              label: 'Username',
                              controller: _usernameController,
                              enabled: _isEditing,
                              prefixIcon: Icons.person,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            _buildTextField(
                              label: 'Email',
                              initialValue: _user?.email ?? 'No email provided',
                              enabled: false,
                              prefixIcon: Icons.email_outlined,
                            ),
                            SizedBox(height: 20),
                            _buildTextField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              enabled: _isEditing,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 30),
                            _buildSectionTitle('Address'),
                            SizedBox(height: 15),
                            _buildTextField(
                              label: 'Home Address',
                              controller: _addressController,
                              enabled: _isEditing,
                              prefixIcon: Icons.home_outlined,
                              maxLines: 3,
                            ),
                            SizedBox(height: 30),
                            if (_isEditing) _buildUpdateProfileButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 2,
                  blurRadius: 10,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 75,
              backgroundColor: Color(0xFF003366),
              child: CircleAvatar(
                radius: 72,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_currentPhotoUrl != null
                        ? NetworkImage(_currentPhotoUrl!)
                        : null) as ImageProvider<Object>?,
                child: (_imageFile == null && _currentPhotoUrl == null)
                    ? Icon(Icons.person_outline, size: 80, color: Colors.white)
                    : null,
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 15,
              right: 5,
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey[600],
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 22, color: Colors.grey[600])
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUpdateProfileButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: Text(
          'Update Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
