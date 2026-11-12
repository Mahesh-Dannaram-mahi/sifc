import 'simple_policy_view.dart';

class CommunityGuidelines {
  static const String title = 'Community Guidelines';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'community_standards': {
      'id': 'community_standards',
      'title': 'Community Standards',
      'summary': 'Our commitment to a respectful community',
      'details': [
        {
          'title': 'Core Values',
          'points': [
            'Respect for all community members regardless of background',
            'Constructive communication and feedback',
            'Support for local businesses and merchants',
            'Honest reviews and authentic experiences',
            'Inclusive and welcoming environment for everyone',
            'Commitment to quality and excellence',
          ],
        },
        {
          'title': 'Expected Behavior',
          'points': [
            'Treat delivery partners with courtesy and respect',
            'Provide accurate and honest feedback about orders',
            'Communicate any issues promptly and professionally',
            'Respect merchant policies and operational hours',
            'Maintain appropriate communication with support staff',
            'Follow platform guidelines for all interactions',
          ],
        },
      ],
    },
    'user_conduct': {
      'id': 'user_conduct',
      'title': 'User Conduct Guidelines',
      'summary': 'Appropriate behavior for platform users',
      'details': [
        {
          'title': 'Ordering Behavior',
          'points': [
            'Place orders with genuine intent to purchase',
            'Provide accurate delivery information',
            'Be available to receive orders within reasonable time',
            'Communicate special instructions clearly in advance',
            'Respect preparation time and delivery schedules',
            'Avoid excessive order modifications after confirmation',
          ],
        },
        {
          'title': 'Communication Standards',
          'points': [
            'Use respectful language in all communications',
            'Avoid profanity or offensive content',
            'Provide constructive feedback for improvement',
            'Respond promptly to merchant or delivery partner queries',
            'Report issues through appropriate channels',
            'Maintain professional tone in dispute resolution',
          ],
        },
      ],
    },
    'review_guidelines': {
      'id': 'review_guidelines',
      'title': 'Review & Rating Guidelines',
      'summary': 'Fair and honest review practices',
      'details': [
        {
          'title': 'Authentic Reviews',
          'points': [
            'Only review items you have actually ordered',
            'Provide specific and detailed feedback',
            'Rate based on actual experience, not expectations',
            'Include relevant context for your review',
            'Update reviews if experience changes significantly',
            'Avoid reviews based on third-party information',
          ],
        },
        {
          'title': 'Prohibited Review Practices',
          'points': [
            'Fake reviews or reviews for compensation',
            'Competitor reviews or malicious content',
            'Personal attacks on merchants or staff',
            'Reviews containing hate speech or discrimination',
            'Reviews with personal information about others',
            'Multiple reviews for the same order experience',
          ],
        },
      ],
    },
    'prohibited_activities': {
      'id': 'prohibited_activities',
      'title': 'Prohibited Activities',
      'summary': 'Actions that are not allowed on our platform',
      'details': [
        {
          'title': 'Account Misuse',
          'points': [
            'Creating multiple accounts to exploit promotions',
            'Sharing account credentials with others',
            'Using fake information for registration',
            'Attempting to manipulate loyalty program systems',
            'Circumventing platform policies or restrictions',
            'Exploiting technical vulnerabilities or bugs',
          ],
        },
        {
          'title': 'Fraudulent Behavior',
          'points': [
            'False claims about order issues for refunds',
            'Chargeback abuse or payment fraud',
            'Impersonating merchants or platform staff',
            'Coordinating fake reviews with other users',
            'Manipulating delivery partner ratings unfairly',
            'Exploiting promotional offers illegitimately',
          ],
        },
      ],
    },
    'delivery_partner_interaction': {
      'id': 'delivery_partner_interaction',
      'title': 'Delivery Partner Interaction',
      'summary': 'Guidelines for interacting with delivery personnel',
      'details': [
        {
          'title': 'Respectful Treatment',
          'points': [
            'Treat delivery partners with dignity and respect',
            'Understand they work under time constraints',
            'Provide clear directions and access information',
            'Be prepared for delivery at scheduled time',
            'Communicate delays or issues promptly',
            'Appreciate their service in challenging conditions',
          ],
        },
        {
          'title': 'Safety Considerations',
          'points': [
            'Maintain safe distance during handover',
            'Follow contactless delivery when requested',
            'Ensure well-lit and safe delivery locations',
            'Report any safety concerns immediately',
            'Avoid physical contact unless necessary',
            'Respect delivery partner\'s personal boundaries',
          ],
        },
      ],
    },
    'dispute_resolution': {
      'id': 'dispute_resolution',
      'title': 'Dispute Resolution',
      'summary': 'Handling conflicts and disagreements',
      'details': [
        {
          'title': 'Resolution Process',
          'points': [
            'Contact customer support for formal disputes',
            'Provide clear evidence and documentation',
            'Allow reasonable time for investigation',
            'Participate constructively in resolution process',
            'Accept fair and reasonable outcomes',
            'Escalate only through proper channels',
          ],
        },
        {
          'title': 'Mediation Guidelines',
          'points': [
            'Consider merchant perspective in disputes',
            'Be open to compromise solutions',
            'Focus on resolution rather than blame',
            'Maintain professional communication throughout',
            'Document all communication related to dispute',
            'Learn from experience to prevent future issues',
          ],
        },
      ],
    },
    'consequences': {
      'id': 'consequences',
      'title': 'Consequences & Enforcement',
      'summary': 'What happens when guidelines are violated',
      'details': [
        {
          'title': 'Warning System',
          'points': [
            'First offense: Warning and educational notice',
            'Second offense: Temporary feature restrictions',
            'Third offense: Account suspension (7-30 days)',
            'Fourth offense: Permanent account termination',
            'Severe violations: Immediate permanent ban',
            'All warnings documented in account history',
          ],
        },
        {
          'title': 'Appeal Process',
          'points': [
            'Right to appeal any moderation decision',
            'Submit appeal within 7 days of action',
            'Provide additional context or evidence',
            'Review by senior moderation team',
            'Final decision communicated within 14 days',
            'Appeal decisions are final and binding',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'community_standards',
    'user_conduct',
    'review_guidelines',
    'prohibited_activities',
    'delivery_partner_interaction',
    'dispute_resolution',
    'consequences',
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
