import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your server IP when testing on a physical device
  static const String baseUrl = 'http://localhost:3000/api';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> get _headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Something went wrong',
    );
  }

  // Auth
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String otp,
    required String pin,
    required String firstName,
    required String lastName,
    required String businessName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'pin': pin,
        'firstName': firstName,
        'lastName': lastName,
        'businessName': businessName,
      }),
    );
    final data = await _handleResponse(response);
    await saveToken(data['accessToken']);
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber, 'pin': pin}),
    );
    final data = await _handleResponse(response);
    await saveToken(data['accessToken']);
    return data;
  }

  // User
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> submitKyc({
    required String nationalId,
    required String kraPin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/kyc'),
      headers: await _headers,
      body: jsonEncode({'nationalId': nationalId, 'kraPin': kraPin}),
    );
    return _handleResponse(response);
  }

  // Wallet
  Future<Map<String, dynamic>> getBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/balance'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> transfer({
    required String recipientPhone,
    required double amount,
    required String pin,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/transfer'),
      headers: await _headers,
      body: jsonEncode({
        'recipientPhone': recipientPhone,
        'amount': amount,
        'pin': pin,
        if (description != null) 'description': description,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/transactions?page=$page&limit=$limit'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  // M-Pesa
  Future<Map<String, dynamic>> mpesaDeposit({
    required double amount,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mpesa/deposit'),
      headers: await _headers,
      body: jsonEncode({'amount': amount, 'phoneNumber': phoneNumber}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> mpesaWithdraw({
    required double amount,
    required String phoneNumber,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mpesa/withdraw'),
      headers: await _headers,
      body: jsonEncode({
        'amount': amount,
        'phoneNumber': phoneNumber,
        'pin': pin,
      }),
    );
    return _handleResponse(response);
  }

  // Savings Pots
  Future<List<dynamic>> getSavingsPots() async {
    final response = await http.get(
      Uri.parse('$baseUrl/savings-pots'),
      headers: await _headers,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as List<dynamic>;
    }
    throw ApiException(statusCode: response.statusCode, message: 'Failed to load pots');
  }

  Future<Map<String, dynamic>> createSavingsPot({
    required String name,
    String? emoji,
    double? targetAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings-pots'),
      headers: await _headers,
      body: jsonEncode({
        'name': name,
        if (emoji != null) 'emoji': emoji,
        if (targetAmount != null) 'targetAmount': targetAmount,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> depositToPot({
    required String potId,
    required double amount,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings-pots/$potId/deposit'),
      headers: await _headers,
      body: jsonEncode({'amount': amount, 'pin': pin}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> withdrawFromPot({
    required String potId,
    required double amount,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings-pots/$potId/withdraw'),
      headers: await _headers,
      body: jsonEncode({'amount': amount, 'pin': pin}),
    );
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
