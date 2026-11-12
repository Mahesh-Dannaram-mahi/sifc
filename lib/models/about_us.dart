import 'package:flutter/material.dart';

// ---------- Sipora Café Theme (Green) ----------
class SiporaTheme {
  static const Color greenDark = Color(0xFF2D5016);
  static const Color greenMid = Color(0xFF3D6B1E);
  static const Color greenLight = Color(0xFF5A8A2E);
  static const Color greenBg = Color(0xFFEFF5E8);
  static const Color greenSurface = Color(0xFFF7FAF2);
  static const Color greenPill = Color(0xFF7ECC4A);

  static const Color cream = Color(0xFFFAFAF7);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static const Color textDark = Color(0xFF1A2810);
  static const Color textMuted = Color(0xFF6B7B5A);

  static const Color border = Color(0xFFD4E0C4);

  static const Color gold = Color(0xFFC8960C);
  static const Color goldText = Color(0xFF8A6400);
  static const Color goldBorder = Color(0xFFE8C64A);
  static const Color goldBg = Color(0xFFFDF6E3);

  static const Color red = Color(0xFFC0392B);
  static const Color redBg = Color(0xFFFDECEA);
  static const Color redBorder = Color(0xFFF0C4C0);
}

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutUsPage(),
    );
  }
}

