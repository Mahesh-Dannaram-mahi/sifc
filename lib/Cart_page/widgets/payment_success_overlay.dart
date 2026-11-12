import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/sipora_theme.dart';

class PaymentSuccessResult {
  final String orderId;
  final int? invoiceId;

  const PaymentSuccessResult({required this.orderId, this.invoiceId});
}

class PaymentSuccessOverlay extends StatefulWidget {
  final PaymentSuccessResult result;
  final VoidCallback onDone;

  const PaymentSuccessOverlay({
    super.key,
    required this.result,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentSuccessResult result,
    required VoidCallback onDone,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, _, __) =>
          PaymentSuccessOverlay(result: result, onDone: onDone),
      transitionBuilder: (ctx, animation, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<PaymentSuccessOverlay> createState() => _PaymentSuccessOverlayState();
}

class _PaymentSuccessOverlayState extends State<PaymentSuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _checkController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _playPaymentSound();
  }

  Future<void> _playPaymentSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/payment_sound.mp3'));
    } catch (_) {
      // Sound asset may be missing in dev builds.
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.w(28)),
          padding: EdgeInsets.fromLTRB(
            context.w(24),
            context.h(28),
            context.w(24),
            context.h(20),
          ),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(context.r(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(scale: scale, child: child);
                },
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _checkController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: context.w(88),
                    height: context.w(88),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: context.w(52),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.h(20)),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: context.sp(20),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                ),
              ),
              SizedBox(height: context.h(8)),
              Text(
                'Your order has been placed.',
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: theme.textMuted,
                ),
              ),
              SizedBox(height: context.h(16)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(12),
                ),
                decoration: BoxDecoration(
                  color: theme.greenBg,
                  borderRadius: BorderRadius.circular(context.r(12)),
                  border: Border.all(color: theme.border, width: 1.w),
                ),
                child: Column(
                  children: [
                    Text(
                      'Order ID',
                      style: TextStyle(
                        fontSize: context.sp(12),
                        color: theme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      widget.result.orderId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w700,
                        color: SiporaTheme.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: context.h(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(22)),
                    ),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
