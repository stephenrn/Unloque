import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add Firebase Storage import
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

  // Add a new recursive deletion function
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

          try {
            // Get all storage references but don't delete yet
            final ListResult result = await storageRef.listAll();

            // Add prefixes to the list of refs to delete
            for (var prefix in result.prefixes) {
              // Get all items in the subdirectory
              final subItems = await prefix.listAll();
              for (var item in subItems.items) {
                storageRefsToDelete.add(item);
              }
            }

            // Add direct files to the list of refs to delete
            storageRefsToDelete.addAll(result.items);
          } catch (e) {
            print('Error listing storage files for program $programId: $e');
          }

          // Delete the program document from Firestore
          await programDoc.reference.delete();
        } catch (e) {
          print('Error processing program $programId: $e');
        }
      }

      // 3. Delete the organization document itself
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .delete();

      // 4. After Firestore operations are complete, delete all the storage references
      // This way, even if the widget context is deactivated, we're still using
      // references we captured earlier
      for (var storageRef in storageRefsToDelete) {
        try {
          await storageRef.delete();
          print('Deleted storage file: ${storageRef.fullPath}');
        } catch (e) {
          print('Error deleting storage file ${storageRef.fullPath}: $e');
        }
      }

      // 5. Finally try to delete any organization-level storage files
      try {
        final orgStorageRef = FirebaseStorage.instance
            .ref()
            .child('organizations/$organizationId');

        try {
          // Delete the entire organization folder
          final result = await orgStorageRef.listAll();
          for (var item in result.items) {
            try {
              await item.delete();
            } catch (e) {
              print('Error deleting organization file ${item.fullPath}: $e');
            }
          }
        } catch (e) {
          print('Error listing organization-level storage files: $e');
        }
      } catch (e) {
        print('Error accessing organization storage: $e');
      }
    } catch (e) {
      print('Error in deletion process: $e');
      throw e; // Rethrow to be caught by the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Developer Options',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin section header
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 32, color: Colors.blue[700]),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrative Panel',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Create and manage organizations',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Organization creation form
            const Text(
              'Create New Organization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Logo URL',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          border: OutlineInputBorder(),
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
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Organization'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Organization list
            const Text(
              'Existing Organizations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('organizations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No organizations found'),
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
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[200],
                          child: data['logoUrl'] != null &&
                                  data['logoUrl'].toString().isNotEmpty
                              ? Image.network(
                                  data['logoUrl'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.business);
                                  },
                                )
                              : const Icon(Icons.business),
                        ),
                        title: Text(data['name'] ?? 'Unnamed Organization'),
                        subtitle: Text(data['website'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Replace the existing dialog with enhanced version that safely handles deletion
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete Organization'),
                                content: Text(
                                    'This will permanently delete "${data['name'] ?? 'this organization'}" and ALL associated data:\n\n'
                                    '• All programs\n'
                                    '• All uploaded files\n'
                                    '• All configuration data\n\n'
                                    'This action cannot be undone. Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        // Capture organizationId before closing dialog
                                        final String orgId = doc.id;

                                        // Close dialog first to avoid context issues
                                        Navigator.pop(dialogContext);

                                        // Show loading indicator
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Deleting organization and all data...'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        // Call the deletion method with the captured ID
                                        await _deleteOrganizationData(orgId);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Organization deleted successfully with all associated data'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error deleting organization: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Delete Everything',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          // Navigate to the organization details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrganizationPage(
                                organization: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
