import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ProfileService {
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    File? avatarFile,
    String? avatarUrl,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Please Login');
      }

      // First, update text fields using /edit-user endpoint
      await _updateTextFields(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        token: token,
      );

      // Then, upload avatar if a file is provided using /upload-avatar endpoint
      if (avatarFile != null) {
        await _uploadAvatar(
          userId: userId,
          avatarFile: avatarFile,
          token: token,
        );
      }

      // If avatar URL was provided directly (not as file), update it
      if (avatarUrl != null && avatarUrl.isNotEmpty && avatarFile == null) {
        await _updateAvatarUrl(
          userId: userId,
          avatarUrl: avatarUrl,
          token: token,
        );
      }

      // Get the updated user data
      final updatedUser = await _fetchUpdatedUser(userId: userId, token: token);

      // Return combined result
      return {
        'success': true,
        'message': 'Profile updated successfully',
        'user': updatedUser,
      };
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on Exception catch (e) {
      throw Exception(e.toString());
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Helper to update text fields
  static Future<void> _updateTextFields({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/user/edit-user');

    final Map<String, String> fields = {
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };

    final response = await http
        .put(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(fields),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out. Please try again.');
          },
        );

    if (response.statusCode != 200) {
      final dynamic data = json.decode(response.body);
      String errorMessage = 'Failed to update profile';
      if (data is Map<String, dynamic>) {
        errorMessage = data['message'] ?? errorMessage;
      } else if (data is Map<dynamic, dynamic>) {
        final convertedData = Map<String, dynamic>.from(data);
        errorMessage = convertedData['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  // Helper to upload avatar using the public endpoint
  static Future<void> _uploadAvatar({
    required String userId,
    required File avatarFile,
    required String token,
  }) async {
    // Validate file
    if (!await avatarFile.exists()) {
      throw Exception('File does not exist');
    }

    final fileSize = await avatarFile.length();
    if (fileSize > maxFileSize) {
      throw Exception('Image size exceeds 5MB limit');
    }

    if (fileSize == 0) {
      throw Exception('File is empty');
    }

    // Check file type
    final extension = avatarFile.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Only JPG, PNG, GIF, and WEBP images are supported');
    }

    // Determine content type
    String contentType = 'image/jpeg';
    if (extension == 'png') {
      contentType = 'image/png';
    } else if (extension == 'gif') {
      contentType = 'image/gif';
    } else if (extension == 'webp') {
      contentType = 'image/webp';
    }

    // Use the public /upload-avatar endpoint (no auth required per backend)
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/user/upload-avatar/$userId',
    );
    final request = http.MultipartRequest('POST', uri);

    // Add the file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Backend expects 'file' parameter name
        avatarFile.path,
        contentType: MediaType.parse(contentType),
      ),
    );

    // Send request with timeout
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Avatar upload timed out. Please try again.');
      },
    );

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final dynamic data = json.decode(responseBody);
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      } else if (data is Map<dynamic, dynamic>) {
        final convertedData = Map<String, dynamic>.from(data);
        if (convertedData['success'] == true) {
          return;
        }
        throw Exception(convertedData['message'] ?? 'Avatar upload failed');
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Avatar upload failed: ${response.statusCode}');
    }
  }

  // Helper to update avatar URL (for URL-only updates)
  static Future<void> _updateAvatarUrl({
    required String userId,
    required String avatarUrl,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/user/edit-user');

    final Map<String, dynamic> payload = {
      'id': userId,
      'avataricons': avatarUrl,
    };

    final response = await http
        .put(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(payload),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out. Please try again.');
          },
        );

    if (response.statusCode != 200) {
      final dynamic data = json.decode(response.body);
      String errorMessage = 'Failed to update avatar URL';
      if (data is Map<String, dynamic>) {
        errorMessage = data['message'] ?? errorMessage;
      } else if (data is Map<dynamic, dynamic>) {
        final convertedData = Map<String, dynamic>.from(data);
        errorMessage = convertedData['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  // Helper to fetch updated user data
  static Future<Map<String, dynamic>> _fetchUpdatedUser({
    required String userId,
    required String token,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/user/fetch-user-data/$userId',
    );

    final response = await http
        .get(
          uri,
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out. Please try again.');
          },
        );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        final userData = data['user'];
        if (userData is Map<String, dynamic>) {
          return userData;
        } else if (userData is Map<dynamic, dynamic>) {
          return Map<String, dynamic>.from(userData);
        } else {
          throw Exception('Invalid user data format');
        }
      } else if (data is Map<dynamic, dynamic>) {
        final convertedData = Map<String, dynamic>.from(data);
        if (convertedData['success'] == true) {
          final userData = convertedData['user'];
          if (userData is Map<String, dynamic>) {
            return userData;
          } else if (userData is Map<dynamic, dynamic>) {
            return Map<String, dynamic>.from(userData);
          }
        }
        throw Exception(
          convertedData['message'] ?? 'Failed to fetch user data',
        );
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to fetch user data: ${response.statusCode}');
    }
  }
}
