import 'simple_policy_view.dart';

class LoyaltyProgramPolicy {
  static const String title = 'Loyalty Program Policy';
  static String get lastUpdated =>
      'Last updated: ${DateTime.now().toString().split(' ')[0]}';

  static const Map<String, dynamic> sections = {
    'program_overview': {
      'id': 'program_overview',
      'title': 'Program Overview',
      'summary': 'Understanding the Sipora loyalty rewards system',
      'details': [
        {
          'title': 'What is Sipora Rewards?',
          'points': [
            'Free loyalty program for all registered users',
            'Earn points on every qualifying purchase',
            'Redeem points for discounts and free items',
            'Tier-based benefits with increasing rewards',
            'Exclusive member-only promotions and offers',
            'Birthday and anniversary special rewards',
          ],
        },
        {
          'title': 'Program Benefits',
          'points': [
            'Points never expire with active account',
            'No minimum spend to earn points',
            'Instant point redemption at checkout',
            'Bonus points on special occasions',
            'Early access to new features and promotions',
            'Personalized offers based on preferences',
          ],
        },
      ],
    },
    'earning_points': {
      'id': 'earning_points',
      'title': 'Earning Points',
      'summary': 'How you accumulate loyalty points',
      'details': [
        {
          'title': 'Base Earning Rates',
          'points': [
            '10 points for every ₹100 spent on beverages',
            '5 points for every ₹100 spent on food items',
            '2 points for every ₹100 spent on merchandise',
            '1 point for every ₹100 spent on delivery fees',
            'Points rounded up to nearest whole number',
            'Points credited instantly after order completion',
          ],
        },
        {
          'title': 'Bonus Point Opportunities',
          'points': [
            'First order of the day: 2x points multiplier',
            'Birthday week: 3x points on all orders',
            'Weekend orders (Sat-Sun): 1.5x points',
            'New user first 5 orders: 2x points',
            'Referral bonus: 500 points per successful referral',
            'Social media sharing: 50 points per share (max 3/day)',
          ],
        },
      ],
    },
    'reward_tiers': {
      'id': 'reward_tiers',
      'title': 'Membership Tiers',
      'summary': 'Progressive benefits as you earn more',
      'details': [
        {
          'title': 'Tier Structure',
          'points': [
            'Bronze (0-1,000 points): 5% discount, free delivery on ₹200+',
            'Silver (1,001-5,000 points): 10% discount, free delivery on ₹150+',
            'Gold (5,001-10,000 points): 15% discount, free delivery on ₹100+',
            'Platinum (10,001+ points): 20% discount, always free delivery',
            'Tier status recalculated annually on anniversary date',
            'Grace period of 30 days to maintain tier status',
          ],
        },
        {
          'title': 'Tier-Specific Benefits',
          'points': [
            'Bronze: Basic rewards, monthly bonus offers',
            'Silver: Priority support, exclusive monthly deals',
            'Gold: VIP customer service, early sale access',
            'Platinum: Dedicated account manager, exclusive events',
            'All tiers: Points multiplier increases with tier level',
            'Tier upgrades: Instant bonus points on promotion',
          ],
        },
      ],
    },
    'redeeming_rewards': {
      'id': 'redeeming_rewards',
      'title': 'Redeeming Points',
      'summary': 'How to use your accumulated points',
      'details': [
        {
          'title': 'Redemption Options',
          'points': [
            '100 points = ₹10 discount on any order',
            '500 points = Free beverage (up to ₹150 value)',
            '1000 points = Free meal (up to ₹300 value)',
            '2000 points = ₹200 gift voucher',
            'Points can be combined with other discounts',
            'Partial redemption allowed for any point amount',
          ],
        },
        {
          'title': 'Redemption Process',
          'points': [
            'Apply points during checkout in payment section',
            'See real-time discount calculation',
            'Points deducted immediately after order confirmation',
            'Failed orders: Points automatically restored',
            'Maximum points per order: 50% of order value',
            'Redemption history available in account dashboard',
          ],
        },
      ],
    },
    'special_offers': {
      'id': 'special_offers',
      'title': 'Special Offers & Promotions',
      'summary': 'Exclusive deals for loyalty members',
      'details': [
        {
          'title': 'Member-Only Promotions',
          'points': [
            'Double points weekends (announced monthly)',
            'Flash sales with extra points multiplier',
            'Seasonal bonus point campaigns',
            'Anniversary celebration rewards',
            'Holiday special point events',
            'Partner merchant exclusive offers',
          ],
        },
        {
          'title': 'Limited Time Offers',
          'points': [
            'Bonus points on specific menu items',
            'Referral bonus multipliers during campaigns',
            'Social media challenges with point rewards',
            'App review bonuses (first-time only)',
            'Survey completion rewards',
            'Event-based point earning opportunities',
          ],
        },
      ],
    },
    'account_management': {
      'id': 'account_management',
      'title': 'Account Management',
      'summary': 'Managing your loyalty program account',
      'details': [
        {
          'title': 'Point Tracking & History',
          'points': [
            'Real-time point balance in app dashboard',
            'Detailed transaction history available',
            'Point expiration reminders (if applicable)',
            'Monthly point summary statements',
            'Tier progress tracking with next tier goals',
            'Redemption history and usage analytics',
          ],
        },
        {
          'title': 'Account Settings',
          'points': [
            'Notification preferences for point updates',
            'Birthday date for special rewards',
            'Preferred communication channels',
            'Privacy settings for promotional offers',
            'Family account linking options',
            'Corporate account management features',
          ],
        },
      ],
    },
    'terms_conditions': {
      'id': 'terms_conditions',
      'title': 'Terms & Conditions',
      'summary': 'Rules governing the loyalty program',
      'details': [
        {
          'title': 'General Rules',
          'points': [
            'Points non-transferable between accounts',
            'No cash value for accumulated points',
            'Sipora reserves right to modify program terms',
            'Fraudulent activity leads to account suspension',
            'Program participation requires active account',
            'Terms may change with 30-day prior notice',
          ],
        },
        {
          'title': 'Account Inactivity',
          'points': [
            'Inactive for 12 months: Points expire',
            'Inactive for 24 months: Account deactivation',
            'Reactivation possible within 6 months of deactivation',
            'Lost points cannot be recovered after expiration',
            'Activity defined as any earning or redemption',
            'Inactivity warnings sent at 6 and 9 months',
          ],
        },
      ],
    },
  };

  static const List<String> sectionIds = [
    'program_overview',
    'earning_points',
    'reward_tiers',
    'redeeming_rewards',
    'special_offers',
    'account_management',
    'terms_conditions',
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
