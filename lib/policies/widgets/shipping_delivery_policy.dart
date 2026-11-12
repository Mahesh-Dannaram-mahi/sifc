import 'simple_policy_view.dart';

class ShippingDeliveryPolicy {
  static const String title = 'Shipping & Delivery Policy';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'delivery_areas': {
      'id': 'delivery_areas',
      'title': 'Service Areas & Coverage',
      'summary': 'Where we deliver and service availability',
      'details': [
        {
          'title': 'Current Service Zones',
          'points': [
            'Major metropolitan areas within city limits',
            'Select suburban zones with partner merchant coverage',
            'Business districts and commercial areas',
            'Educational institutions and campus areas',
            'Residential communities with verified delivery routes',
            'Special event venues with prior coordination',
          ],
        },
        {
          'title': 'Coverage Verification',
          'points': [
            'Real-time address validation during checkout',
            'GPS-based delivery radius confirmation',
            'Alternative pickup options for out-of-zone addresses',
            'Regular service area expansion updates',
            'Notification of temporary service disruptions',
            'Partner merchant delivery capabilities verification',
          ],
        },
      ],
    },
    'delivery_timeframes': {
      'id': 'delivery_timeframes',
      'title': 'Delivery Timeframes',
      'summary': 'When you can expect your orders',
      'details': [
        {
          'title': 'Standard Delivery',
          'points': [
            'Average delivery time: 25-40 minutes',
            'Peak hours may extend to 45-60 minutes',
            'Order preparation time: 5-15 minutes',
            'Real-time tracking available from order confirmation',
            'Estimated delivery time provided at checkout',
            'Weather and traffic conditions may affect timing',
          ],
        },
        {
          'title': 'Express & Priority Options',
          'points': [
            'Express delivery: 15-25 minutes (additional fee)',
            'Priority handling for loyalty program members',
            'Scheduled delivery slots available in advance',
            'Business lunch rush priority service',
            'Weekend and holiday delivery schedules',
            'Bulk order special delivery arrangements',
          ],
        },
      ],
    },
    'delivery_charges': {
      'id': 'delivery_charges',
      'title': 'Delivery Fees & Charges',
      'summary': 'Cost structure for delivery services',
      'details': [
        {
          'title': 'Standard Delivery Fees',
          'points': [
            'Base delivery fee: ₹30-50 based on distance',
            'Zone-based pricing for different service areas',
            'Minimum order value: ₹150 for free delivery eligibility',
            'Peak hour surcharge: ₹10-15 during rush times',
            'Weather condition surcharges when applicable',
            'Multiple delivery destination handling fees',
          ],
        },
        {
          'title': 'Discount & Waiver Programs',
          'points': [
            'Free delivery on orders above ₹300',
            'Loyalty program members get 50% off delivery fees',
            'First-time user free delivery promotion',
            'Monthly delivery pass for frequent customers',
            'Bulk order delivery fee discounts',
            'Corporate account special delivery rates',
          ],
        },
      ],
    },
    'order_tracking': {
      'id': 'order_tracking',
      'title': 'Order Tracking & Updates',
      'summary': 'Stay informed about your delivery status',
      'details': [
        {
          'title': 'Real-Time Tracking Features',
          'points': [
            'Live GPS tracking of delivery partner',
            'Order preparation stage notifications',
            'Pickup confirmation and departure alerts',
            'Estimated arrival time updates',
            'Delivery partner contact information',
            'Route deviation and delay notifications',
          ],
        },
        {
          'title': 'Communication Channels',
          'points': [
            'In-app order status dashboard',
            'SMS notifications for key milestones',
            'Email confirmations and updates',
            'Push notifications for real-time alerts',
            'WhatsApp integration for order updates',
            'Customer service chat for tracking queries',
          ],
        },
      ],
    },
    'delivery_requirements': {
      'id': 'delivery_requirements',
      'title': 'Delivery Requirements & Guidelines',
      'summary': 'What you need to know for successful delivery',
      'details': [
        {
          'title': 'Customer Responsibilities',
          'points': [
            'Provide accurate and complete delivery address',
            'Ensure someone is available to receive the order',
            'Maintain accessible delivery location',
            'Provide valid contact number for coordination',
            'Inform about special delivery instructions in advance',
            'Be prepared with payment method if cash on delivery',
          ],
        },
        {
          'title': 'Special Handling Requests',
          'points': [
            'Contactless delivery options available',
            'Special timing requests accommodated when possible',
            'Building access codes provided securely',
            'Parking and delivery entrance instructions',
            'Temperature-sensitive handling for specific items',
            'Bulk item delivery coordination requirements',
          ],
        },
      ],
    },
    'delivery_issues': {
      'id': 'delivery_issues',
      'title': 'Delivery Issues & Resolution',
      'summary': 'How we handle delivery problems',
      'details': [
        {
          'title': 'Common Issues & Solutions',
          'points': [
            'Late delivery: Automatic discount coupon for future orders',
            'Wrong address: Redelivery attempt with updated information',
            'Customer unavailable: Order held for 15 minutes, then returned',
            'Damaged items: Immediate replacement or refund processed',
            'Missing items: Verified and redelivered within 30 minutes',
            'Delivery partner issues: Immediate escalation and resolution',
          ],
        },
        {
          'title': 'Resolution Process',
          'points': [
            '24/7 customer support for delivery issues',
            'Real-time issue reporting through app',
            'Photo evidence required for damage claims',
            'Automatic refund processing for verified issues',
            'Loyalty points compensation for service failures',
            'Follow-up satisfaction surveys for quality improvement',
          ],
        },
      ],
    },
    'restrictions': {
      'id': 'restrictions',
      'title': 'Delivery Restrictions & Limitations',
      'summary': 'Items and conditions not eligible for delivery',
      'details': [
        {
          'title': 'Item Restrictions',
          'points': [
            'Alcoholic beverages (age verification required)',
            'Perishable items beyond 2-hour delivery radius',
            'Items requiring special equipment for handling',
            'Hazardous materials and restricted substances',
            'Oversized items beyond standard delivery capacity',
            'Items requiring temperature control beyond 30 minutes',
          ],
        },
        {
          'title': 'Service Limitations',
          'points': [
            'No delivery during extreme weather conditions',
            'Limited service during public holidays and festivals',
            'Delivery suspension during local emergencies',
            'Maximum order value limits for single delivery',
            'Geographic restrictions in newly launched areas',
            'Time-based restrictions for certain merchant categories',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'delivery_areas',
    'delivery_timeframes',
    'delivery_charges',
    'order_tracking',
    'delivery_requirements',
    'delivery_issues',
    'restrictions',
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
