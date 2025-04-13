import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add import for the new page
import 'package:unloque/pages/admin/program_details_form_page.dart';

class OrganizationPage extends StatefulWidget {
  final Map<String, dynamic> organization;

  const OrganizationPage({
    Key? key,
    required this.organization,
  }) : super(key: key);

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizationName =
        widget.organization['name'] ?? 'Organization Details';
    final organizationLogo = widget.organization['logoUrl'];
    final organizationWebsite = widget.organization['website'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          organizationName,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Programs'),
            Tab(text: 'News'),
            Tab(text: 'Map Data'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Organization header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: organizationLogo != null &&
                          organizationLogo.toString().isNotEmpty
                      ? Image.network(
                          organizationLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.business, size: 40);
                          },
                        )
                      : const Icon(Icons.business, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organizationName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (organizationWebsite.isNotEmpty)
                        Text(
                          organizationWebsite,
                          style: TextStyle(
                            color: Colors.blue[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Programs Tab
                _ProgramsTab(organizationId: widget.organization['id']),

                // News Tab
                _NewsTab(organizationId: widget.organization['id']),

                // Map Data Tab
                _MapDataTab(organizationId: widget.organization['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  final String organizationId;

  const _ProgramsTab({required this.organizationId});

  void _showAddProgramDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String? selectedCategory;
    final deadlineController = TextEditingController();
    DateTime? selectedDeadline;
    Color selectedColor =
        Colors.blue[100]!; // Update initial color to lighter blue

    // List of predefined colors for selection - changed to lighter variants
    final colors = [
      Colors.blue[100]!,
      Colors.red[100]!,
      Colors.green[100]!,
      Colors.orange[100]!,
      Colors.purple[100]!,
      Colors.teal[100]!,
      Colors.pink[100]!,
      Colors.amber[100]!,
      Colors.indigo[100]!,
      Colors.cyan[100]!,
    ];

    // List of available categories
    final categories = ['Educational', 'Social', 'Healthcare'];

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Program'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Program Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a program name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        selectedCategory = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: deadlineController,
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          selectedDeadline = pickedDate;
                          deadlineController.text =
                              pickedDate.toIso8601String().split('T')[0];
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a deadline';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      // Generate a document ID for the program
                      final programDocRef = FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('programs')
                          .doc(); // This generates a unique ID

                      final programId = programDocRef.id;

                      // Create program data
                      final programData = {
                        'id': programId, // Include the ID in the document
                        'name': nameController.text.trim(),
                        'category': selectedCategory,
                        'deadline': deadlineController.text,
                        'color': selectedColor.value,
                        'organizationId': organizationId,
                        'programStatus':
                            'Closed', // Set default status to Closed
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      // Save to Firebase using the generated ID
                      await programDocRef.set(programData);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Program added successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding program: $e')),
                      );
                    }
                  }
                },
                child: const Text('Add Program'),
              ),
            ],
          );
        });
      },
    );
  }

  // Add this method to handle program deletion
  Future<void> _deleteProgram(
      BuildContext context, String programId, String programName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text(
            'Are you sure you want to delete "$programName"? This will also remove it from all users\' applications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the program from Firestore
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('programs')
                    .doc(programId)
                    .delete();

                // Cascade delete from users-application
                final usersSnapshot =
                    await FirebaseFirestore.instance.collection('users').get();
                for (final userDoc in usersSnapshot.docs) {
                  final userApplicationsRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userDoc.id)
                      .collection('users-application');

                  final userApplicationsSnapshot = await userApplicationsRef
                      .where('id', isEqualTo: programId)
                      .get();
                  for (final applicationDoc in userApplicationsSnapshot.docs) {
                    await applicationDoc.reference.delete();
                  }
                }

                Navigator.pop(context); // Close dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Program deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context); // Close dialog even on error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting program: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProgramDialog(context),
        backgroundColor: Colors.grey[300], // Changed to light grey
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Update the stream to read from the organization's programs subcollection
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .collection('programs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No programs found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a program',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            // Set alignment to start from the left
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final colorValue = data['color'] as int?;
              final programColor =
                  colorValue != null ? Color(colorValue) : Colors.blue[200]!;

              // Fetch organization logo
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .get(),
                builder: (context, orgSnapshot) {
                  String? logoUrl;
                  String orgName = "Organization";

                  if (orgSnapshot.hasData && orgSnapshot.data != null) {
                    final orgData =
                        orgSnapshot.data!.data() as Map<String, dynamic>?;
                    logoUrl = orgData?['logoUrl'] as String?;
                    orgName = orgData?['name'] as String? ?? "Organization";
                  }

                  // Removed GestureDetector and its onTap property
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: programColor,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey[800]!, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section with program name and action buttons
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Replace CircleAvatar with a rounded rectangle Container
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(
                                        8), // Slightly rounded corners
                                  ),
                                  child: logoUrl != null && logoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              8), // Match container's border radius
                                          child: Image.network(
                                            logoUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.folder_special,
                                                color: Colors.grey[800],
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.folder_special,
                                          color: Colors.grey[800],
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Program',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        orgName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Add edit button
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    // Navigate to program details form page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProgramDetailsFormPage(
                                          program: data,
                                          organizationId: organizationId,
                                          organizationName: orgName,
                                          organizationLogoUrl: logoUrl,
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Edit Program',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    _deleteProgram(context, doc.id,
                                        data['name'] ?? 'Unnamed Program');
                                  },
                                  tooltip: 'Delete Program',
                                ),
                              ],
                            ),
                          ),
                          // Bottom section with deadline and category
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: Colors.grey[800], size: 16),
                                    const SizedBox(width: 8),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Due: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          TextSpan(
                                            text: data['deadline'] ??
                                                'No Deadline',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Status indicator now inline with due date
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (data['programStatus'] ??
                                                    "Closed") ==
                                                "Open"
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (data['programStatus'] ??
                                                      "Closed") ==
                                                  "Open"
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        data['programStatus'] ?? "Closed",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (data['programStatus'] ??
                                                      "Closed") ==
                                                  "Open"
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  data['category'] ?? 'No Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  final String organizationId;

  const _NewsTab({required this.organizationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add news functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Add news functionality not implemented yet')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .where('organizationId', isEqualTo: organizationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No news articles found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a news article',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: data['imageUrl'] != null &&
                          data['imageUrl'].toString().isNotEmpty
                      ? SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image);
                            },
                          ),
                        )
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.image),
                        ),
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Text(data['date'] != null
                      ? data['date'].toString().split(' ')[0]
                      : 'No date'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // TODO: Implement delete news functionality
                    },
                  ),
                  onTap: () {
                    // TODO: Implement view/edit news functionality
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MapDataTab extends StatelessWidget {
  final String organizationId;

  const _MapDataTab({required this.organizationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add map data functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Add map data functionality not implemented yet')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mapData')
            .where('organizationId', isEqualTo: organizationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No map data found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add map data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(data['locationName'] ?? 'Unnamed Location'),
                  subtitle: Text(
                    'Lat: ${data['latitude']?.toStringAsFixed(4) ?? 'N/A'}, '
                    'Lng: ${data['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // TODO: Implement delete map data functionality
                    },
                  ),
                  onTap: () {
                    // TODO: Implement view/edit map data functionality
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
