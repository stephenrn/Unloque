import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/pages/admin/program_beneficiaries_editor.dart';
// Add import for the new page
import 'package:unloque/pages/admin/program_details_form_page.dart';
// Add import for ApplicationManagerPage at the top
import 'package:unloque/pages/admin/application_manager_page.dart';
// Add these imports:
import 'package:unloque/constants/category_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/services.dart';
// Update the import for web_viewer.dart - add this at the top with other imports
import '../../utils/web_viewer.dart';

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

    // List of available categories - make sure this matches how data is stored in Firebase
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

                  // Make the program card pressable to navigate to ApplicationManagerPage
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicationManagerPage(
                              organizationId: organizationId,
                              programId: data['id'],
                              programName: data['name'] ?? '',
                              categoryColor: programColor,
                            ),
                          ),
                        );
                      },
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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

class _NewsTab extends StatefulWidget {
  final String organizationId;

  const _NewsTab({required this.organizationId});

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
  Future<void> _showAddNewsDialog(BuildContext context,
      {DocumentSnapshot? doc, Map<String, dynamic>? initialData}) async {
    final formKey = GlobalKey<FormState>();
    final headlineController =
        TextEditingController(text: initialData?['headline'] ?? '');
    String? selectedCategory = initialData?['category'];
    final dateController =
        TextEditingController(text: initialData?['date'] ?? '');
    final imageUrlController =
        TextEditingController(text: initialData?['imageUrl'] ?? '');
    final newsUrlController =
        TextEditingController(text: initialData?['newsUrl'] ?? '');

    final categories = ['Social', 'Healthcare', 'Education'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? 'Add News Article' : 'Edit News Article'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: headlineController,
                      decoration: InputDecoration(
                        labelText: 'Headline',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter headline'
                          : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) => selectedCategory = val,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select category'
                          : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          dateController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Select date' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter image URL'
                          : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: newsUrlController,
                      decoration: InputDecoration(
                        labelText: 'News URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter news URL'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final data = {
                      'headline': headlineController.text.trim(),
                      'category': selectedCategory,
                      'date': dateController.text.trim(),
                      'imageUrl': imageUrlController.text.trim(),
                      'newsUrl': newsUrlController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    if (doc == null) {
                      await FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(widget.organizationId)
                          .collection('news')
                          .add(data);
                    } else {
                      await doc.reference.update(data);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(doc == null
                              ? 'News article added!'
                              : 'News article updated!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(doc == null ? 'Add News' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to delete a news article
  void _deleteNewsArticle(DocumentSnapshot doc) {
    final headline =
        (doc.data() as Map<String, dynamic>)['headline'] ?? 'this article';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete News Article'),
        content: Text('Are you sure you want to delete "$headline"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await doc.reference.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('News article deleted!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting article: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // First, get the organization data to pass to news cards
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .get(),
      builder: (context, orgSnapshot) {
        String organizationName = "Organization";
        String? logoUrl;

        if (orgSnapshot.hasData && orgSnapshot.data != null) {
          final orgData = orgSnapshot.data!.data() as Map<String, dynamic>?;
          organizationName = orgData?['name'] as String? ?? "Organization";
          logoUrl = orgData?['logoUrl'] as String?;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddNewsDialog(context),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(widget.organizationId)
                .collection('news')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Fixed null check - Added proper null data handling
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.docs.isEmpty) {
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

              // Only proceed if we have data
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        _NewsSliderStyleCard(
                          headline: data['headline'] ?? '',
                          category: data['category'] ?? '',
                          date: data['date'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          newsUrl: data['newsUrl'] ?? '',
                          organizationName: organizationName,
                          logoUrl: logoUrl ?? '',
                          onTapEdit: () => _showAddNewsDialog(context,
                              doc: doc, initialData: data),
                          onTapDelete: () => _deleteNewsArticle(doc),
                        ),
                        // ...existing code...
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// News card styled like the slider, but for list view
class _NewsSliderStyleCard extends StatelessWidget {
  final String headline;
  final String category;
  final String date;
  final String imageUrl;
  final String newsUrl;
  final String organizationName;
  final String logoUrl;
  final VoidCallback? onTapEdit;
  final VoidCallback? onTapDelete; // Add this property

  const _NewsSliderStyleCard({
    Key? key,
    required this.headline,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.newsUrl,
    required this.organizationName,
    this.logoUrl = '',
    this.onTapEdit,
    this.onTapDelete, // Add this parameter
  }) : super(key: key);

  // Updated colors to even lighter variants
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'healthcare':
        return Colors.red[300]!; // Even lighter red
      case 'education':
        return Colors.blue[300]!; // Even lighter blue
      case 'social':
        return Colors.green[300]!; // Even lighter green
      default:
        return Colors.grey[300]!; // Even lighter grey
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace with a complete implementation
    return GestureDetector(
      onTap: () async {
        if (newsUrl.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => NewsViewerDialog(
              headline: headline,
              category: category,
              date: date,
              imageUrl: imageUrl,
              newsUrl: newsUrl,
              organizationName: organizationName,
              organizationLogo: logoUrl,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No news content available.')),
          );
        }
      },
      child: Container(
        height: 180, // Fixed height to prevent layout issues
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[300]);
                      },
                    )
                  : Container(color: Colors.grey[300]),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    // Source and Date
                    Row(
                      children: [
                        Container(
                          width: 24, // Bigger container
                          height: 24, // Bigger container
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                5), // Rounded box instead of circle
                          ),
                          child: logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      5), // Match container's border radius
                                  child: Image.network(
                                    logoUrl,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business,
                                        size: 16,
                                        color: Colors.grey[600],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                        ),
                        SizedBox(width: 4),
                        // Handle long organization names with Expanded and ellipsis
                        Expanded(
                          child: Text(
                            organizationName,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Ensure date always shows by using a non-flexible container
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Headline - Add this section that was missing
                    Text(
                      headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Admin action buttons - Add these to the top right
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        color: Colors.blue[800],
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                        onPressed: onTapEdit,
                        tooltip: 'Edit',
                      ),
                    ),
                    SizedBox(width: 8),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete, size: 20),
                        color: Colors.red[800],
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                        onPressed: onTapDelete,
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapDataTab extends StatelessWidget {
  final String organizationId;

  const _MapDataTab({required this.organizationId});

  // Add this method to show program selection dialog
  void _showProgramSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Program'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(organizationId)
                .collection('programs')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                      'No programs available. Please create a program first.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final program =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final colorValue = program['color'] as int?;
                  final programColor = colorValue != null
                      ? Color(colorValue)
                      : Colors.blue[100]!;

                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: programColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    title: Text(program['name'] ?? 'Unnamed Program'),
                    subtitle: Text(program['category'] ?? 'No Category'),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramBeneficiariesEditor(
                            programId: program['id'],
                            programName: program['name'] ?? 'Unnamed Program',
                            organizationId: organizationId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Add method to delete map data
  void _deleteMapData(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Map Data'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('mapdata')
                    .doc(docId)
                    .delete();

                Navigator.pop(context); // Close dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Map data deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context); // Close dialog on error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting map data: $e')),
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
        onPressed: () => _showProgramSelectionDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mapdata')
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

              // Different card for beneficiaries type
              if (data['type'] == 'beneficiaries') {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.people, color: Colors.green),
                    title: Text(data['title'] ?? 'Program Beneficiaries'),
                    subtitle: Text(
                      'Total: ${data['Total Beneficiaries']?.toString() ?? 'Not specified'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProgramBeneficiariesEditor(
                                  programId: data['programId'],
                                  programName: data['programName'] ?? 'Program',
                                  organizationId: organizationId,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteMapData(context, doc.id,
                                data['title'] ?? 'Program Beneficiaries');
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to edit the beneficiaries
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramBeneficiariesEditor(
                            programId: data['programId'],
                            programName: data['programName'] ?? 'Program',
                            organizationId: organizationId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              // Original card for other map data types
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
                      _deleteMapData(context, doc.id,
                          data['locationName'] ?? 'Unnamed Location');
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

// Add this new class for a better news viewing experience
class NewsViewerDialog extends StatelessWidget {
  final String headline;
  final String category;
  final String date;
  final String imageUrl;
  final String newsUrl;
  final String organizationName;
  final String organizationLogo; // Add logo parameter

  const NewsViewerDialog({
    Key? key,
    required this.headline,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.newsUrl,
    required this.organizationName,
    this.organizationLogo = '', // Default to empty string
  }) : super(key: key);

  // Updated colors to even lighter variants
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'healthcare':
        return Colors.red[300]!; // Even lighter red
      case 'education':
        return Colors.blue[300]!; // Even lighter blue
      case 'social':
        return Colors.green[300]!; // Even lighter green
      default:
        return Colors.grey[300]!; // Even lighter grey
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use actual logo if available with updated styling
    Widget orgIcon = Container(
      width: 24, // Bigger container
      height: 24, // Bigger container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5), // Rounded box instead of circle
      ),
      child: organizationLogo.isNotEmpty
          ? ClipRRect(
              borderRadius:
                  BorderRadius.circular(5), // Match container's border radius
              child: Image.network(
                organizationLogo,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.business,
                      size: 16, color: Colors.grey[600]);
                },
              ),
            )
          : Icon(Icons.business, size: 16, color: Colors.grey[600]),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge with custom color
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // News headline
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Organization and date with better support for long organization names
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    orgIcon, // Use the custom icon widget
                    SizedBox(width: 4),
                    // Wrap the organization name in an Expanded to handle long text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organizationName.isNotEmpty
                                ? organizationName
                                : 'Organization',
                            style: TextStyle(color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          // Move date below for cleaner layout when org name is long
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey[700]),
                              SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24),
                // Grey button without org icon
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.open_in_browser),
                    label: Text("View Full Article"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SafeWebViewer(
                            url: newsUrl,
                            title: 'News',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 16),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('CLOSE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
