// lib/widgets/rating_stars.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final Function(double)? onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor = const Color(0xFFFFC107),
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final starSize = isTablet ? size * 1.2 : size;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isHalfStar = rating > index && rating < starValue;

        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!.call(starValue)
              : null,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(1)),
            child: Icon(
              isHalfStar ? Icons.star_half : Icons.star,
              size: starSize,
              color: starValue <= rating
                  ? activeColor
                  : (isHalfStar ? activeColor : inactiveColor),
            ),
          ),
        );
      }),
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final double initialRating;
  final double size;
  final Function(double) onRatingSubmitted;
  final String? productId;
  final String? userId;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0,
    this.size = 24,
    required this.onRatingSubmitted,
    this.productId,
    this.userId,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  double _hoverRating = 0;
  double _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    _hoverRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final starSize = isTablet ? widget.size * 1.2 : widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;

            return GestureDetector(
              onTap: _isSubmitting ? null : () => _submitRating(starValue),
              onHorizontalDragUpdate: (details) {
                if (!_isSubmitting) {
                  setState(() {
                    _hoverRating = starValue;
                  });
                }
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _hoverRating = _selectedRating;
                });
              },
              child: MouseRegion(
                onEnter: (_) {
                  if (!_isSubmitting) {
                    setState(() {
                      _hoverRating = starValue;
                    });
                  }
                },
                onExit: (_) {
                  if (!_isSubmitting) {
                    setState(() {
                      _hoverRating = _selectedRating;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.symmetric(horizontal: context.w(2)),
                  child: Icon(
                    starValue <=
                            (_hoverRating > 0 ? _hoverRating : _selectedRating)
                        ? Icons.star
                        : Icons.star_border,
                    size: starSize,
                    color:
                        starValue <=
                            (_hoverRating > 0 ? _hoverRating : _selectedRating)
                        ? const Color(0xFFFFC107)
                        : theme.textMuted,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_isSubmitting)
          Padding(
            padding: EdgeInsets.only(top: context.h(8)),
            child: SizedBox(
              width: starSize,
              height: starSize,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                color: SiporaTheme.greenDark,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submitRating(double rating) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _selectedRating = rating;
      _hoverRating = rating;
    });

    await widget.onRatingSubmitted(rating);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
