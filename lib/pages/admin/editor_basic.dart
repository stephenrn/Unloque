import 'package:flutter/material.dart';

class BasicEditorTab extends StatefulWidget {
  final String programName;
  final String? selectedCategory;
  final String deadline;
  final Color selectedColor;
  final String organizationName;
  final String? organizationLogoUrl;

  final Function(String) updateName;
  final Function(String?) updateCategory;
  final Function(String) updateDeadline;
  final Function(Color) updateColor;
  final Function() showColorPickerDialog;
  final Function(BuildContext) selectDate;

  const BasicEditorTab({
    Key? key,
    required this.programName,
    required this.selectedCategory,
    required this.deadline,
    required this.selectedColor,
    required this.organizationName,
    required this.organizationLogoUrl,
    required this.updateName,
    required this.updateCategory,
    required this.updateDeadline,
    required this.updateColor,
    required this.showColorPickerDialog,
    required this.selectDate,
  }) : super(key: key);

  @override
  State<BasicEditorTab> createState() => _BasicEditorTabState();
}

class _BasicEditorTabState extends State<BasicEditorTab> {
  late TextEditingController _nameController;
  late TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.programName);
    _deadlineController = TextEditingController(text: widget.deadline);

    _nameController.addListener(() {
      widget.updateName(_nameController.text);
    });

    _deadlineController.addListener(() {
      widget.updateDeadline(_deadlineController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program header card
          Container(
            decoration: BoxDecoration(
              color: widget.selectedColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with program info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Organization logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.organizationLogoUrl != null &&
                                widget.organizationLogoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.organizationLogoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      color: Colors.grey[800],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.business,
                                color: Colors.grey[800],
                              ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isEmpty
                                  ? 'Program Name'
                                  : _nameController.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.organizationName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom section with due date
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
                          SizedBox(width: 8),
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
                                  text: _deadlineController.text.isEmpty
                                      ? 'No deadline set'
                                      : _deadlineController.text,
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
                      Text(
                        widget.selectedCategory ?? 'No category',
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

          SizedBox(height: 24),

          // Program details form
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!, width: 0.5),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program name field
                Text(
                  'Program Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter program name',
                  ),
                ),
                SizedBox(height: 16),

                // Category dropdown
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: widget.selectedCategory,
                  items:
                      ['Educational', 'Social', 'Healthcare'].map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    widget.updateCategory(value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Deadline field
                Text(
                  'Deadline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _deadlineController,
                  readOnly: true,
                  onTap: () => widget.selectDate(context),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select deadline',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                SizedBox(height: 16),

                // Color picker
                Text(
                  'Program Color',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: widget.showColorPickerDialog,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: Text(
                        'Tap to change color',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
