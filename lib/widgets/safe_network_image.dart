import 'package:flutter/material.dart';

class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  void _loadImage() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageInfo?.image.dispose();
      _imageInfo = null;
    });

    final imageProvider = NetworkImage(widget.imageUrl);
    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageStream!.addListener(
      ImageStreamListener(_imageListener, onError: _onError),
    );
  }

  void _imageListener(ImageInfo imageInfo, bool synchronousCall) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _imageInfo = imageInfo;
      });
    }
  }

  void _onError(Object exception, StackTrace? stackTrace) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_imageListener));
    _imageInfo?.image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_hasError) {
      child = widget.errorWidget ?? _buildDefaultErrorWidget();
    } else if (_isLoading) {
      child = widget.placeholder ?? _buildDefaultPlaceholder();
    } else if (_imageInfo != null) {
      child = RawImage(
        image: _imageInfo!.image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else {
      child = widget.placeholder ?? _buildDefaultPlaceholder();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }

    return child;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (widget.width ?? 50) * 0.4,
            color: Colors.grey[600],
          ),
          if (widget.height != null && widget.height! > 40)
            const SizedBox(height: 4),
          if (widget.height != null && widget.height! > 40)
            Text(
              'Image unavailable',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }
}

// Extension to easily replace NetworkImage with SafeNetworkImage in DecorationImage
extension SafeImageDecoration on DecorationImage {
  static DecorationImage safeNetworkImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    return DecorationImage(
      image: NetworkImage(imageUrl),
      fit: fit,
      onError: (error, stackTrace) {
      },
    );
  }
}
