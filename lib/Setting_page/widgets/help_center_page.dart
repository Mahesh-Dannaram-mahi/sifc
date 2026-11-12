import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/user_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'ticket_success_page.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';

  bool _isLoading = false;
  int? _expandedFAQIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<SupportCategory> _categories = [
    SupportCategory(
      id: 'general',
      name: 'General Inquiry',
      icon: Icons.help_outline_rounded,
    ),
    SupportCategory(
      id: 'technical',
      name: 'Technical Support',
      icon: Icons.build_outlined,
    ),
    SupportCategory(
      id: 'billing',
      name: 'Billing Question',
      icon: Icons.receipt_outlined,
    ),
    SupportCategory(
      id: 'feature',
      name: 'Feature Request',
      icon: Icons.lightbulb_outline,
    ),
  ];

  final List<FAQ> _faqs = [
    FAQ(
      question: 'What is SIPORA?',
      answer:
          'SIPORA is a loyalty and customer engagement platform built exclusively for tea, coffee, and café outlets.',
    ),
    FAQ(
      question: 'How does SIPORA work?',
      answer:
          'Simply scan QR codes at participating outlets to earn points, rewards, and cashback offers.',
    ),
    FAQ(
      question: 'Is SIPORA free to use?',
      answer:
          'Yes, SIPORA is completely free for customers. No hidden charges or fees.',
    ),
    FAQ(
      question: 'How can I become a partner?',
      answer:
          'Contact our team through the website or app to onboard your outlet.',
    ),
    FAQ(
      question: 'How to report an issue?',
      answer: 'Use the "create support ticket" form above to report the issue.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userInfo = await UserService.getUserBasicInfo();
      if (userInfo != null && mounted) {
        setState(() {
          _nameController.text = userInfo['name'] ?? '';
          _emailController.text = userInfo['email'] ?? '';
          _phoneController.text = userInfo['phone'] ?? '';
        });
      }
    } catch (e) {
    
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = ResponsiveConstants.isTablet(context);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(isTablet),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(isTablet),
                _buildQuickStats(isTablet),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveConstants.getScreenPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 3,
                      ),
                      _buildSectionTitle(
                        'Contact Options',
                        'Get in touch through your preferred channel',
                      ),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 2,
                      ),
                      _buildContactOptions(isTablet),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 5,
                      ),
                      _buildSectionTitle(
                        'Create Support Ticket',
                        'We\'ll respond within 24 hours',
                      ),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 2,
                      ),
                      _buildTicketForm(isTablet),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 5,
                      ),
                      _buildSectionTitle(
                        'Frequently Asked Questions',
                        'Quick answers to common questions',
                      ),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 2,
                      ),
                      _buildFAQSection(isTablet),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) * 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isTablet) {
    final theme = context.siporaTheme;
    final avatarSize = ResponsiveConstants.getAvatarSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

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
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize - 7,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Help Center',
        style: TextStyle(
          fontSize: titleFontSize - 2,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
        ),
      ),
      // No actions section with refresh button
    );
  }

  Widget _buildWelcomeBanner(bool isTablet) {
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final headingFontSize = ResponsiveConstants.getHeadingFontSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);

    return Container(
      margin: EdgeInsets.all(isTablet ? screenPadding * 1.5 : screenPadding),
      padding: EdgeInsets.all(isTablet ? screenPadding * 1.5 : screenPadding),
      decoration: SiporaTheme.gradientDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Assistance?',
                  style: TextStyle(
                    fontSize: isTablet
                        ? headingFontSize - 4
                        : headingFontSize - 6,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
                Text(
                  'Our support team is available 24/7 to help you with any questions or concerns.',
                  style: TextStyle(
                    fontSize: isTablet ? fontSize - 1 : fontSize - 2,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveConstants.getGridSpacing(context) * 2),
          Container(
            padding: EdgeInsets.all(isTablet ? iconSize - 6 : iconSize - 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: isTablet ? iconSize + 8 : iconSize + 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isTablet) {
    final screenPadding = ResponsiveConstants.getScreenPadding(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? screenPadding * 1.5 : screenPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Response Time',
              '< 24 hrs',
              Icons.schedule_rounded,
              SiporaTheme.greenLight,
              isTablet,
            ),
          ),
          SizedBox(width: ResponsiveConstants.getGridSpacing(context) * 1.5),
          Expanded(
            child: _buildStatCard(
              'Satisfaction Rate',
              '98%',
              Icons.thumb_up_rounded,
              SiporaTheme.greenDark,
              isTablet,
            ),
          ),
          SizedBox(width: ResponsiveConstants.getGridSpacing(context) * 1.5),
          Expanded(
            child: _buildStatCard(
              'Active Support',
              '24/7',
              Icons.headset_mic_rounded,
              SiporaTheme.greenLight,
              isTablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isTablet,
  ) {
    final theme = context.siporaTheme;
    final cardPadding = ResponsiveConstants.getCardPadding(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? cardPadding : cardPadding - 2),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(cardRadius - 2),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? iconSize - 16 : iconSize - 18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isTablet ? iconSize - 4 : iconSize - 6,
            ),
          ),
          SizedBox(height: ResponsiveConstants.getGridSpacing(context) * 0.75),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? titleFontSize - 4 : titleFontSize - 6,
              fontWeight: FontWeight.bold,
              color: theme.textDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: fontSize - 3, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize - 2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: SiporaTheme.greenMid,
          ),
        ),
        SizedBox(height: ResponsiveConstants.getGridSpacing(context) * 0.5),
        Text(
          subtitle,
          style: TextStyle(fontSize: fontSize - 3, color: theme.textMuted),
        ),
      ],
    );
  }

  Widget _buildContactOptions(bool isTablet) {
    final theme = context.siporaTheme;
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    final options = [
      ContactOption(
        icon: Icons.chat_rounded,
        title: 'Live Chat',
        description: 'Chat with our team',
        color: SiporaTheme.greenMid,
        action: () =>
            SiporaTheme.showSnackBar(context, 'Coming soon!', isError: false),
      ),
      ContactOption(
        icon: Icons.email_rounded,
        title: 'Email Support',
        description: 'support@sipora.com',
        color: SiporaTheme.greenLight,
        action: _launchEmail,
      ),
      ContactOption(
        icon: Icons.phone_rounded,
        title: 'Call Us',
        description: '+91 98765 43210',
        color: SiporaTheme.greenMid,
        action: _launchPhone,
      ),
      ContactOption(
        icon: Icons.chat,
        title: 'WhatsApp',
        description: 'Message on WhatsApp',
        color: SiporaTheme.greenLight,
        action: _launchWhatsApp,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: ResponsiveConstants.getGridSpacing(context) * 1.5,
        mainAxisSpacing: ResponsiveConstants.getGridSpacing(context) * 1.5,
        childAspectRatio: 1.5,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return GestureDetector(
          onTap: option.action,
          child: Container(
            padding: EdgeInsets.all(isTablet ? cardRadius : cardRadius - 2),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(cardRadius - 2),
              border: Border.all(color: theme.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: SiporaTheme.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isTablet ? iconSize - 16 : iconSize - 18,
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.color,
                    size: isTablet ? iconSize - 2 : iconSize - 4,
                  ),
                ),
                SizedBox(
                  height: ResponsiveConstants.getGridSpacing(context) * 0.75,
                ),
                Text(
                  option.title,
                  style: TextStyle(
                    fontSize: titleFontSize - 4,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
                Text(
                  option.description,
                  style: TextStyle(
                    fontSize: fontSize - 3,
                    color: theme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketForm(bool isTablet) {
    final theme = context.siporaTheme;
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final cardPadding = ResponsiveConstants.getCardPadding(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(
                isTablet ? cardPadding + 2 : cardPadding - 2,
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.greenBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                border: Border(
                  bottom: BorderSide(color: theme.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isTablet ? cardPadding - 4 : cardPadding - 6,
                    ),
                    decoration: BoxDecoration(
                      color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: SiporaTheme.greenDark,
                      size: 18,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveConstants.getGridSpacing(context) * 1.5,
                  ),
                  Expanded(
                    child: Text(
                      'Create Support Ticket',
                      style: TextStyle(
                        fontSize:
                            ResponsiveConstants.getTitleFontSize(context) - 4,
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? cardPadding + 4 : cardPadding),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                    isTablet: isTablet,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Name is required' : null,
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) * 2,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    isTablet: isTablet,
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Email is required';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v!)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) * 2,
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+91 XXXXXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isTablet: isTablet,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Phone number is required' : null,
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) * 2,
                  ),
                  _SmartDropdown(
                    value: _selectedCategory,
                    categories: _categories,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    isTablet: isTablet,
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) * 2,
                  ),
                  _buildTextField(
                    controller: _subjectController,
                    label: 'Subject',
                    hint: 'Brief summary of your issue',
                    icon: Icons.subject_rounded,
                    isTablet: isTablet,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Subject is required' : null,
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) * 2,
                  ),
                  _buildTextField(
                    controller: _messageController,
                    label: 'Message',
                    hint: 'Please provide detailed information...',
                    icon: Icons.message_outlined,
                    maxLines: 4,
                    isTablet: isTablet,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Message is required' : null,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(
                isTablet ? cardPadding + 2 : cardPadding - 2,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.border, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: SiporaTheme.primaryButtonStyle(
                    height: isTablet ? buttonHeight + 4 : buttonHeight - 4,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Ticket',
                          style: TextStyle(
                            fontSize: isTablet
                                ? buttonFontSize - 1
                                : buttonFontSize - 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isTablet,
    String? Function(String?)? validator,
  }) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 2,
            fontWeight: FontWeight.w500,
            color: theme.textDark,
          ),
        ),
        SizedBox(height: gridSpacing),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: fontSize - 1,
              color: theme.textMuted,
            ),
            prefixIcon: Icon(
              icon,
              size: ResponsiveConstants.getIconSize(context) - 6,
              color: theme.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context) - 2,
              ),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context) - 2,
              ),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context) - 2,
              ),
              borderSide: const BorderSide(
                color: SiporaTheme.greenMid,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context) - 2,
              ),
              borderSide: const BorderSide(color: SiporaTheme.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context) - 2,
              ),
              borderSide: const BorderSide(color: SiporaTheme.red, width: 2),
            ),
            filled: true,
            fillColor: theme.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.getScreenPadding(context),
              vertical: isTablet ? 16 : 12,
            ),
          ),
          validator: validator,
          style: TextStyle(
            fontSize: isTablet ? fontSize - 1 : fontSize - 2,
            color: theme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(bool isTablet) {
    final theme = context.siporaTheme;
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final cardPadding = ResponsiveConstants.getCardPadding(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        final isExpanded = _expandedFAQIndex == index;
        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveConstants.getGridSpacing(context),
          ),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(cardRadius - 4),
            border: Border.all(color: theme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(
                  () => _expandedFAQIndex = isExpanded ? null : index,
                ),
                borderRadius: BorderRadius.circular(cardRadius - 4),
                child: Padding(
                  padding: EdgeInsets.all(
                    isTablet ? cardPadding : cardPadding - 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          isTablet ? iconSize - 16 : iconSize - 18,
                        ),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: SiporaTheme.greenMid,
                          size: 16,
                        ),
                      ),
                      SizedBox(
                        width:
                            ResponsiveConstants.getGridSpacing(context) * 1.5,
                      ),
                      Expanded(
                        child: Text(
                          faq.question,
                          style: TextStyle(
                            fontSize: titleFontSize - 8,
                            fontWeight: FontWeight.w500,
                            color: theme.textDark,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                        color: SiporaTheme.greenMid,
                        size: iconSize - 6,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? cardPadding : cardPadding - 2,
                          0,
                          isTablet ? cardPadding : cardPadding - 2,
                          isTablet ? cardPadding : cardPadding - 2,
                        ),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: theme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/service-desk/support/create-ticket',
        ),
        headers: {'accept': 'application/json'},
        body: {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'ticket_type': _selectedCategory,
          'subject': _subjectController.text.trim(),
          'description': _messageController.text.trim(),
        },
      );
      if (response.statusCode == 200 && mounted) {
        _clearForm();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TicketSuccessPage()),
        );
      } else {
        throw Exception('Failed to submit ticket');
      }
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Failed to submit ticket. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategory = 'general');
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'support@sipora.com');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+919876543210');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/919876543210');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }
}

