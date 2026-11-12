// lib/widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onLikeToggled;
  final double size;
  final bool showCount;

  const LikeButton({
    super.key,
    required this.isLiked,
    this.likeCount = 0,
    this.onLikeToggled,
    this.size = 20,
    this.showCount = true,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
    if (oldWidget.likeCount != widget.likeCount) {
      _likeCount = widget.likeCount;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Animate
    _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _animationController.reverse();

    // Toggle like state locally for instant UI feedback
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Callback for actual API call
    widget.onLikeToggled?.call();

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final size = isTablet ? widget.size * 1.2 : widget.size;

    return GestureDetector(
      onTap: _handleLike,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: size,
                  color: _isLiked ? Colors.red : theme.textMuted,
                ),
                if (widget.showCount && _likeCount > 0) ...[
                  SizedBox(width: context.w(4)),
                  Text(
                    _formatLikeCount(_likeCount),
                    style: TextStyle(
                      fontSize: size * 0.6,
                      fontWeight: FontWeight.w600,
                      color: _isLiked ? Colors.red : theme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
