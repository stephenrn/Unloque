import 'package:flutter/material.dart';
import 'package:unloque/pages/application_details_page.dart';

class ApplicationFormPage extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationFormPage({super.key, required this.application});

  @override
  _ApplicationFormPageState createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  String? selectedOption; // For multiple-choice selection
  Map<String, bool> checkboxValues = {}; // For checkbox selections
  Map<String, DateTime?> selectedDates = {}; // For date selections

  @override
  void initState() {
    super.initState();
    final forms = widget.application['details']['forms'] ?? [];
    for (var form in forms) {
      if (form['type'] == 'checkbox') {
        for (var option in form['options']) {
          checkboxValues[option] = false; // Initialize all checkboxes as false
        }
      } else if (form['type'] == 'date') {
        selectedDates[form['label']] = null; // Initialize dates as null
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDates[label]) {
      setState(() {
        selectedDates[label] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final forms = widget.application['details']['forms'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Application Form',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.application['categoryColor'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.application['programName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.application['organizationName'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Forms Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: forms.map<Widget>((form) {
                        switch (form['type']) {
                          case 'short_answer':
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: form['placeholder'],
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            );
                          case 'paragraph':
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: form['placeholder'],
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            );
                          case 'multiple_choice':
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...form['options'].map<Widget>((option) {
                                  return RadioListTile(
                                    value: option,
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedOption = value as String?;
                                      });
                                    },
                                    title: Text(option),
                                  );
                                }).toList(),
                                SizedBox(height: 16),
                              ],
                            );
                          case 'checkbox':
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...form['options'].map<Widget>((option) {
                                  return CheckboxListTile(
                                    value: checkboxValues[option],
                                    onChanged: (value) {
                                      setState(() {
                                        checkboxValues[option] = value!;
                                      });
                                    },
                                    title: Text(option),
                                  );
                                }).toList(),
                                SizedBox(height: 16),
                              ],
                            );
                          case 'date':
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: selectedDates[form['label']] ==
                                            null
                                        ? 'Select a date'
                                        : '${selectedDates[form['label']]!.toLocal()}'
                                            .split(' ')[0],
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, form['label']),
                                ),
                                SizedBox(height: 16),
                              ],
                            );
                          case 'attachment':
                            return SizedBox.shrink();
                          default:
                            return SizedBox.shrink();
                        }
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Handle form submission
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: darkenColor(widget.application['categoryColor']!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Submit Application',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