class _AboutUsPageState extends State<AboutUsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _activeTab = 'vision';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.9;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: SiporaTheme.cardWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header with drag handle and close button
            _buildHeader(context),
            
            // Scrollable content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(context),
                        const SizedBox(height: 40),
                        _buildAboutSiporaSection(context),
                        const SizedBox(height: 40),
                        _buildMissionVisionSection(context),
                        const SizedBox(height: 40),
                        _buildFeaturesSection(context),
                        const SizedBox(height: 40),
                        _buildFounderSection(context),
                        const SizedBox(height: 40),
                        _buildCoreValuesSection(context),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Us',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SiporaTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Discover Our Story',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SiporaTheme.textMuted,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SiporaTheme.cardWhite.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: SiporaTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final stats = [
      {
        'value': '500+',
        'label': 'Outlets Onboarded',
        'icon': Icons.business,
      },
      {
        'value': '100K+',
        'label': 'Happy Customers',
        'icon': Icons.people,
      },
      {
        'value': '15+',
        'label': 'Cities',
        'icon': Icons.location_on,
      },
      {
        'value': '98%',
        'label': 'Satisfaction Rate',
        'icon': Icons.star,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SiporaTheme.greenBg,
            SiporaTheme.cardWhite,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SiporaTheme.greenMid.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.textMuted.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo and Brand Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_cafe,
                  size: 28,
                  color: SiporaTheme.cardWhite,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sipora',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SiporaTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main Heading
          Text(
            "India's First Dedicated Loyalty Platform for Tea Shops & Cafés",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SiporaTheme.textDark,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Sipora is India\'s first dedicated loyalty and engagement platform built exclusively for tea shops and cafés — turning every visit into a reason to come back.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SiporaTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SiporaTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SiporaTheme.greenBg.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      color: SiporaTheme.greenDark,
                      size: 18,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stat['value'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SiporaTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        stat['label'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SiporaTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSiporaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Sipora',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SiporaTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: SiporaTheme.greenDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SiporaTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SiporaTheme.greenBg.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.textMuted.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sipora is India\'s first dedicated loyalty and engagement platform built exclusively for tea shops and cafés.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: SiporaTheme.textDark,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In a country where chai and coffee are part of everyday life, millions of customers visit outlets daily — but most businesses still struggle with one key problem: customer retention.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: SiporaTheme.textDark,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sipora was created to solve exactly that. We bridge the gap between customers and outlets by turning every visit into a reason to come back.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: SiporaTheme.textDark,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionVisionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Vision & Mission',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SiporaTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tab Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 'vision'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 'vision'
                        ? SiporaTheme.greenDark
                        : SiporaTheme.cardWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Vision',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _activeTab == 'vision'
                          ? SiporaTheme.cardWhite
                          : SiporaTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 'mission'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 'mission'
                        ? SiporaTheme.greenDark
                        : SiporaTheme.cardWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Mission',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _activeTab == 'mission'
                          ? SiporaTheme.cardWhite
                          : SiporaTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Vision or Mission Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _activeTab == 'vision'
              ? _buildVisionCard()
              : _buildMissionCard(),
        ),
      ],
    );
  }

  Widget _buildVisionCard() {
    return Container(
      key: const ValueKey('vision'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SiporaTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SiporaTheme.greenMid.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.textMuted.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: SiporaTheme.greenDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Our Vision',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SiporaTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'To transform India\'s tea and café ecosystem by making customer loyalty simple, digital, and effective for every outlet — from small tea stalls to growing café brands.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: SiporaTheme.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      key: const ValueKey('mission'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SiporaTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SiporaTheme.greenMid.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.textMuted.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: SiporaTheme.greenDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Our Mission',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SiporaTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildMissionItems([
            'To help outlets build a loyal customer base',
            'To ensure customers always find quality & hygiene-assured places',
            'To replace outdated loyalty methods with a smart, scalable digital solution',
          ]),
        ],
      ),
    );
  }

  List<Widget> _buildMissionItems(List<String> items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.check_circle,
                color: SiporaTheme.greenDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: SiporaTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      {
        'icon': Icons.smartphone,
        'title': '100% Tech-Enabled',
        'desc': 'App-based ecosystem connecting customers, outlets & operations',
        'trend': 'Digital First',
      },
      {
        'icon': Icons.card_giftcard,
        'title': 'Dedicated Loyalty Platform',
        'desc': 'Exclusively built for tea shops and cafés',
        'trend': 'Industry First',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Scalable Model',
        'desc': 'Smart system designed for outlets of all sizes',
        'trend': 'Rapid Expansion',
      },
      {
        'icon': Icons.people,
        'title': 'Customer Retention',
        'desc': 'Turn every visit into a reason to come back',
        'trend': 'High Retention',
      },
      {
        'icon': Icons.track_changes,
        'title': 'Simple & Effective',
        'desc': 'Replace outdated loyalty methods with a smart digital solution',
        'trend': 'Easy to Adopt',
      },
      {
        'icon': Icons.verified,
        'title': 'Quality Assurance',
        'desc': 'Customers always find quality & hygiene-assured places',
        'trend': 'Trusted Network',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What Sets Us Apart',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SiporaTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'re not following the industry — we\'re leading the change in the tea and café ecosystem',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: SiporaTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: features.map((feature) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SiporaTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SiporaTheme.greenBg.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: SiporaTheme.textMuted.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: SiporaTheme.greenDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SiporaTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: SiporaTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenMid.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feature['trend'] as String,
                          style: const TextStyle(
                            color: SiporaTheme.greenMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildFounderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet the Founder',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SiporaTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: SiporaTheme.greenDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: SiporaTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.textMuted.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: SiporaTheme.greenBg.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Founder Image Section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SiporaTheme.greenDark.withValues(alpha: 0.8),
                        SiporaTheme.greenMid.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: SiporaTheme.cardWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SiporaTheme.greenBg,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SiporaTheme.textMuted.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Sipora_Logo.jpeg',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        SiporaTheme.greenDark,
                                        SiporaTheme.greenLight,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 56,
                                        color: SiporaTheme.cardWhite,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pavan Kumar',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: SiporaTheme.cardWhite,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Founder Info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pavan Kumar',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: SiporaTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ex-Banker turned Tea & Coffee Entrepreneur',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SiporaTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Pavan Kumar, an Ex-Banker who served as a Deputy Manager, chose to step away from a stable career to pursue his true passion — tea and coffee.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: SiporaTheme.textDark,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'Unlike many in the industry, his journey is backed not just by passion, but by deep expertise. He is a Certified Tea Taster & Blender and a Certified Barista, bringing both art and science into every cup.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: SiporaTheme.textDark,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Quote Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: SiporaTheme.greenDark,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        '"Through my journey, I identified a critical gap in the industry — the lack of customer retention and meaningful engagement between outlets and customers."',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: SiporaTheme.textDark,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'As the founder behind brands like Boring Banker Café, South Indian Filter Coffee, Desi Chai, and CommuniTea, Pavan has been closely involved in building and scaling tea and coffee businesses at the ground level.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: SiporaTheme.textDark,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Second Quote Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SiporaTheme.greenLight.withValues(alpha: 0.2),
                            SiporaTheme.cardWhite,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: SiporaTheme.greenMid,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        '"Sipora is not just an idea — it is a vision shaped by real industry experience, built to solve real problems. It\'s a solution designed to transform how tea and coffee outlets connect with their customers, build loyalty, and grow sustainably."',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: SiporaTheme.textDark,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Founder achievements grid
                    Column(
                      children: [
                        _buildAchievementItem(context, Icons.work, 'Ex-Banker, Deputy Manager'),
                        _buildAchievementItem(context, Icons.local_cafe, 'Certified Tea Taster & Blender'),
                        _buildAchievementItem(context, Icons.restaurant, 'Certified Barista'),
                        _buildAchievementItem(context, Icons.trending_up, 'Serial Entrepreneur in Tea & Coffee'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SiporaTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SiporaTheme.greenBg.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.textMuted.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SiporaTheme.greenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: SiporaTheme.greenDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SiporaTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreValuesSection(BuildContext context) {
    final coreValues = [
      {
        'icon': Icons.favorite,
        'title': 'Customer First',
        'desc': 'Every decision revolves around customer experience',
        'color': SiporaTheme.greenDark,
      },
      {
        'icon': Icons.restaurant,
        'title': 'Taste Without Compromise',
        'desc': 'Authentic flavor in every cup',
        'color': SiporaTheme.greenMid,
      },
      {
        'icon': Icons.bolt,
        'title': 'Tech-Driven Excellence',
        'desc': 'Smart solutions power accuracy & growth',
        'color': SiporaTheme.greenDark,
      },
      {
        'icon': Icons.business,
        'title': 'Entrepreneur Empowerment',
        'desc': 'Supporting outlets to build a loyal customer base',
        'color': SiporaTheme.greenMid,
      },
      {
        'icon': Icons.balance,
        'title': 'Integrity & Transparency',
        'desc': 'Ethical practices and honest business',
        'color': SiporaTheme.greenDark,
      },
      {
        'icon': Icons.lightbulb,
        'title': 'Innovation as a Habit',
        'desc': 'Continuous improvement in everything we do',
        'color': SiporaTheme.greenMid,
      },
      {
        'icon': Icons.groups,
        'title': 'Community & Culture',
        'desc': 'Chai and coffee as shared connecting experiences',
        'color': SiporaTheme.greenDark,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Core Values',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SiporaTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The principles that guide every decision we make',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: SiporaTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: coreValues.length,
          itemBuilder: (context, index) {
            final value = coreValues[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SiporaTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SiporaTheme.textMuted.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: SiporaTheme.greenBg.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (value['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      value['icon'] as IconData,
                      color: value['color'] as Color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      value['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SiporaTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      value['desc'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: SiporaTheme.textMuted,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}