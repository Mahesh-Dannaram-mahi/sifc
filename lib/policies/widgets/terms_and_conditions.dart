import 'simple_policy_view.dart';

class TermsAndConditions {
  static const String title = 'Terms & Conditions';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'welcome': {
      'id': 'welcome',
      'title': 'Welcome to Sipora',
      'summary': 'Your premium tea and coffee experience platform',
      'details': [
        {
          'points': [
            'Welcome to Sipora, your premier digital destination for discovering and enjoying the finest tea and coffee experiences',
            'Our platform serves as a bridge between passionate tea/coffee lovers and quality local outlets',
            'We are committed to creating a safe, fair, and enjoyable ecosystem for all community members',
            'These terms form the foundation of our relationship and ensure a transparent experience',
          ],
        },
      ],
    },
    'introduction': {
      'id': 'introduction',
      'title': 'Introduction & Platform Overview',
      'summary': 'Understanding how Sipora works and what we offer',
      'details': [
        {
          'title': 'What is Sipora?',
          'points': [
            'A revolutionary digital platform connecting tea and coffee enthusiasts with local artisanal outlets',
            'Technology-driven solution for seamless beverage discovery and ordering',
            'Community-focused ecosystem promoting local businesses and beverage culture',
          ],
        },
        {
          'title': 'Our Core Services',
          'points': [
            'Smart discovery of tea and coffee outlets based on your preferences and location',
            'Hassle-free order placement with real-time tracking and updates',
            'Comprehensive loyalty rewards program with exclusive member benefits',
            'Secure digital payment processing through industry-leading partners',
            'Personalized recommendations based on your taste preferences',
            'Special promotional offers and seasonal campaigns',
          ],
        },
        {
          'title': 'Our Role',
          'points': [
            'Sipora acts as a technology intermediary platform facilitating transactions',
            'We provide the digital infrastructure for seamless customer-merchant connections',
            'Quality assurance through verified merchant partnerships',
            'Continuous platform improvement based on user feedback',
          ],
          'note':
              'We are committed to transparency in all our operations and interactions',
        },
      ],
    },
    'definitions': {
      'id': 'definitions',
      'title': 'Key Terms & Definitions',
      'summary': 'Understanding the language of our platform',
      'details': [
        {
          'title': 'Platform Terminology',
          'points': [
            'Platform: The Sipora mobile application and website collectively',
            'Customer/User: Any individual who registers and uses Sipora services',
            'Merchant/Outlet: Tea or coffee shops officially partnered with Sipora',
            'Transaction: Any purchase, order, or payment processed through Sipora',
            'Payment Gateway: Our secure payment processing system powered by Razorpay',
            'Sipora Points: Loyalty rewards earned on qualifying purchases',
            'Order Confirmation: Digital acknowledgment of your placed order',
          ],
        },
      ],
    },
    'registration': {
      'id': 'registration',
      'title': 'Account Registration & Security',
      'summary': 'Creating and securing your Sipora account',
      'details': [
        {
          'title': 'Eligibility Requirements',
          'points': [
            'You must be 18 years or older to create an account',
            'Valid mobile number required for OTP-based verification',
            'Email address is optional but recommended for account recovery',
            'One account per user - multiple accounts are strictly prohibited',
            'Business accounts require additional verification',
          ],
        },
        {
          'title': 'Account Security Guidelines',
          'points': [
            'You are solely responsible for maintaining account confidentiality',
            'Never share your OTP or login credentials with anyone',
            'Enable biometric login where available for added security',
            'Immediately report any unauthorized account access',
            'Regular password updates are recommended',
            'Sipora will never ask for your password via email or phone',
          ],
        },
        {
          'title': 'Account Termination',
          'points': [
            'You may delete your account anytime through app settings',
            'Sipora reserves right to suspend accounts violating terms',
            'Inactive accounts may be deactivated after 24 months',
            'Fraudulent activities lead to immediate termination',
          ],
          'note':
              'Account deletion is irreversible and results in loss of all rewards',
        },
      ],
    },
    'merchant': {
      'id': 'merchant',
      'title': 'Merchant Partnership Program',
      'summary': 'How we partner with quality beverage outlets',
      'details': [
        {
          'title': 'Merchant Requirements',
          'points': [
            'Valid business registration certificate mandatory',
            'FSSAI license required for all food and beverage operations',
            'Strict quality standards and hygiene protocols must be maintained',
            'Accurate menu, pricing, and outlet information required',
            'Regular quality audits conducted by Sipora team',
            'Insurance coverage recommended for business operations',
          ],
        },
        {
          'title': 'Partnership Benefits',
          'points': [
            'Increased visibility to thousands of beverage enthusiasts',
            'Access to customer analytics and business insights',
            'Marketing support and promotional opportunities',
            'Secure and reliable payment processing',
            'Dedicated merchant support team',
            'Community of like business owners',
          ],
        },
        {
          'title': 'Merchant Responsibilities',
          'points': [
            'Maintain accurate inventory and pricing information',
            'Process orders in a timely manner',
            'Provide quality products as described',
            'Resolve customer issues professionally',
            'Comply with all applicable laws and regulations',
          ],
        },
      ],
    },
    'payments': {
      'id': 'payments',
      'title': 'Payment Processing & Fees',
      'summary': 'Secure transactions and fee structure',
      'details': [
        {
          'title': 'Payment Flow',
          'points': [
            'All payments processed through Razorpay, our trusted payment partner',
            'End-to-end encryption for all financial transactions',
            'Payment flow: Customer ΓåÆ Sipora Platform ΓåÆ Merchant',
            'Multiple payment methods: Cards, UPI, NetBanking, Wallets',
            'Instant payment confirmation and digital receipts',
            'Secure storage of payment preferences (with consent)',
          ],
        },
        {
          'title': 'Fees and Charges',
          'points': [
            'Platform convenience fee: Small percentage per transaction',
            'Delivery fees: Based on distance and order value',
            'No hidden charges - all fees disclosed before order confirmation',
            'Premium membership: Optional subscription for reduced fees',
            'GST applicable as per government regulations',
            'International transaction fees for foreign cards',
          ],
        },
        {
          'title': 'Payment Security',
          'points': [
            'PCI DSS compliant payment processing',
            'Two-factor authentication for all transactions',
            'Real-time fraud detection and prevention',
            'Regular security audits by third-party firms',
            'Zero liability protection for unauthorized transactions',
          ],
          'note': 'We never store your complete card details on our servers',
        },
      ],
    },
    'refunds': {
      'id': 'refunds',
      'title': 'Refund & Cancellation Policy',
      'summary': 'Fair and transparent refund process',
      'details': [
        {
          'title': 'Cancellation Scenarios',
          'points': [
            'Before preparation starts: 90% refund of order value',
            'After preparation begins: No cancellation possible',
            'Technical issues preventing delivery: 100% refund',
            'Merchant unable to fulfill order: Full refund + loyalty points',
            'Wrong item delivered: Refund or replacement offered',
            'Long delivery delays: Partial refund or discount on next order',
          ],
        },
        {
          'title': 'Quality Issues',
          'points': [
            'Report quality concerns within 30 minutes of delivery',
            'Photo/video evidence required for verification',
            'Refund processed after quality team investigation',
            'Repeat offenders may face account restrictions',
            'Quality scores affect merchant partnership status',
          ],
        },
        {
          'title': 'Refund Processing',
          'points': [
            'Refunds processed within 5-7 business days',
            'Amount credited to original payment source',
            'Sipora credits for faster resolution when preferred',
            'International refunds may take 10-14 days',
            'Refund status trackable in app',
            'Dispute resolution available for unresolved issues',
          ],
          'note': 'Processing time depends on your bank/payment provider',
        },
      ],
    },
    'loyalty': {
      'id': 'loyalty',
      'title': 'Loyalty Rewards Program',
      'summary': 'Earn rewards on every sip',
      'details': [
        {
          'title': 'Earning Points',
          'points': [
            'Earn 10 Sipora Points for every ₹100 spent',
            'Bonus points on first order of the day',
            'Double points on your birthday week',
            'Refer friends: 500 points per successful referral',
            'Special event bonuses and limited-time multipliers',
            'Points never expire with active account',
          ],
        },
        {
          'title': 'Reward Tiers',
          'points': [
            'Bronze (0-1000 points): Basic rewards, 5% off',
            'Silver (1001-5000 points): 10% off, free delivery',
            'Gold (5001-10000 points): 15% off, priority support',
            'Platinum (10000+ points): 20% off, exclusive events',
            'Tier benefits refresh annually',
            'Special perks for maintaining tier status',
          ],
        },
        {
          'title': 'Redeeming Rewards',
          'points': [
            '100 points = ₹10 discount on any order',
            'Free beverage after every 10 purchases',
            'Exclusive access to member-only promotions',
            'Seasonal reward catalog with special items',
            'Gift points to friends and family',
            'Charity donation option available',
          ],
        },
      ],
    },
    'rights': {
      'id': 'rights',
      'title': 'User Rights & Responsibilities',
      'summary': 'Your rights and obligations on the platform',
      'details': [
        {
          'title': 'Your Rights',
          'points': [
            'Right to access and download your data',
            'Right to delete your account and associated data',
            'Right to fair treatment and non-discrimination',
            'Right to clear pricing and no hidden charges',
            'Right to dispute resolution for unsatisfactory experiences',
            'Right to privacy as per our privacy policy',
          ],
        },
        {
          'title': 'Your Responsibilities',
          'points': [
            'Provide accurate and truthful information',
            'Use platform only for lawful purposes',
            'Respect intellectual property rights',
            'No fraudulent transactions or chargeback abuse',
            'Professional and respectful communication',
            'Report bugs or security issues responsibly',
          ],
        },
        {
          'title': 'Prohibited Activities',
          'points': [
            'Creating multiple accounts to exploit promotions',
            'Automated ordering or bot usage',
            'Harassment of merchants or support staff',
            'Reverse engineering the platform',
            'Impersonation or identity fraud',
            'Commercial resale of ordered items',
          ],
        },
      ],
    },
    'privacy': {
      'id': 'privacy',
      'title': 'Data Privacy & Protection',
      'summary': 'How we protect and use your information',
      'details': [
        {
          'title': 'Information We Collect',
          'points': [
            'Basic profile information: name, phone, email',
            'Order history and preferences',
            'Location data for outlet discovery',
            'Payment information (securely by payment partners)',
            'Device information for app optimization',
            'Usage patterns to improve experience',
          ],
        },
        {
          'title': 'How We Use Your Data',
          'points': [
            'Process and fulfill your orders',
            'Personalize your beverage recommendations',
            'Improve platform performance and features',
            'Send relevant offers and updates',
            'Prevent fraud and enhance security',
            'Analyze trends and user behavior',
          ],
        },
        {
          'title': 'Data Protection Measures',
          'points': [
            'End-to-end encryption for sensitive data',
            'Regular security audits and updates',
            'Strict access controls and employee training',
            'Anonymization for analytics',
            'Secure data centers with redundancy',
            'Compliance with data protection laws',
          ],
          'note': 'We never sell your personal data to third parties',
        },
      ],
    },
    'legal': {
      'id': 'legal',
      'title': 'Legal & Compliance',
      'summary': 'Legal framework governing our relationship',
      'details': [
        {
          'title': 'Governing Law',
          'points': [
            'These terms are governed by the laws of India',
            'Subject to exclusive jurisdiction of Mumbai courts',
            'Compliance with Information Technology Act, 2000',
            'Consumer Protection Act, 2019 applicable',
            'GDPR compliance for EU users',
            'Arbitration clause for dispute resolution',
          ],
        },
        {
          'title': 'Limitation of Liability',
          'points': [
            'Sipora acts as technology intermediary only',
            'Not liable for product quality from merchants',
            'Not responsible for merchant operational delays',
            'Maximum liability limited to order value',
            'No liability for indirect or consequential damages',
            'Force majeure events excluded from liability',
          ],
        },
        {
          'title': 'Modifications',
          'points': [
            'Terms may be updated with 30 days notice',
            'Continued use constitutes acceptance',
            'Material changes notified via email',
            'Previous versions available on request',
            'Right to terminate with cause without notice',
            'Users may reject changes by closing account',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'welcome',
    'introduction',
    'definitions',
    'registration',
    'merchant',
    'payments',
    'refunds',
    'loyalty',
    'rights',
    'privacy',
    'legal',
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
