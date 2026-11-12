import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../providers/user_provider.dart';
import '../../Setting_page/widgets/profile_information_page.dart';
import '../../theme/sipora_theme.dart';
import '../../services/wallet_service.dart';
import '../../Setting_page/widgets/wallet_recharge_page.dart';
import '../../services/storage_service.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  double _walletBalance = 0;
  bool _isLoadingWallet = true;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 6) return 'Dawn,';
    if (hour >= 6 && hour < 8) return 'Sunrise,';
    if (hour >= 8 && hour < 10) return 'Good Morning,';
    if (hour >= 10 && hour < 12) return 'Forenoon,';
    if (hour >= 12 && hour < 13) return 'Noon,';
    if (hour >= 13 && hour < 16) return 'Good Afternoon,';
    if (hour >= 16 && hour < 18) return 'Dusk,';
    if (hour >= 18 && hour < 20) return 'Twilight,';
    if (hour >= 20 && hour < 22) return 'Good Evening,';
    if (hour >= 22 && hour < 24) return 'Good Night,';
    if (hour >= 0 && hour < 4) return 'Midnight,';
    return 'Good Day,';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 6) return '🌅';
    if (hour >= 6 && hour < 8) return '🌄';
    if (hour >= 8 && hour < 10) return '☀️';
    if (hour >= 10 && hour < 12) return '🌤️';
    if (hour >= 12 && hour < 13) return '🍽️';
    if (hour >= 13 && hour < 16) return '☕';
    if (hour >= 16 && hour < 18) return '🌆';
    if (hour >= 18 && hour < 20) return '🌙';
    if (hour >= 20 && hour < 22) return '✨';
    if (hour >= 22 && hour < 24) return '🌃';
    if (hour >= 0 && hour < 4) return '🌌';
    return '👋';
  }

  String _formatWalletAmount(double amount) {
    if (amount >= 1000) {
      final thousands = amount / 1000;
      if (thousands == thousands.toInt()) {
        return '${thousands.toInt()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _isLoadingWallet = true);
    try {
      final wallet = await WalletService.fetchWallet();
      if (mounted && wallet != null) {
        setState(() => _walletBalance = wallet.currentBalance);
      }
    } catch (e) {
      // debugPrint('Error loading wallet balance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingWallet = false);
      }
    }
  }

  Future<void> _navigateToWallet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletRechargePage(
          initialBalance: _walletBalance,
          onBalanceUpdated: () {
            _loadWalletBalance();
          },
        ),
      ),
    );
    if (result == true) {
      _loadWalletBalance();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    final screenPadding = isSmall
        ? context.w(12)
        : (isTablet ? context.w(24) : context.w(20));
    final verticalPadding = isSmall
        ? context.h(12)
        : (isTablet ? context.h(16) : context.h(16));
    final greetingFontSize = isSmall
        ? context.sp(11)
        : (isTablet ? context.sp(14) : context.sp(13));
    final nameFontSize = isSmall
        ? context.sp(16)
        : (isTablet ? context.sp(20) : context.sp(18));
    final walletIconSize = isSmall
        ? context.w(16)
        : (isTablet ? context.w(20) : context.w(18));
    final walletAmountSize = isSmall
        ? context.sp(12)
        : (isTablet ? context.sp(15) : context.sp(14));
    final avatarSize = isSmall
        ? context.w(36)
        : (isTablet ? context.w(48) : context.w(42));
    final backgroundImageSize = isSmall
        ? context.w(70)
        : (isTablet ? context.w(95) : context.w(85));
    const logoLeftDistance = -15.0;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.userData;
        final firstName = user?['first_name'] ?? '';
        final lastName = user?['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isEmpty ? 'Sipora User' : fullName;
        final avatarUrl = user?['avataricons'];

        final combinedText = '$displayName • Every Sip Rewards You. ☕';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              color: SiporaTheme.greenDark,
              padding: EdgeInsets.symmetric(
                horizontal: screenPadding,
                vertical: verticalPadding,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isSmall
                          ? context.w(28)
                          : (isTablet ? context.w(40) : context.w(35)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$_greeting ',
                                style: TextStyle(
                                  fontSize: greetingFontSize,
                                  color: SiporaTheme.greenPill,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _greetingEmoji,
                                style: TextStyle(fontSize: greetingFontSize),
                              ),
                            ],
                          ),
                          SiporaMarquee(
                            text: combinedText,
                            style: TextStyle(
                              fontSize: nameFontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            speed: 40.0,
                            gap: 64.0,
                          ),
                        ],
                      ),
                    ),

                    // ── Wallet chip ─────────────────────────────────────────
                    GestureDetector(
                      onTap: _navigateToWallet,
                      child: Container(
                        margin: EdgeInsets.only(
                          right: isSmall ? context.w(8) : context.w(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? context.w(8) : context.w(12),
                          vertical: isSmall ? context.h(4) : context.h(6),
                        ),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(context.r(20)),
                          border: Border.all(
                            color: SiporaTheme.greenLight.withValues(
                              alpha: 0.5,
                            ),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: SiporaTheme.greenPill,
                              size: walletIconSize,
                            ),
                            SizedBox(width: context.w(4)),
                            if (_isLoadingWallet)
                              SizedBox(
                                width: walletIconSize * 0.8,
                                height: walletIconSize * 0.8,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SiporaTheme.greenPill,
                                ),
                              )
                            else
                              Text(
                                '₹${_formatWalletAmount(_walletBalance)}',
                                style: TextStyle(
                                  fontSize: walletAmountSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Avatar ──────────────────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileInformationPage(),
                          ),
                        ).then((_) {
                          userProvider.refreshUser();
                        });
                      },
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SiporaTheme.greenLight,
                            width: isSmall ? 1.5 : 2.0,
                          ),
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderAvatar(avatarSize),
                                )
                              : _buildPlaceholderAvatar(avatarSize),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: logoLeftDistance,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LogoImage(size: backgroundImageSize),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar(double size) {
    return Container(
      color: SiporaTheme.greenMid,
      child: Icon(
        Icons.person,
        color: SiporaTheme.greenLight,
        size: size * 0.6,
      ),
    );
  }
}

