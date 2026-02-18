import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<bool> checkAuth() async {
    final token = await _api.token;
    if (token == null) return false;

    try {
      final data = await _api.getProfile();
      _user = UserModel.fromJson(data);
      notifyListeners();
      return true;
    } catch (_) {
      await _api.clearToken();
      return false;
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.requestOtp(phoneNumber);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String phoneNumber,
    required String otp,
    required String pin,
    required String firstName,
    required String lastName,
    required String businessName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(
        phoneNumber: phoneNumber,
        otp: otp,
        pin: pin,
        firstName: firstName,
        lastName: lastName,
        businessName: businessName,
      );
      _user = UserModel.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String phoneNumber,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(phoneNumber: phoneNumber, pin: pin);
      _user = UserModel.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }
}
