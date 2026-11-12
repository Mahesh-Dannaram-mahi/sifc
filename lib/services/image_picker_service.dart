import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImagePickerService {
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxWidth = 800;
  static const int maxHeight = 800;
  static const int imageQuality = 70;

  // ============================================
  // PICK IMAGE - UPDATED
  // ============================================
  static Future<File?> pickImage({required BuildContext context}) async {
    try {
      final bool isAndroid13OrHigher = await _isAndroid13OrHigher();
      File? imageFile;

      if (isAndroid13OrHigher) {
        // Android 13+: Use system photo picker - NO PERMISSION NEEDED
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: maxWidth.toDouble(),
          maxHeight: maxHeight.toDouble(),
          imageQuality: imageQuality,
        );

        if (image == null) return null;

        final File rawFile = File(image.path);
        if (!await rawFile.exists()) {
          throw Exception('Selected file does not exist.');
        }
        imageFile = rawFile;
      } else {
        // Android 12 and below OR iOS: Need permission
        final bool hasPermission = await _checkAndRequestPermissions(context);
        if (!hasPermission) return null;

        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: maxWidth.toDouble(),
          maxHeight: maxHeight.toDouble(),
          imageQuality: imageQuality,
        );

        if (image == null) return null;

        final File rawFile = File(image.path);
        if (!await rawFile.exists()) {
          throw Exception('Selected file does not exist.');
        }
        imageFile = rawFile;
      }

      if (imageFile == null) return null;

      if (!context.mounted) return null;

      try {
        final CroppedFile? cropped = await _cropImage(
          imagePath: imageFile.path,
        );

        if (cropped == null) {
          return imageFile;
        }

        final File croppedFile = File(cropped.path);
        final int fileSize = await croppedFile.length();
        if (fileSize > maxFileSize) {
          if (context.mounted) {
            _showSnackBar(
              context,
              'Image size exceeds 5MB. Please choose a smaller image.',
              isError: true,
            );
          }
          return null;
        }

        return croppedFile;
      } catch (e) {
        return imageFile;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
      return null;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
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

  static Future<CroppedFile?> _cropImage({required String imagePath}) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: imageQuality,
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
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // PERMISSION HANDLING - UPDATED
  // ============================================
  static Future<bool> _checkAndRequestPermissions(BuildContext context) async {
    try {
      // iOS: Request photos permission
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted || status.isLimited) {
          return true;
        } else if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(context, 'Photos');
          }
          return false;
        } else {
          if (context.mounted) {
            _showSnackBar(
              context,
              'Photos permission is required to select images.',
              isError: true,
            );
          }
          return false;
        }
      }

      // Android: Check version
      if (Platform.isAndroid) {
        final bool isAndroid13OrHigher = await _isAndroid13OrHigher();

        // Android 13+ uses system photo picker - NO PERMISSION NEEDED
        if (isAndroid13OrHigher) {
          return true;
        }

        // Android 12 and below: Need storage permission
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(context, 'Storage');
          }
          return false;
        } else {
          if (context.mounted) {
            _showSnackBar(
              context,
              'Storage permission is required to select images on this device.',
              isError: true,
            );
          }
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName Permission Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The app needs $permissionName permission to select images for your profile.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enable it in the app settings.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
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
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // IMAGE PREVIEW
  // ============================================
  static Future<File?> showImagePreview({
    required BuildContext context,
    required File imageFile,
    String? title,
  }) async {
    try {
      if (!await imageFile.exists()) {
        if (context.mounted) {
          _showSnackBar(context, 'Image file is not available.', isError: true);
        }
        return null;
      }

      return await showDialog<File>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title ?? 'Image Preview',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PhotoView(
                          imageProvider: FileImage(imageFile),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                          backgroundDecoration: const BoxDecoration(
                            color: Colors.black12,
                          ),
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unable to preview image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, imageFile);
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Use This Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Could not preview image: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
      return null;
    }
  }

  // ============================================
  // AVATAR PICKER OPTIONS
  // ============================================
  static Future<File?> showAvatarPickerOptions({
    required BuildContext context,
    File? currentImage,
  }) async {
    File? selectedFile;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: false,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (currentImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await showImagePreview(
                          context: context,
                          imageFile: currentImage,
                          title: 'Avatar Preview',
                        );
                      } catch (e) {
                        if (context.mounted) {
                          _showSnackBar(
                            context,
                            'Error showing preview: ${e.toString().replaceFirst('Exception: ', '')}',
                            isError: true,
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2D5016),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: FileImage(currentImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: const Color(0xFF2D5016),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Select and crop an image for your avatar',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImage(context: context);
                  if (file != null && context.mounted) {
                    final result = await showImagePreview(
                      context: context,
                      imageFile: file,
                      title: 'Avatar Preview',
                    );
                    if (result != null) {
                      selectedFile = result;
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: const Color(0xFF2D5016),
                  ),
                ),
                title: const Text(
                  'Enter Image URL',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Provide a URL for your avatar',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    _showUrlDialog(context);
                  }
                },
              ),
              if (currentImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[700],
                    ),
                  ),
                  title: Text(
                    'Remove Selected Image',
                    style: TextStyle(fontSize: 16, color: Colors.red[700]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectedFile = null;
                    if (context.mounted) {
                      _showSnackBar(
                        context,
                        'Image removed. You can select a new one.',
                        isError: false,
                      );
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    return selectedFile;
  }

  // ============================================
  // URL DIALOG
  // ============================================
  static void _showUrlDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: const Color(0xFF2D5016),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Enter Avatar URL',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the URL of your avatar image:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Avatar URL',
                  hintText: 'https://example.com/avatar.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty &&
                    Uri.tryParse(url)?.hasAbsolutePath == true) {
                  Navigator.pop(context, url);
                  if (context.mounted) {
                    _showSnackBar(
                      context,
                      'Avatar URL added successfully!',
                      isError: false,
                    );
                  }
                } else {
                  if (context.mounted) {
                    _showSnackBar(
                      context,
                      'Please enter a valid URL',
                      isError: true,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
              ),
              child: const Text('Use URL'),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // SNACKBAR HELPER
  // ============================================
  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[700] : const Color(0xFF2D5016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // debugPrint('Error showing snackbar: $e');
    }
  }
}
