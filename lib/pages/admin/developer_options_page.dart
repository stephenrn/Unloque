import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unloque/pages/admin/population_editor_page.dart';
import 'organization_page.dart';

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key});

  @override
  DeveloperOptionsPageState createState() => DeveloperOptionsPageState();
}

class DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a unique ID for the organization
      final organizationId =
          FirebaseFirestore.instance.collection('organizations').doc().id;

      // Prepare organization data
      final organizationData = {
        'id': organizationId,
        'name': _nameController.text.trim(),
        'logoUrl': _logoUrlController.text.trim(),
        'website': _websiteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firebase organizations collection (not under users)
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .set(organizationData);

      // Clear form and show success message
      _nameController.clear();
      _logoUrlController.clear();
      _websiteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating organization: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recursivelyDeleteFolder(Reference storageRef) async {
    try {
      // First list everything in this folder
      final ListResult result = await storageRef.listAll();

      // Delete all nested files
      for (var item in result.items) {
        try {
          await item.delete();
          print('Deleted file: ${item.fullPath}');
        } catch (e) {
          print('Error deleting file ${item.fullPath}: $e');
        }
      }

      // Recursively delete subfolders
      for (var prefix in result.prefixes) {
        await _recursivelyDeleteFolder(prefix);
      }

      // Note: Firebase Storage doesn't have a direct way to delete empty folders
      // as folders are just prefixes and disappear when all items are deleted
    } catch (e) {
      print('Error in recursive deletion: $e');
    }
  }

  Future<void> _deleteOrganizationData(String organizationId) async {
    try {
      // 1. First, collect all the Firebase Storage refs to delete later
      final List<Reference> storageRefsToDelete = [];

      // 2. Get all programs
      final programsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .get();

      // Process each program
      for (final programDoc in programsSnapshot.docs) {
        final programId = programDoc.id;

        try {
          // Store storage references to delete later
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('organizations/$organizationId/programs/$programId');

          // Add to the list of references to delete
          storageRefsToDelete.add(storageRef);

          // Delete the program document from Firestore
          await programDoc.reference.delete();
          print('Deleted program document: $programId');
        } catch (e) {
          print('Error processing program $programId: $e');
        }
      }

      // 3. Delete the organization document itself
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .delete();
      print('Deleted organization document: $organizationId');

      // 4. After Firestore operations are complete, delete all storage references
      for (var storageRef in storageRefsToDelete) {
        try {
          // Use recursive deletion for each program folder
          await _recursivelyDeleteFolder(storageRef);
        } catch (e) {
          print('Error deleting program storage: ${storageRef.fullPath}: $e');
        }
      }

      // 5. Finally, delete the main organization folder recursively
      try {
        final orgStorageRef = FirebaseStorage.instance
            .ref()
            .child('organizations/$organizationId');

        print(
            'Attempting to delete organization folder: ${orgStorageRef.fullPath}');
        await _recursivelyDeleteFolder(orgStorageRef);
        print('Successfully completed organization storage deletion process');
      } catch (e) {
        print('Error deleting organization-level storage: $e');
      }
    } catch (e) {
      print('Error in deletion process: $e');
      throw e; // Rethrow to be caught by the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        toolbarHeight: 140,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, true),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.grey[900],
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Developer Options',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[200],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28), // For visual balance with the back button
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin section header
              Container(
                margin: EdgeInsets.only(top: 8, bottom: 24),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.admin_panel_settings,
                          size: 32, color: Colors.blue[800]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrative Panel',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create and manage organizations',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quezon Population Editor button - updated design
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PopulationEditorPage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.people_alt_rounded,
                              size: 28, color: Colors.green[800]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Quezon Population',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update population data for municipalities',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.grey[800],
                            size: 20,
                          ),
                          padding: EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Organization creation form section header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 32, 0, 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_business,
                        size: 20,
                        color: Colors.purple[800],
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Create New Organization',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              // Updated form card with better styling
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Organization Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.business),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an organization name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _logoUrlController,
                          decoration: InputDecoration(
                            labelText: 'Logo URL',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.image),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a logo URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            labelText: 'Website',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.language),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a website URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createOrganization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text("Creating organization...")
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add),
                                      SizedBox(width: 8),
                                      Text(
                                        'CREATE ORGANIZATION',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
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
              ),

              // Organization list header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 32, 0, 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business_center,
                        size: 20,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Existing Organizations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              // Organization list with improved cards
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('organizations')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(24),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .business_center_outlined, // Changed from Icons.business_off which doesn't exist
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No organizations found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrganizationPage(
                                  organization: data,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: data['logoUrl'] != null &&
                                            data['logoUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            data['logoUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.business,
                                                size: 30,
                                                color: Colors.grey[600],
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.business,
                                            size: 30,
                                            color: Colors.grey[600],
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Organization',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      if (data['website'] != null &&
                                          data['website'].toString().isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.language,
                                              size: 14,
                                              color: Colors.blue[700],
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                data['website'],
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[700],
                                    ),
                                    onPressed: () {
                                      // Show the existing delete dialog
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red[700],
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete Organization'),
                                            ],
                                          ),
                                          content: Text(
                                              'This will permanently delete "${data['name'] ?? 'this organization'}" and ALL associated data:\n\n'
                                              '• All programs\n'
                                              '• All uploaded files\n'
                                              '• All configuration data\n\n'
                                              'This action cannot be undone. Are you sure?'),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogContext),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  final String orgId = doc.id;
                                                  Navigator.pop(dialogContext);

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Deleting organization and all data...'),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ),
                                                  );

                                                  await _deleteOrganizationData(
                                                      orgId);

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Organization deleted successfully'),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error deleting organization: $e'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text(
                                                  'Delete Everything'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Delete Organization',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
