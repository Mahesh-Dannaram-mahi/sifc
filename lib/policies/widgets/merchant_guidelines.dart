import 'simple_policy_view.dart';

class MerchantGuidelines {
  static const String title = 'Merchant Guidelines';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'onboarding_requirements': {
      'id': 'onboarding_requirements',
      'title': 'Onboarding Requirements',
      'summary': 'Essential criteria for merchant partnership',
      'details': [
        {
          'title': 'Business Registration',
          'points': [
            'Valid business registration certificate mandatory',
            'Current trade license from local authorities',
            'GST registration for tax compliance',
            'Food license (FSSAI) for food and beverage businesses',
            'Bank account for business transactions',
            'PAN card for business identification',
          ],
        },
        {
          'title': 'Quality Standards',
          'points': [
            'Professional kitchen and preparation facilities',
            'Quality ingredients and sourcing documentation',
            'Standardized recipes and preparation methods',
            'Food safety and hygiene certification',
            'Professional staff training programs',
            'Quality control processes and documentation',
          ],
        },
      ],
    },
    'operational_standards': {
      'id': 'operational_standards',
      'title': 'Operational Standards',
      'summary': 'Daily operational requirements',
      'details': [
        {
          'title': 'Service Quality',
          'points': [
            'Consistent taste and quality across all orders',
            'Professional packaging and presentation',
            'Timely order preparation within promised time',
            'Accurate order fulfillment without errors',
            'Temperature maintenance for food safety',
            'Customer service excellence standards',
          ],
        },
        {
          'title': 'Hygiene & Safety',
          'points': [
            'Daily cleaning and sanitization protocols',
            'Staff hygiene standards and uniforms',
            'Regular pest control and maintenance',
            'Food storage at proper temperatures',
            'Clean and organized preparation areas',
            'Compliance with local health regulations',
          ],
        },
      ],
    },
    'menu_management': {
      'id': 'menu_management',
      'title': 'Menu Management',
      'summary': 'Guidelines for menu and pricing',
      'details': [
        {
          'title': 'Menu Requirements',
          'points': [
            'Accurate and detailed menu descriptions',
            'Clear allergen information for all items',
            'High-quality food photography for all items',
            'Regular menu updates and seasonal additions',
            'Pricing transparency and consistency',
            'Availability status updates in real-time',
          ],
        },
        {
          'title': 'Pricing Guidelines',
          'points': [
            'Competitive pricing based on market rates',
            'Clear breakdown of all charges and taxes',
            'No hidden fees or surprise charges',
            'Regular price reviews and adjustments',
            'Special pricing for loyalty program members',
            'Promotional pricing with clear terms',
          ],
        },
      ],
    },
    'order_fulfillment': {
      'id': 'order_fulfillment',
      'title': 'Order Fulfillment',
      'summary': 'Processing and delivery standards',
      'details': [
        {
          'title': 'Order Processing',
          'points': [
            'Accept orders within 2 minutes of receipt',
            'Begin preparation immediately after confirmation',
            'Maintain accurate preparation time estimates',
            'Update order status in real-time',
            'Communicate delays to customers promptly',
            'Quality check before packaging for delivery',
          ],
        },
        {
          'title': 'Packaging Standards',
          'points': [
            'Food-grade packaging materials only',
            'Secure and spill-proof packaging',
            'Temperature-appropriate packaging',
            'Clear labeling with order details',
            'Eco-friendly packaging when possible',
            'Professional presentation standards',
          ],
        },
      ],
    },
    'customer_service': {
      'id': 'customer_service',
      'title': 'Customer Service',
      'summary': 'Excellence in customer interactions',
      'details': [
        {
          'title': 'Communication Standards',
          'points': [
            'Professional and courteous communication',
            'Prompt response to customer inquiries',
            'Clear and accurate information sharing',
            'Empathetic handling of customer complaints',
            'Regular feedback collection and implementation',
            'Multi-language support when possible',
          ],
        },
        {
          'title': 'Issue Resolution',
          'points': [
            '24-hour response time for complaints',
            'Fair resolution of customer disputes',
            'Replacement or refund policies clearly stated',
            'Documentation of all customer interactions',
            'Regular review of customer feedback',
            'Continuous improvement based on feedback',
          ],
        },
      ],
    },
    'technology_integration': {
      'id': 'technology_integration',
      'title': 'Technology Integration',
      'summary': 'Platform and technology requirements',
      'details': [
        {
          'title': 'System Requirements',
          'points': [
            'Reliable internet connection for order management',
            'Smartphone or tablet for order acceptance',
            'Printer for order receipts (optional)',
            'POS system integration capabilities',
            'Regular software and app updates',
            'Backup systems for order management',
          ],
        },
        {
          'title': 'Digital Operations',
          'points': [
            'Real-time inventory management',
            'Digital payment processing integration',
            'Order tracking and status updates',
            'Analytics and reporting tools usage',
            'Customer data management and privacy',
            'Regular system maintenance and updates',
          ],
        },
      ],
    },
    'performance_metrics': {
      'id': 'performance_metrics',
      'title': 'Performance Metrics',
      'summary': 'Quality and performance evaluation',
      'details': [
        {
          'title': 'Key Performance Indicators',
          'points': [
            'Order acceptance rate (target: >95%)',
            'Average preparation time (target: <15 minutes)',
            'Customer satisfaction rating (target: >4.5/5)',
            'Order accuracy rate (target: >98%)',
            'On-time delivery rate (target: >90%)',
            'Customer complaint resolution rate (target: >95%)',
          ],
        },
        {
          'title': 'Quality Assurance',
          'points': [
            'Regular quality audits by Sipora team',
            'Mystery shopping evaluations',
            'Customer feedback analysis',
            'Peer reviews and best practice sharing',
            'Performance improvement plans when needed',
            'Recognition for outstanding performance',
          ],
        },
      ],
    },
    'compliance_requirements': {
      'id': 'compliance_requirements',
      'title': 'Compliance & Legal',
      'summary': 'Regulatory and legal requirements',
      'details': [
        {
          'title': 'Regulatory Compliance',
          'points': [
            'Regular health department inspections',
            'Food safety and handling certifications',
            'Local business license renewals',
            'Tax compliance and documentation',
            'Employment law compliance',
            'Environmental regulations adherence',
          ],
        },
        {
          'title': 'Platform Policies',
          'points': [
            'Adherence to Sipora terms of service',
            'No direct payment circumvention',
            'Fair competition and ethical practices',
            'Data privacy and security compliance',
            'Intellectual property respect',
            'Regular policy updates and training',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'onboarding_requirements',
    'operational_standards',
    'menu_management',
    'order_fulfillment',
    'customer_service',
    'technology_integration',
    'performance_metrics',
    'compliance_requirements',
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
