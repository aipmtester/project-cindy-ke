import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/wallet_model.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  List<SavingsPotModel> _pots = [];
  bool _isLoading = false;
  String? _error;

  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  List<SavingsPotModel> get pots => _pots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBalance() async {
    try {
      final data = await _api.getBalance();
      _wallet = WalletModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    try {
      final data = await _api.getTransactions();
      final list = data['transactions'] as List;
      _transactions = list.map((t) => TransactionModel.fromJson(t)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPots() async {
    try {
      final data = await _api.getSavingsPots();
      _pots = data.map((p) => SavingsPotModel.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadBalance(),
      loadTransactions(),
      loadPots(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> transfer({
    required String recipientPhone,
    required double amount,
    required String pin,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.transfer(
        recipientPhone: recipientPhone,
        amount: amount,
        pin: pin,
        description: description,
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deposit({required double amount, required String phoneNumber}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.mpesaDeposit(amount: amount, phoneNumber: phoneNumber);
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

  Future<bool> withdraw({
    required double amount,
    required String phoneNumber,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.mpesaWithdraw(amount: amount, phoneNumber: phoneNumber, pin: pin);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createPot({
    required String name,
    String? emoji,
    double? targetAmount,
  }) async {
    try {
      await _api.createSavingsPot(name: name, emoji: emoji, targetAmount: targetAmount);
      await loadPots();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> depositToPot({
    required String potId,
    required double amount,
    required String pin,
  }) async {
    try {
      await _api.depositToPot(potId: potId, amount: amount, pin: pin);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> withdrawFromPot({
    required String potId,
    required double amount,
    required String pin,
  }) async {
    try {
      await _api.withdrawFromPot(potId: potId, amount: amount, pin: pin);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