// ---------- Smart Dropdown ----------
class _SmartDropdown extends StatefulWidget {
  final String value;
  final List<SupportCategory> categories;
  final ValueChanged<String> onChanged;
  final bool isTablet;

  const _SmartDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  State<_SmartDropdown> createState() => _SmartDropdownState();
}

class _SmartDropdownState extends State<_SmartDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    const double itemHeight = 44.0;
    final double dropdownHeight = widget.categories.length * itemHeight;
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - position.dy - size.height - 16;
    final spaceAbove = position.dy - 16;
    final openAbove = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;

    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: openAbove
                  ? Offset(0, -(dropdownHeight + 6))
                  : Offset(0, size.height + 6),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: size.width,
                    decoration: BoxDecoration(
                      color: SiporaTheme.whiteLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SiporaTheme.greenMid,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SiporaTheme.greenDark.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.categories.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final category = entry.value;
                          final isSelected = category.id == widget.value;
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  widget.onChanged(category.id);
                                  _close();
                                },
                                child: Container(
                                  height: itemHeight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? SiporaTheme.greenBg
                                        : SiporaTheme.whiteLight,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: isSelected
                                            ? SiporaTheme.greenMid
                                            : SiporaTheme.textMutedLight,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? SiporaTheme.greenMid
                                                : SiporaTheme.textDarkLight,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: SiporaTheme.greenLight,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < widget.categories.length - 1)
                                Divider(
                                  height: 0,
                                  thickness: 0.5,
                                  color: SiporaTheme.borderLight,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    _fadeController.forward(from: 0);
    setState(() => _isOpen = true);
  }

  Future<void> _close() async {
    await _fadeController.reverse();
    _removeOverlay();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final selected = widget.categories.firstWhere((c) => c.id == widget.value);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: widget.isTablet ? 48 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SiporaTheme.greenBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen ? SiporaTheme.greenMid : theme.border,
              width: _isOpen ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected.icon,
                color: _isOpen ? SiporaTheme.greenMid : SiporaTheme.greenMid,
                size: iconSize - 4,
              ),
              SizedBox(
                width: ResponsiveConstants.getGridSpacing(context) * 1.5,
              ),
              Expanded(
                child: Text(
                  selected.name,
                  style: TextStyle(
                    fontSize: widget.isTablet ? fontSize - 1 : fontSize - 2,
                    fontWeight: _isOpen ? FontWeight.w600 : FontWeight.normal,
                    color: _isOpen ? SiporaTheme.greenMid : theme.textDark,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: SiporaTheme.greenMid,
                  size: iconSize - 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Models ----------
class SupportCategory {
  final String id;
  final String name;
  final IconData icon;
  SupportCategory({required this.id, required this.name, required this.icon});
}

class ContactOption {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback action;
  ContactOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.action,
  });
}

class FAQ {
  final String question;
  final String answer;
  FAQ({required this.question, required this.answer});
}
