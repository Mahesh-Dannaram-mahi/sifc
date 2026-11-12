import 'simple_policy_view.dart';

class PrivacyPolicy {
  static const String title = 'Privacy Policy';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'data_collection': {
      'id': 'data_collection',
      'title': 'Information We Collect',
      'summary': 'What personal information we gather from users',
      'details': [
        {
          'title': 'Personal Information',
          'points': [
            'Full name and contact details (phone number, email address)',
            'Profile information including profile picture and preferences',
            'Delivery addresses and location data for service fulfillment',
            'Payment information processed securely through trusted partners',
            'Device information and app usage analytics',
            'Communication preferences and notification settings',
          ],
        },
        {
          'title': 'Automatically Collected Data',
          'points': [
            'IP address and general geographic location',
            'Device type, operating system, and browser information',
            'App usage patterns and interaction analytics',
            'Crash reports and technical diagnostics',
            'Cookies and similar tracking technologies',
            'Session duration and feature usage statistics',
          ],
        },
      ],
    },
    'data_usage': {
      'id': 'data_usage',
      'title': 'How We Use Your Information',
      'summary': 'Purpose and scope of data utilization',
      'details': [
        {
          'title': 'Service Delivery',
          'points': [
            'Process and fulfill your tea and coffee orders',
            'Provide personalized recommendations based on preferences',
            'Manage delivery logistics and tracking',
            'Process payments and handle refunds',
            'Send order confirmations and delivery updates',
            'Maintain your account and profile information',
          ],
        },
        {
          'title': 'Communication & Marketing',
          'points': [
            'Send promotional offers and discount notifications',
            'Provide customer support and respond to inquiries',
            'Share updates about new features and services',
            'Send loyalty program rewards and notifications',
            'Request feedback and conduct surveys',
            'Communicate policy changes and important updates',
          ],
        },
      ],
    },
    'data_sharing': {
      'id': 'data_sharing',
      'title': 'Data Sharing & Third Parties',
      'summary': 'How and when we share your information',
      'details': [
        {
          'title': 'Merchant Partners',
          'points': [
            'Share order details with partnered tea/coffee outlets',
            'Provide delivery information for order fulfillment',
            'Share customer feedback relevant to service quality',
            'Exchange necessary information for loyalty program integration',
            'Coordinate refund and dispute resolution processes',
            'Maintain quality assurance and service standards',
          ],
        },
        {
          'title': 'Service Providers',
          'points': [
            'Payment processors for secure transaction handling',
            'Delivery partners for order fulfillment',
            'Cloud service providers for data storage',
            'Analytics providers for app performance monitoring',
            'Communication platforms for notifications',
            'Security services for fraud prevention',
          ],
        },
      ],
    },
    'data_protection': {
      'id': 'data_protection',
      'title': 'Data Security & Protection',
      'summary': 'Measures we take to safeguard your information',
      'details': [
        {
          'title': 'Technical Safeguards',
          'points': [
            'End-to-end encryption for sensitive data transmission',
            'Secure socket layer (SSL) technology for all communications',
            'Regular security audits and vulnerability assessments',
            'Multi-factor authentication for account protection',
            'Intrusion detection and prevention systems',
            'Secure data centers with 24/7 monitoring',
          ],
        },
        {
          'title': 'Organizational Measures',
          'points': [
            'Strict employee access controls and authentication',
            'Comprehensive privacy training for all staff members',
            'Data minimization principles in collection practices',
            'Regular privacy impact assessments for new features',
            'Incident response procedures for data breaches',
            'Compliance with international data protection standards',
          ],
        },
      ],
    },
    'user_rights': {
      'id': 'user_rights',
      'title': 'Your Privacy Rights',
      'summary': 'Control over your personal information',
      'details': [
        {
          'title': 'Access & Correction',
          'points': [
            'Request access to your personal data at any time',
            'Update or correct inaccurate information in your profile',
            'Download your data in machine-readable format',
            'Review order history and account activity logs',
            'Access communication preferences and privacy settings',
            'Request deletion of inactive or outdated information',
          ],
        },
        {
          'title': 'Control & Consent',
          'points': [
            'Withdraw consent for marketing communications',
            'Opt-out of data sharing with third parties',
            'Control cookie and tracking preferences',
            'Set privacy preferences for your account',
            'Manage notification and alert settings',
            'Request restriction of data processing',
          ],
        },
      ],
    },
    'data_retention': {
      'id': 'data_retention',
      'title': 'Data Retention & Deletion',
      'summary': 'How long we keep your information',
      'details': [
        {
          'title': 'Retention Periods',
          'points': [
            'Account information retained while account is active',
            'Order history kept for 7 years for legal compliance',
            'Payment data processed and deleted per PCI standards',
            'Marketing communications preferences retained indefinitely',
            'Analytics data anonymized after 24 months',
            'Support tickets and communications retained for 3 years',
          ],
        },
        {
          'title': 'Deletion Process',
          'points': [
            'Account deletion removes all personal data immediately',
            'Order history may be retained for legal requirements',
            'Anonymized data may be used for analytics purposes',
            'Third-party data deletion requests initiated upon account closure',
            'Backup data deleted according to retention schedules',
            'Emergency data deletion available for security concerns',
          ],
        },
      ],
    },
    'legal_compliance': {
      'id': 'legal_compliance',
      'title': 'Legal & Regulatory Compliance',
      'summary': 'Our commitment to privacy laws',
      'details': [
        {
          'title': 'Applicable Regulations',
          'points': [
            'Information Technology Act, 2000 (India)',
            'Personal Data Protection Bill compliance',
            'General Data Protection Regulation (GDPR) for EU users',
            'California Consumer Privacy Act (CCPA) compliance',
            'Payment Card Industry Data Security Standard (PCI DSS)',
            'Industry-specific data protection guidelines',
          ],
        },
        {
          'title': 'Compliance Measures',
          'points': [
            'Regular privacy audits by third-party assessors',
            'Data Protection Officer appointed for oversight',
            'Privacy by Design principles in development',
            'Regular staff training on privacy regulations',
            'Documentation of data processing activities',
            'Incident reporting to regulatory authorities when required',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'data_collection',
    'data_usage',
    'data_sharing',
    'data_protection',
    'user_rights',
    'data_retention',
    'legal_compliance',
  ];

  static String getSectionTitle(String sectionId) {
    return sections[sectionId]?['title'] ?? '';
  }

  static String getSectionSummary(String sectionId) {
    return sections[sectionId]?['summary'] ?? '';
  }

  static List<PolicySectionDetail> getSectionDetails(String sectionId) {
    final details = sections[sectionId]?['details'] as List<dynamic>? ?? [];
    return details.map((detail) {
      final detailMap = detail as Map<String, dynamic>;
      return PolicySectionDetail(
        title: detailMap['title'] as String?,
        points: List<String>.from(detailMap['points'] ?? []),
        note: detailMap['note'] as String?,
      );
    }).toList();
  }
}
