import 'package:flutter/material.dart';

class AvailableApplicationsData {
  static List<Map<String, dynamic>> getAllApplications() {
    return [
      {
        'id': 'dost_science_scholarship',
        'category': 'Education',
        'programName': 'DOST Science Scholarship',
        'organizationName': 'Department of Science and Technology',
        'description':
            'Scholarship for students pursuing degrees in science and technology fields.',
        'deadline': 'Dec 31, 2023',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
        'details': {
          'description':
              'This scholarship supports students in science and technology fields with financial assistance. '
                  'It covers tuition fees, book allowances, and monthly stipends. Recipients are expected to maintain '
                  'a certain GPA and participate in science-related activities. This program aims to nurture future scientists '
                  'and innovators who will contribute to national development.',
          'requirements': [
            'Must be a Filipino citizen.',
            'Must have a high school GPA of 85% or higher.',
            'Must pass the DOST scholarship exam.',
            'Must submit a letter of recommendation from a teacher.',
            'Must provide proof of financial need.',
            'Must attend an orientation session upon acceptance.'
          ],
          'eligibility': {
            'points': [
              'Open to incoming college students.',
              'Must not have any existing scholarship grants.',
              'Must demonstrate a strong interest in science and technology.',
              'Must be willing to work in the Philippines after graduation for at least 2 years.'
            ],
            'extra':
                'Applicants must also pass an interview conducted by the DOST selection committee. '
                    'Special consideration will be given to students from underprivileged backgrounds.'
          },
          'forms': [
            {
              'type': 'short_answer',
              'label': 'Full Name',
              'placeholder': 'Enter your full name'
            },
            {
              'type': 'paragraph',
              'label': 'Why do you deserve this scholarship?',
              'placeholder': 'Write your answer here...'
            },
            {
              'type': 'multiple_choice',
              'label': 'Preferred Field of Study',
              'options': ['Engineering', 'Science', 'Technology', 'Mathematics']
            },
            {
              'type': 'checkbox',
              'label': 'Documents Submitted',
              'options': [
                'Transcript of Records',
                'Birth Certificate',
                'ID Picture'
              ]
            },
            {'type': 'date', 'label': 'Date of Birth'},
            {
              'type': 'attachment',
              'label': 'Upload Supporting Documents',
              'placeholder': 'Attach your files here...'
            },
            {
              'type': 'attachment',
              'label': 'Upload Identification Documents',
              'placeholder': 'Attach your ID files here...'
            },
            {
              'type': 'attachment',
              'label': 'Upload Financial Documents',
              'placeholder': 'Attach your financial files here...'
            }
          ]
        }
      },
      {
        'id': 'public_school_teachers_grant',
        'category': 'Education',
        'programName': 'Public School Teachers Grant',
        'organizationName': 'Department of Education',
        'description':
            'Financial assistance program for public school teachers pursuing advanced studies.',
        'deadline': 'Jan 15, 2024',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
        'details': {
          'description':
              'This grant provides financial support for public school teachers pursuing higher education.',
          'requirements': [
            'Must be a licensed public school teacher.',
            'Must be enrolled in a graduate program.',
            'Must submit a letter of intent.'
          ],
          'eligibility': {
            'points': [
              'Open to teachers with at least 3 years of teaching experience.',
              'Must have a satisfactory performance rating.'
            ],
            'extra': 'Priority will be given to teachers in underserved areas.'
          },
          'forms': [
            {
              'type': 'short_answer',
              'label': 'Full Name',
              'placeholder': 'Enter your full name'
            },
            {
              'type': 'paragraph',
              'label': 'Why do you want this grant?',
              'placeholder': 'Write your answer here...'
            },
            {
              'type': 'checkbox',
              'label': 'Documents Submitted',
              'options': [
                'Transcript of Records',
                'Teaching License',
                'Letter of Intent'
              ]
            },
            {'type': 'date', 'label': 'Date of Birth'},
            {
              'type': 'attachment',
              'label': 'Upload Supporting Documents',
              'placeholder': 'Attach your files here...'
            }
          ]
        }
      },
      {
        'id': 'medical_technology_scholarship',
        'category': 'Healthcare',
        'programName': 'Medical Technology Scholarship',
        'organizationName': 'Department of Health',
        'description':
            'Scholarship program for aspiring medical technologists.',
        'deadline': 'Dec 20, 2023',
        'categoryColor': Colors.green[200],
        'organizationLogo': Icons.local_hospital,
        'details': {
          'description':
              'This program provides financial aid to students pursuing medical technology degrees.',
          'requirements': [
            'Must be enrolled in a medical technology program.',
            'Must have a GPA of 3.0 or higher.',
            'Must commit to serving in public health after graduation.'
          ],
          'eligibility': {
            'points': [
              'Open to college sophomores and above.',
              'Must be in good academic standing.'
            ],
            'extra':
                'Preference will be given to students from underserved areas.'
          },
          'forms': [
            {
              'type': 'short_answer',
              'label': 'Full Name',
              'placeholder': 'Enter your full name'
            },
            {
              'type': 'paragraph',
              'label': 'Why do you want to pursue medical technology?',
              'placeholder': 'Write your answer here...'
            },
            {
              'type': 'multiple_choice',
              'label': 'Preferred Area of Practice',
              'options': ['Clinical Laboratory', 'Public Health', 'Research']
            },
            {
              'type': 'checkbox',
              'label': 'Documents Submitted',
              'options': [
                'Transcript of Records',
                'Birth Certificate',
                'ID Picture'
              ]
            },
            {'type': 'date', 'label': 'Date of Birth'},
            {
              'type': 'attachment',
              'label': 'Upload Supporting Documents',
              'placeholder': 'Attach your files here...'
            }
          ]
        }
      },
      {
        'id': 'youth_leadership_program',
        'category': 'Social',
        'programName': 'Youth Leadership Program',
        'organizationName': 'Department of Social Welfare',
        'description':
            'Training and support program for young community leaders.',
        'deadline': 'Jan 20, 2024',
        'categoryColor': Colors.purple[200],
        'organizationLogo': Icons.people,
        'details': {
          'description':
              'This program aims to develop leadership skills among youth.',
          'requirements': [
            'Must be between 18-25 years old.',
            'Must have a track record of community involvement.',
            'Must submit a personal statement.'
          ],
          'eligibility': {
            'points': [
              'Open to youth from all regions.',
              'Must demonstrate leadership potential.'
            ],
            'extra':
                'Special consideration for applicants from marginalized communities.'
          },
          'forms': [
            {
              'type': 'short_answer',
              'label': 'Full Name',
              'placeholder': 'Enter your full name'
            },
            {
              'type': 'paragraph',
              'label': 'Describe your leadership experience.',
              'placeholder': 'Write your answer here...'
            },
            {
              'type': 'checkbox',
              'label': 'Documents Submitted',
              'options': [
                'Resume',
                'Recommendation Letter',
                'Community Involvement Proof'
              ]
            },
            {'type': 'date', 'label': 'Date of Birth'},
            {
              'type': 'attachment',
              'label': 'Upload Supporting Documents',
              'placeholder': 'Attach your files here...'
            }
          ]
        }
      },
    ];
  }

  static List<Map<String, dynamic>> getApplicationsByCategory(String category) {
    return getAllApplications()
        .where((app) => app['category'] == category)
        .toList();
  }
}
