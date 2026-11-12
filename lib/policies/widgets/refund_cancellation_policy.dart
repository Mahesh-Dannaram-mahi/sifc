import 'simple_policy_view.dart';

class RefundCancellationPolicy {
  static const String title = 'Refund & Cancellation Policy';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'cancellation_policy': {
      'id': 'cancellation_policy',
      'title': 'Order Cancellation',
      'summary': 'When and how you can cancel your orders',
      'details': [
        {
          'title': 'Cancellation Timeframes',
          'points': [
            'Within 2 minutes of order placement: Full refund (100%)',
            '2-5 minutes after order: 90% refund (10% processing fee)',
            '5-10 minutes after order: 75% refund (25% processing fee)',
            'After 10 minutes or order preparation: No cancellation possible',
            'Bulk orders (₹1000+): Extended 5-minute cancellation window',
            'Custom orders: Cancellation policy varies by merchant',
          ],
        },
        {
          'title': 'Cancellation Process',
          'points': [
            'Cancel through app order status page',
            'Automatic refund processing to original payment method',
            'Refund confirmation sent via SMS and email',
            'Loyalty points restored if deducted',
            'Cancellation reason requested for service improvement',
            'Emergency cancellation available for verified issues',
          ],
        },
      ],
    },
    'refund_policy': {
      'id': 'refund_policy',
      'title': 'Refund Eligibility',
      'summary': 'When you qualify for a refund',
      'details': [
        {
          'title': 'Quality Issues',
          'points': [
            'Wrong items delivered: 100% refund or replacement',
            'Damaged packaging: 100% refund or redelivery',
            'Food quality concerns: Full refund after verification',
            'Temperature issues (cold items hot, etc.): 75% refund',
            'Missing items: Pro-rata refund or immediate redelivery',
            'Contamination or foreign objects: 100% refund + compensation',
          ],
        },
        {
          'title': 'Service Issues',
          'points': [
            'Delivery beyond 60 minutes: 25% refund coupon',
            'Delivery beyond 90 minutes: 50% refund to wallet',
            'Delivery beyond 120 minutes: 100% refund to wallet',
            'Rude behavior by delivery partner: 25% refund + apology',
            'Order not delivered: 100% refund + bonus points',
            'Multiple delivery attempts: 15% refund coupon',
          ],
        },
      ],
    },
    'refund_process': {
      'id': 'refund_process',
      'title': 'Refund Processing',
      'summary': 'How and when you receive your refund',
      'details': [
        {
          'title': 'Refund Methods',
          'points': [
            'Original payment method: 5-7 business days',
            'Sipora wallet: Immediate credit',
            'Bank transfer: 3-5 business days (for wallet refunds)',
            'Store credit: Instant processing',
            'Loyalty points: Immediate restoration',
            'Gift vouchers: Issued within 24 hours',
          ],
        },
        {
          'title': 'Processing Timeline',
          'points': [
            'Refund request review: 15-30 minutes',
            'Verification process: Up to 2 hours for complex cases',
            'Approval and initiation: Within 4 hours of verification',
            'Payment gateway processing: 2-5 business days',
            'Bank processing: Additional 1-2 business days',
            'Notification sent at each processing stage',
          ],
        },
      ],
    },
    'refund_exceptions': {
      'id': 'refund_exceptions',
      'title': 'Non-Refundable Items',
      'summary': 'Items and services not eligible for refunds',
      'details': [
        {
          'title': 'Excluded Categories',
          'points': [
            'Customized orders after preparation begins',
            'Perishable items consumed in full',
            'Promotional items and free additions',
            'Delivery charges for completed deliveries',
            'Peak hour surcharges during successful delivery',
            'Items returned due to customer preference change',
          ],
        },
        {
          'title': 'Special Circumstances',
          'points': [
            'Force majeure events (natural disasters, etc.)',
            'Customer-provided incorrect address',
            'Customer unavailable for delivery beyond 30 minutes',
            'Orders placed during merchant operational issues',
            'Items damaged due to customer handling',
            'Refund requests beyond 24 hours of delivery',
          ],
        },
      ],
    },
    'dispute_resolution': {
      'id': 'dispute_resolution',
      'title': 'Dispute Resolution',
      'summary': 'Resolving refund disagreements',
      'details': [
        {
          'title': 'Resolution Process',
          'points': [
            'Initial review by customer support team',
            'Evidence collection (photos, videos, timestamps)',
            'Merchant consultation for verification',
            'Senior support team escalation if needed',
            'Final decision within 48 hours of dispute',
            'Appeal process available for unsatisfactory resolutions',
          ],
        },
        {
          'title': 'Evidence Requirements',
          'points': [
            'Photo of damaged items with timestamp',
            'Video evidence for quality issues (recommended)',
            'Order confirmation and delivery screenshots',
            'Communication history with delivery partner',
            'Original packaging for contamination claims',
            'Witness statements for service issues',
          ],
        },
      ],
    },
    'compensation_policy': {
      'id': 'compensation_policy',
      'title': 'Compensation & Goodwill',
      'summary': 'Additional compensation for service failures',
      'details': [
        {
          'title': 'Service Failure Compensation',
          'points': [
            'First-time issue: 25% additional refund',
            'Repeated issues: 50% additional refund + loyalty bonus',
            'Major service failures: Free order credit + 500 points',
            'System-wide issues: Universal discount coupons',
            'Long resolution times: Additional 10% compensation',
            'Customer inconvenience: Variable compensation based on severity',
          ],
        },
        {
          'title': 'Goodwill Gestures',
          'points': [
            'Birthday order issues: Double refund + special gift',
            'Frequent customer issues: Priority resolution + bonus',
            'New customer problems: Enhanced compensation package',
            'Holiday order failures: Special compensation offers',
            'Corporate account issues: Dedicated resolution team',
            'VIP customer issues: Personalized compensation',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'cancellation_policy',
    'refund_policy',
    'refund_process',
    'refund_exceptions',
    'dispute_resolution',
    'compensation_policy',
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
