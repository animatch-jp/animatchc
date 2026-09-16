import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dx2xqewxb';
  static const String apiKey = '257184434655497';
  static const String uploadPreset = 'animatch_upload';

  static Future<String?> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return await uploadImageBytes(bytes, pickedFile.name);
    } catch (e) {
      print('🔥 画像選択エラー: $e');
      return null;
    }
  }

  static Future<String?> uploadImageBytes(
      Uint8List bytes, String fileName) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      } else {
        print('🔥 アップロードエラー: $jsonData');
        return null;
      }
    } catch (e) {
      print('🔥 アップロードエラー: $e');
      return null;
    }
  }
}
