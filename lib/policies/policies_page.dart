import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'widgets/terms_bottom_sheet.dart';
import 'widgets/privacy_policy.dart';
import 'widgets/shipping_delivery_policy.dart';
import 'widgets/refund_cancellation_policy.dart';
import 'widgets/loyalty_program_policy.dart';
import 'widgets/community_guidelines.dart';
import 'widgets/merchant_guidelines.dart';
import 'widgets/simple_policy_view.dart';

class PoliciesPage extends StatefulWidget {
  const PoliciesPage({super.key});

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final responsive = _ResponsiveValues.fromContext(context);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(responsive),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: isTablet
                  ? responsive.gridSpacing * 1.5
                  : responsive.gridSpacing,
            ),
            children: [
              // ========== Legal Policies Section ==========
              _buildSectionHeader(
                title: 'Legal Policies',
                icon: Icons.gavel_rounded,
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Terms governing your use of Sipora platform',
                iconColor: SiporaTheme.greenMid,
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TermsBottomSheet(),
                  );
                },
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we collect, use, and protect your data',
                iconColor: SiporaTheme.greenLight,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: PrivacyPolicy.title,
                        lastUpdated: PrivacyPolicy.lastUpdated,
                        sections: PrivacyPolicy.sections,
                        sectionIds: PrivacyPolicy.sectionIds,
                        getSectionTitle: PrivacyPolicy.getSectionTitle,
                        getSectionSummary: PrivacyPolicy.getSectionSummary,
                        getSectionDetails: PrivacyPolicy.getSectionDetails,
                        getSectionIcon: _getPrivacyPolicyIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.gridSpacing * 2),

              // ========== Business Policies Section ==========
              _buildSectionHeader(
                title: 'Business Policies',
                icon: Icons.business_rounded,
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.local_shipping_outlined,
                title: 'Shipping & Delivery',
                subtitle: 'Delivery timelines and procedures',
                iconColor: SiporaTheme.greenMid,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: ShippingDeliveryPolicy.title,
                        lastUpdated: ShippingDeliveryPolicy.lastUpdated,
                        sections: ShippingDeliveryPolicy.sections,
                        sectionIds: ShippingDeliveryPolicy.sectionIds,
                        getSectionTitle: ShippingDeliveryPolicy.getSectionTitle,
                        getSectionSummary:
                            ShippingDeliveryPolicy.getSectionSummary,
                        getSectionDetails:
                            ShippingDeliveryPolicy.getSectionDetails,
                        getSectionIcon: _getShippingPolicyIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.currency_rupee_outlined,
                title: 'Refund & Cancellation',
                subtitle: 'Refund procedures and cancellation rules',
                iconColor: SiporaTheme.greenLight,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: RefundCancellationPolicy.title,
                        lastUpdated: RefundCancellationPolicy.lastUpdated,
                        sections: RefundCancellationPolicy.sections,
                        sectionIds: RefundCancellationPolicy.sectionIds,
                        getSectionTitle:
                            RefundCancellationPolicy.getSectionTitle,
                        getSectionSummary:
                            RefundCancellationPolicy.getSectionSummary,
                        getSectionDetails:
                            RefundCancellationPolicy.getSectionDetails,
                        getSectionIcon: _getRefundPolicyIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.card_giftcard_outlined,
                title: 'Loyalty Program',
                subtitle: 'Terms for rewards and loyalty points',
                iconColor: SiporaTheme.greenMid,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: LoyaltyProgramPolicy.title,
                        lastUpdated: LoyaltyProgramPolicy.lastUpdated,
                        sections: LoyaltyProgramPolicy.sections,
                        sectionIds: LoyaltyProgramPolicy.sectionIds,
                        getSectionTitle: LoyaltyProgramPolicy.getSectionTitle,
                        getSectionSummary:
                            LoyaltyProgramPolicy.getSectionSummary,
                        getSectionDetails:
                            LoyaltyProgramPolicy.getSectionDetails,
                        getSectionIcon: _getLoyaltyPolicyIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.gridSpacing * 2),

              // ========== Community Guidelines Section ==========
              _buildSectionHeader(
                title: 'Community Guidelines',
                icon: Icons.groups_rounded,
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.people_outline,
                title: 'Community Standards',
                subtitle: 'Rules for respectful interaction',
                iconColor: SiporaTheme.greenLight,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: CommunityGuidelines.title,
                        lastUpdated: CommunityGuidelines.lastUpdated,
                        sections: CommunityGuidelines.sections,
                        sectionIds: CommunityGuidelines.sectionIds,
                        getSectionTitle: CommunityGuidelines.getSectionTitle,
                        getSectionSummary:
                            CommunityGuidelines.getSectionSummary,
                        getSectionDetails:
                            CommunityGuidelines.getSectionDetails,
                        getSectionIcon: _getCommunityGuidelinesIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),
              _buildPolicyCard(
                icon: Icons.store_outlined,
                title: 'Merchant Guidelines',
                subtitle: 'Rules for our merchant partners',
                iconColor: SiporaTheme.greenMid,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePolicyView(
                        title: MerchantGuidelines.title,
                        lastUpdated: MerchantGuidelines.lastUpdated,
                        sections: MerchantGuidelines.sections,
                        sectionIds: MerchantGuidelines.sectionIds,
                        getSectionTitle: MerchantGuidelines.getSectionTitle,
                        getSectionSummary: MerchantGuidelines.getSectionSummary,
                        getSectionDetails: MerchantGuidelines.getSectionDetails,
                        getSectionIcon: _getMerchantGuidelinesIcon,
                      ),
                    ),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.gridSpacing * 3),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Premium AppBar ----
  PreferredSizeWidget _buildAppBar(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: Padding(
        padding: EdgeInsets.only(left: responsive.screenPadding),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: responsive.avatarSize,
              height: responsive.avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: responsive.iconSize - 6,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Policies',
        style: TextStyle(
          fontSize: responsive.titleFontSize - 2,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.2,
        ),
      ),
      // Removed the actions section with refresh button
    );
  }

  // ---- Section Header (UPPERCASE, letter-spaced, green mid) ----
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required _ResponsiveValues responsive,
  }) {
    final theme = context.siporaTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.screenPadding,
        responsive.gridSpacing * 2,
        responsive.screenPadding,
        responsive.gridSpacing * 1,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: responsive.fontSize - 2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: theme.greenMid,
        ),
      ),
    );
  }

  // ---- Policy Card ----
  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required _ResponsiveValues responsive,
  }) {
    final theme = context.siporaTheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive.screenPadding,
        vertical: responsive.gridSpacing / 2,
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        color: theme.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(responsive.cardRadius),
          child: Container(
            padding: EdgeInsets.all(responsive.cardPadding - 2),
            decoration: BoxDecoration(
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(responsive.cardRadius),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: responsive.iconSize + 4,
                  height: responsive.iconSize + 4,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: responsive.iconSize,
                  ),
                ),
                SizedBox(width: responsive.gridSpacing * 1.5),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: responsive.titleFontSize - 6,
                          fontWeight: FontWeight.w600,
                          color: theme.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: responsive.gridSpacing * 0.3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: responsive.fontSize - 2,
                          color: theme.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: responsive.gridSpacing),

                // Arrow Icon
                Container(
                  padding: EdgeInsets.all(responsive.gridSpacing * 0.5),
                  decoration: BoxDecoration(
                    color: theme.greenBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: responsive.iconSize - 10,
                    color: theme.greenMid,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Icon functions for each policy type
  IconData _getPrivacyPolicyIcon(String sectionId) {
    switch (sectionId) {
      case 'data_collection':
        return Icons.download_outlined;
      case 'data_usage':
        return Icons.settings_applications_outlined;
      case 'data_sharing':
        return Icons.share_outlined;
      case 'data_protection':
        return Icons.security_outlined;
      case 'user_rights':
        return Icons.gavel_outlined;
      case 'data_retention':
        return Icons.schedule_outlined;
      case 'legal_compliance':
        return Icons.balance;
      default:
        return Icons.privacy_tip_outlined;
    }
  }

  IconData _getShippingPolicyIcon(String sectionId) {
    switch (sectionId) {
      case 'delivery_areas':
        return Icons.location_on_outlined;
      case 'delivery_timeframes':
        return Icons.schedule_outlined;
      case 'delivery_charges':
        return Icons.currency_rupee_outlined;
      case 'order_tracking':
        return Icons.gps_fixed_outlined;
      case 'delivery_requirements':
        return Icons.assignment_outlined;
      case 'delivery_issues':
        return Icons.error_outline;
      case 'restrictions':
        return Icons.block_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  IconData _getRefundPolicyIcon(String sectionId) {
    switch (sectionId) {
      case 'cancellation_policy':
        return Icons.cancel_outlined;
      case 'refund_policy':
        return Icons.refresh;
      case 'refund_process':
        return Icons.sync_outlined;
      case 'refund_exceptions':
        return Icons.block_outlined;
      case 'dispute_resolution':
        return Icons.handshake_outlined;
      case 'compensation_policy':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.currency_rupee_outlined;
    }
  }

  IconData _getLoyaltyPolicyIcon(String sectionId) {
    switch (sectionId) {
      case 'program_overview':
        return Icons.star_outline;
      case 'earning_points':
        return Icons.add_circle_outline;
      case 'reward_tiers':
        return Icons.trending_up_outlined;
      case 'redeeming_rewards':
        return Icons.redeem_outlined;
      case 'special_offers':
        return Icons.local_offer_outlined;
      case 'account_management':
        return Icons.manage_accounts_outlined;
      case 'terms_conditions':
        return Icons.description_outlined;
      default:
        return Icons.card_giftcard_outlined;
    }
  }

  IconData _getCommunityGuidelinesIcon(String sectionId) {
    switch (sectionId) {
      case 'community_standards':
        return Icons.people_outline;
      case 'user_conduct':
        return Icons.person_outline;
      case 'review_guidelines':
        return Icons.rate_review_outlined;
      case 'prohibited_activities':
        return Icons.block_outlined;
      case 'delivery_partner_interaction':
        return Icons.delivery_dining_outlined;
      case 'dispute_resolution':
        return Icons.handshake_outlined;
      case 'consequences':
        return Icons.warning_outlined;
      default:
        return Icons.people_outline;
    }
  }

  IconData _getMerchantGuidelinesIcon(String sectionId) {
    switch (sectionId) {
      case 'onboarding_requirements':
        return Icons.app_registration_outlined;
      case 'operational_standards':
        return Icons.settings_outlined;
      case 'menu_management':
        return Icons.restaurant_menu_outlined;
      case 'order_fulfillment':
        return Icons.inventory_2_outlined;
      case 'customer_service':
        return Icons.support_agent_outlined;
      case 'technology_integration':
        return Icons.devices_outlined;
      case 'performance_metrics':
        return Icons.analytics_outlined;
      case 'compliance_requirements':
        return Icons.verified_outlined;
      default:
        return Icons.store_outlined;
    }
  }
}

/// Helper class to cache responsive values for better performance
class _ResponsiveValues {
  final double screenPadding;
  final double gridSpacing;
  final double iconSize;
  final double fontSize;
  final double titleFontSize;
  final double cardRadius;
  final double cardPadding;
  final double avatarSize;

  _ResponsiveValues({
    required this.screenPadding,
    required this.gridSpacing,
    required this.iconSize,
    required this.fontSize,
    required this.titleFontSize,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
  });

  factory _ResponsiveValues.fromContext(BuildContext context) {
    return _ResponsiveValues(
      screenPadding: ResponsiveConstants.getScreenPadding(context),
      gridSpacing: ResponsiveConstants.getGridSpacing(context),
      iconSize: ResponsiveConstants.getIconSize(context),
      fontSize: ResponsiveConstants.getFontSize(context),
      titleFontSize: ResponsiveConstants.getTitleFontSize(context),
      cardRadius: ResponsiveConstants.getCardBorderRadius(context),
      cardPadding: ResponsiveConstants.getCardPadding(context),
      avatarSize: ResponsiveConstants.getAvatarSize(context),
    );
  }
}
