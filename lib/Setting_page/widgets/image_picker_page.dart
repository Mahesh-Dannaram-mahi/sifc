import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/sipora_theme.dart';

class ImagePickerPage extends StatefulWidget {
  final File? currentImage;
  final String? currentImageUrl;
  final Function(File?) onImageSelected;

  const ImagePickerPage({
    super.key,
    this.currentImage,
    this.currentImageUrl,
    required this.onImageSelected,
  });

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isImageFromUrl = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
    _isImageFromUrl = widget.currentImage != null
        ? false
        : (widget.currentImageUrl != null &&
              widget.currentImageUrl!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(theme),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(SiporaThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.white,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SiporaTheme.greenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.textDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
          ),
          if (_selectedImage != null || _isImageFromUrl)
            TextButton(
              onPressed: _isLoading ? null : _saveImage,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _selectedImage != null ? 'Use New' : 'Use Current',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: SiporaTheme.greenDark,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(SiporaThemeExtension theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SiporaTheme.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _selectedImage != null
                    ? InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 3.0,
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    : (widget.currentImageUrl != null &&
                          widget.currentImageUrl!.isNotEmpty)
                    ? InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 3.0,
                        child: CachedNetworkImage(
                          imageUrl: widget.currentImageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(
                        Icons.close,
                        color: Colors.red[700],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (widget.currentImageUrl != null &&
                widget.currentImageUrl!.isNotEmpty &&
                _selectedImage == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SiporaTheme.greenLight, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: SiporaTheme.greenDark,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current profile picture displayed. Select a new image below to change it.',
                        style: TextStyle(
                          fontSize: 13,
                          color: SiporaTheme.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: SiporaTheme.greenDark,
                        onTap: _pickFromGallery,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: Colors.blue[700]!,
                        onTap: _pickFromCamera,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null)
                  _buildActionButton(
                    icon: Icons.crop_rounded,
                    label: 'Crop Image',
                    color: Colors.orange[700]!,
                    onTap: _cropImage,
                  ),
                const SizedBox(height: 8),
                if (_selectedImage != null ||
                    (widget.currentImageUrl != null &&
                        widget.currentImageUrl!.isNotEmpty))
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Image',
                    color: Colors.red[700]!,
                    onTap: _removeImage,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================
  // GALLERY PICKER - UPDATED
  // ============================================
  Future<void> _pickFromGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if on Android 13+ (API 33+)
      final bool isAndroid13OrHigher = await _isAndroid13OrHigher();

      XFile? image;

      if (isAndroid13OrHigher) {
        // Android 13+: Use system photo picker - NO PERMISSION NEEDED
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
      } else {
        // Android 12 and below: Need storage permission
        final bool hasPermission = await _checkStoragePermission();
        if (!hasPermission) {
          setState(() => _isLoading = false);
          return;
        }

        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
      }

      if (image != null) {
        final File file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _isImageFromUrl = false;
            _isLoading = false;
          });
          await _cropImage();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================
  // CAMERA PICKER
  // ============================================
  Future<void> _pickFromCamera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final File file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _isImageFromUrl = false;
            _isLoading = false;
          });
          await _cropImage();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================
  // PERMISSION HELPERS
  // ============================================
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt >= 33;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _checkStoragePermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }

      if (await _isAndroid13OrHigher()) {
        return true;
      }

      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog('Storage');
        }
        return false;
      } else {
        if (mounted) {
          _showSnackBar('Storage permission is required.', isError: true);
        }
        return false;
      }
    } catch (e) {
      _showSnackBar('Error checking permissions: $e', isError: true);
      return false;
    }
  }

  Future<bool> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog('Camera');
        }
        return false;
      } else {
        if (mounted) {
          _showSnackBar('Camera permission is required.', isError: true);
        }
        return false;
      }
    } catch (e) {
      _showSnackBar('Error checking camera permission: $e', isError: true);
      return false;
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'The app needs $permissionName permission to select images for your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // IMAGE OPERATIONS
  // ============================================
  Future<void> _cropImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: _selectedImage!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: const Color(0xFF2D5016),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            cropFrameColor: const Color(0xFF2D5016),
            cropFrameStrokeWidth: 3,
            cropGridColor: Colors.white.withValues(alpha: 0.5),
            statusBarLight: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped != null) {
        final File croppedFile = File(cropped.path);
        if (await croppedFile.exists()) {
          setState(() {
            _selectedImage = croppedFile;
            _isLoading = false;
          });
          if (mounted) {
            _showSnackBar('Image cropped successfully!', isError: false);
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to crop image: $e';
        _isLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _isImageFromUrl = false;
      _errorMessage = null;
    });
    widget.onImageSelected(null);
    _showSnackBar('Image removed', isError: false);
  }

  void _saveImage() {
    if (_selectedImage != null) {
      widget.onImageSelected(_selectedImage);
      Navigator.pop(context, _selectedImage);
    } else {
      Navigator.pop(context);
    }
  }
}
