import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Terms and Conditions',
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
                SectionTitle('Terms and Conditions'),
                SectionText(
                  'This service is operated by the team TechIVision. Our goal is to improve access to '
                  'government social welfare programs through technology.\n\n'
                  'By accessing and using our mobile and web applications and any content and features '
                  'therein, you indicate your acceptance of these terms, our privacy policy, and any other '
                  'notices or guidelines we may post from time to time.',
                ),
                NumberedListItem(
                  number: '1',
                  text:
                      'Please read these terms and conditions carefully. By using Unloque, you '
                      'agree to comply with these terms and all applicable laws and regulations.',
                ),
                NumberedListItem(
                  number: '2',
                  text:
                      'If you do not accept these terms, please do not access and/or use our '
                      'services.',
                ),
                NumberedListItem(
                  number: '3',
                  text:
                      'We may update these terms at any time. Please review them regularly to stay '
                      'informed. Continued use of services after changes have made constitutes your '
                      'agreement to the revised terms.',
                ),
                SectionTitle('Use of our Services'),
                NumberedListItem(
                  number: '1',
                  text:
                      'You agree to use our services for lawful purposes only and in a way that does not '
                      'infringe the rights of or restrict any person\'s use and enjoyment of the platform. You '
                      'agree to comply with all relevant laws and regulations.',
                ),
                NumberedListItem(
                  number: '2',
                  text: 'When using our services, you agree that:',
                ),
                BulletListItem(
                  text:
                      'You will only submit true, accurate, and complete information. '
                      'Submitting false data can delay the processing of your application or lead to '
                      'disqualification from programs.',
                ),
                BulletListItem(
                  text:
                      'You will not impersonate another person or use someone else\'s '
                      'documents. Doing so is considered fraud and may lead to legal '
                      'consequences or criminal charges.',
                ),
                BulletListItem(
                  text:
                      'You will use the platform for personal, non-commercial purposes unless '
                      'authorized. The system is designed to help individuals, not for profit or third-'
                      'party gain.',
                ),
                NumberedListItem(
                  number: '3',
                  text: 'You also agree not to:',
                ),
                BulletListItem(
                  text:
                      'Upload fake or altered documents as it may harm the integrity of the '
                      'system.',
                ),
                BulletListItem(
                  text:
                      'Reuse content for other purposes without written permission. These '
                      'tools are only made for transparency, not for unauthorized redistribution.',
                ),
                BulletListItem(
                  text:
                      'Use the system in any way that compromises security or user privacy. '
                      'Any form of interference undermines trust and safety and may lead to a '
                      'permanent ban and reporting to authorities.',
                ),
                SectionTitle('Privacy Policy'),
                SectionText(
                  'This Privacy Policy controls the way Unloque collects, uses, discloses, and protects '
                  'personal information submitted by users regarding the mobile and web apps services. This '
                  'Policy is fully compliant with Republic Act No. 10173, otherwise referred to as the Data '
                  'Privacy Act of 2012, and other relevant Philippine laws and regulations. By accessing and '
                  'using our Services, you are bound to the terms of this Policy.',
                ),
                NumberedListItem(
                  number: '1',
                  text: 'Collection of Personal Data',
                  isBold: true,
                ),
                SectionText(
                  'Unloque gathers personal data used in the facilitation of application for government social '
                  'welfare programs. The information gathered may include, but not be limited to: your full '
                  'name, contact details, government identification numbers, residential address, '
                  'demographic information, educational qualifications, and documents submitted.\n\n'
                  'We can also harvest anonymized location information for transparency and more effective '
                  'resource allocation supporting purposes.',
                ),
                NumberedListItem(
                  number: '2',
                  text: 'Purpose of Processing',
                  isBold: true,
                ),
                SectionText(
                  'Personal data that is submitted to Unloque will be processed exclusively for valid, stated '
                  'purposes. These include identity verification of applicants, application for and processing '
                  'of public welfare services, and generation of demographic reports to enhance '
                  'policymaking and transparency. No data will be processed beyond the essential '
                  'requirements for such purposes.',
                ),
                NumberedListItem(
                  number: '3',
                  text: 'Legal grounds for processing',
                  isBold: true,
                ),
                SectionText(
                  'Unloque processes your data based on lawful reasons such as your express consent, in '
                  'pursuit of public interest aims, adherence to legal requirements, and legitimate interest in '
                  'anti-fraud and in ensuring fair access to government schemes.',
                ),
                NumberedListItem(
                  number: '4',
                  text: 'Third-Party Handling Disclosure',
                  isBold: true,
                ),
                SectionText(
                  'All data submitted through Unloque is transferred securely to the appropriate agency or '
                  'program portal, depending on program requirements. We may act as a data intermediary '
                  'but we do not store any decision-making authority or verification rights beyond what is '
                  'needed to assist with submission and tracking.',
                ),
                NumberedListItem(
                  number: '5',
                  text: 'Data Sharing and Disclosure',
                  isBold: true,
                ),
                SectionText(
                  'Unloque will only disclose your personal data to government agencies with the proper '
                  'authority, local government units, and contracted service providers subject to strict data '
                  'protection agreements. Information will not be sold or made available to advertisers or any '
                  'commercial entity.\n\n'
                  'All third-party partners are chosen based on their capability to maintain security, '
                  'confidentiality, and data protection standards in accordance with this Policy and relevant '
                  'laws.',
                ),
                NumberedListItem(
                  number: '6',
                  text: 'Security Measures',
                  isBold: true,
                ),
                SectionText(
                  'We utilize industry standard organizational, physical, and technological controls to '
                  'safeguard individual information from unauthorized use, loss, or disclosure. These include '
                  'encryption mechanisms, secure cloud infrastructure, access control measures, and '
                  'regular security reviews.',
                ),
                NumberedListItem(
                  number: '7',
                  text: 'Data Subject Rights',
                  isBold: true,
                ),
                SectionText(
                  'As a data subject of the Data Privacy Act of 2012, you are entitled to the following rights: '
                  'the right to be informed, the right to access, the right to object, the right to erasure or '
                  'blocking, the right to correct inaccuracies, the right to data portability, and the right to file a '
                  'complaint before the National Privacy Commission (NPC).',
                ),
                NumberedListItem(
                  number: '8',
                  text: 'Personal Data Retention and Disposal',
                  isBold: true,
                ),
                SectionText(
                  'Unloque will retain your personal data only for the period necessary to achieve the purpose '
                  'for which it was collected, or as is required by law. Once data is no longer needed, it shall '
                  'be securely deleted or anonymized in accordance with relevant regulations and internal '
                  'procedures.',
                ),
                NumberedListItem(
                  number: '9',
                  text: 'Amendments to this Policy',
                  isBold: true,
                ),
                SectionText(
                  'This Policy will be updated periodically to address changes in legislation, guidance from '
                  'the relevant regulators, or system operation. We recommend reviewing this Policy on a '
                  'regular basis. Ongoing use of the Services after the release of updates will be deemed '
                  'acceptance of the new terms.',
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.black87,
        ),
      ),
    );
  }
}

class SectionText extends StatelessWidget {
  final String text;

  const SectionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class NumberedListItem extends StatelessWidget {
  final String number;
  final String text;
  final bool isBold;

  const NumberedListItem({
    required this.number,
    required this.text,
    this.isBold = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                height: 1.5,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BulletListItem extends StatelessWidget {
  final String text;

  const BulletListItem({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
