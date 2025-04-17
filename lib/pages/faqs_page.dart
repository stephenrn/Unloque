import 'package:flutter/material.dart';

class FaqsPage extends StatefulWidget {
  const FaqsPage({super.key});

  @override
  State<FaqsPage> createState() => _FaqsPageState();
}

class _FaqsPageState extends State<FaqsPage> {
  // List to track which FAQs are expanded
  final List<bool> _expandedList = [
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _buildFaqItem(
                  index: 0,
                  question: 'What is Unloque?',
                  answer:
                      'It\'s a free third-party app that lets you apply for government aid programs like 4Ps, DOST '
                      'scholarships, and faster, easier, and with better transparency. We\'re here to make things '
                      'more convenient for you, not to replace government systems.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 1,
                  question: 'Who can use Unloque?',
                  answer: 'Any Filipino citizen can use our services.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 2,
                  question: 'Is Unloque a government app?',
                  answer:
                      'Nope! It\'s an independent platform built to support transparency and accessibility, and '
                      'to help citizens access public services more easily.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 3,
                  question: 'Is my personal data safe?',
                  answer:
                      'Yes. Your data is encrypted and only accessible to authorized personnel from '
                      'government agencies.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 4,
                  question: 'How do I know if my application was received?',
                  answer:
                      'After submission, you\'ll see your application status under the "My Applications" tab. '
                      'You\'ll also receive app notifications when there are updates.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 5,
                  question: 'What if I submitted the wrong document?',
                  answer:
                      'You can update your application before it\'s reviewed. If it\'s already being processed, wait '
                      'for the rejection notice and reapply with the correct files.',
                ),
                _buildDivider(),
                _buildFaqItem(
                  index: 6,
                  question: 'Can I apply for more than one program?',
                  answer:
                      'Yes! You can apply to any programs you\'re eligible for.',
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(
      {required int index, required String question, required String answer}) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedList[index] = !_expandedList[index];
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  _expandedList[index]
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_expandedList[index])
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[300],
      thickness: 1,
    );
  }
}
