class WalletModel {
  final double balance;
  final String currency;
  final String status;

  WalletModel({
    required this.balance,
    required this.currency,
    required this.status,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? 'KES',
      status: json['status'] ?? 'active',
    );
  }
}

class TransactionModel {
  final String id;
  final String reference;
  final String type;
  final String status;
  final double amount;
  final double fee;
  final String currency;
  final String description;
  final String direction;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.amount,
    required this.fee,
    required this.currency,
    required this.description,
    required this.direction,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'KES',
      description: json['description'] ?? '',
      direction: json['direction'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  bool get isIncoming => direction == 'incoming';
}

class SavingsPotModel {
  final String id;
  final String name;
  final String? emoji;
  final double currentAmount;
  final double? targetAmount;
  final int? progress;

  SavingsPotModel({
    required this.id,
    required this.name,
    this.emoji,
    required this.currentAmount,
    this.targetAmount,
    this.progress,
  });

  factory SavingsPotModel.fromJson(Map<String, dynamic> json) {
    return SavingsPotModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'],
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetAmount: json['targetAmount'] != null
          ? (json['targetAmount'] as num).toDouble()
          : null,
      progress: json['progress'],
    );
  }
}