// ─── Logo Image Widget ──────────────────────────────────────────────────────
class _LogoImage extends StatefulWidget {
  final double size;
  const _LogoImage({required this.size});

  @override
  State<_LogoImage> createState() => _LogoImageState();
}

class _LogoImageState extends State<_LogoImage> {
  bool _loaded = false;
  bool _error = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/sipora_logo.png'), context)
        .then((_) {
          if (mounted) setState(() => _loaded = true);
        })
        .catchError((e) {
          if (mounted) setState(() => _error = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Icon(
        Icons.local_cafe,
        size: widget.size * 0.6,
        color: SiporaTheme.gold.withValues(alpha: 0.3),
      );
    }
    if (!_loaded) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SiporaTheme.gold,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image(
        image: const AssetImage('assets/images/sipora_logo.png'),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SiporaMarquee — reliable left-to-right infinite scroll using Ticker
// ═══════════════════════════════════════════════════════════════════════════════

class SiporaMarquee extends StatefulWidget {
  const SiporaMarquee({
    super.key,
    required this.text,
    required this.style,
    this.speed = 40.0,
    this.gap = 60.0,
    this.pauseDuration = const Duration(seconds: 1),
  });

  final String text;
  final TextStyle style;
  final double speed;
  final double gap;
  final Duration pauseDuration;

  @override
  State<SiporaMarquee> createState() => _SiporaMarqueeState();
}

class _SiporaMarqueeState extends State<SiporaMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _offset = 0.0;
  DateTime? _lastTick;
  double _textWidth = 0.0;
  double _containerWidth = 0.0;
  bool _pausing = true;
  Duration _pauseElapsed = Duration.zero;

  bool get _needsScroll => _textWidth > _containerWidth;
  double get _unit => _textWidth + widget.gap;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(SiporaMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _textWidth = 0;
      _offset = 0;
      _pausing = true;
      _pauseElapsed = Duration.zero;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final now = DateTime.now();
    final dt = _lastTick == null ? Duration.zero : now.difference(_lastTick!);
    _lastTick = now;

    if (_pausing) {
      _pauseElapsed += dt;
      if (_pauseElapsed >= widget.pauseDuration) {
        _pausing = false;
      }
      return;
    }

    final delta = widget.speed * dt.inMicroseconds / 1e6;
    setState(() {
      _offset = (_offset + delta) % _unit;
    });
  }

  double _measureTextWidth() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final measuredWidth = _measureTextWidth();

        if (measuredWidth != _textWidth || availableWidth != _containerWidth) {
          _textWidth = measuredWidth;
          _containerWidth = availableWidth;

          if (_needsScroll) {
            if (!_ticker.isActive) {
              _offset = 0;
              _pausing = true;
              _pauseElapsed = Duration.zero;
              _lastTick = null;
              _ticker.start();
            }
          } else {
            if (_ticker.isActive) _ticker.stop();
            _offset = 0;
          }
        }

        final height = (widget.style.fontSize ?? 16) * 1.5;

        if (!_needsScroll) {
          return SizedBox(
            height: height,
            width: availableWidth,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        return SizedBox(
          height: height,
          width: availableWidth,
          child: ClipRect(
            child: CustomPaint(
              painter: _MarqueePainter(
                text: widget.text,
                style: widget.style,
                offset: _offset,
                textWidth: _textWidth,
                gap: widget.gap,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarqueePainter extends CustomPainter {
  _MarqueePainter({
    required this.text,
    required this.style,
    required this.offset,
    required this.textWidth,
    required this.gap,
  });

  final String text;
  final TextStyle style;
  final double offset;
  final double textWidth;
  final double gap;

  double get _unit => textWidth + gap;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    final y = (size.height - tp.height) / 2;

    double x = -offset;
    while (x < size.width) {
      tp.paint(canvas, Offset(x, y));
      x += _unit;
    }
  }

  @override
  bool shouldRepaint(_MarqueePainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.text != text ||
      oldDelegate.textWidth != textWidth;
}
