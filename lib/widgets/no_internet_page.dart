import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/connectivity_service.dart';
import '../theme/sipora_theme.dart';
import '../utils/responsive_constants.dart';
import '../main.dart' show MyApp; // Move import to the top

class NoInternetPage extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  const NoInternetPage({super.key, this.onRetry, this.onExit});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);

    return Scaffold(
      backgroundColor: theme.cream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated WiFi Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: isTablet ? 160 : 120,
                      height: isTablet ? 160 : 120,
                      decoration: BoxDecoration(
                        color: theme.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.red.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.wifi_off,
                        size: isTablet ? 80 : 60,
                        color: theme.red.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Title
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: titleFontSize + 4,
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Please check your internet connection and try again.',
                style: TextStyle(fontSize: fontSize, color: theme.textMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Action Buttons
              Column(
                children: [
                  // Retry Button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        if (widget.onRetry != null) {
                          widget.onRetry!();
                        } else {
                          final navigator = Navigator.of(
                            context,
                          ); // capture before await
                          final hasInternet = await ConnectivityService.instance
                              .hasInternetConnection();
                          if (hasInternet && mounted) {
                            navigator.pushReplacement(
                              MaterialPageRoute(builder: (_) => const MyApp()),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SiporaTheme.gold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Turn On WiFi Button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ConnectivityService.instance.openWifiSettings();
                      },
                      icon: Icon(Icons.wifi, size: buttonFontSize + 2),
                      label: Text(
                        'Turn On WiFi',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SiporaTheme.greenMid,
                        side: BorderSide(color: SiporaTheme.greenMid),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mobile Data Button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ConnectivityService.instance
                            .openMobileDataSettings();
                      },
                      icon: Icon(
                        Icons.signal_cellular_alt,
                        size: buttonFontSize + 2,
                      ),
                      label: Text(
                        'Turn On Mobile Data',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SiporaTheme.greenMid,
                        side: BorderSide(color: SiporaTheme.greenMid),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Exit App Button
                  TextButton.icon(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      if (widget.onExit != null) {
                        widget.onExit!();
                      } else {
                        if (mounted) {
                          SystemNavigator.pop();
                        }
                      }
                    },
                    icon: Icon(Icons.exit_to_app, color: theme.textMuted),
                    label: Text(
                      'Exit App',
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        color: theme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tips
              Container(
                padding: EdgeInsets.all(screenPadding),
                decoration: BoxDecoration(
                  color: SiporaTheme.goldBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(
                    color: SiporaTheme.gold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: SiporaTheme.goldText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SiporaTheme.goldText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Check your WiFi router\n• Enable mobile data\n• Move to a better signal area\n• Restart your network connection',
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        color: SiporaTheme.goldText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
