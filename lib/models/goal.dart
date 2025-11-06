class Goal {
  final int id;
  final int accountId;
  final double targetAmount;
  final DateTime deadline;
  bool isCompleted;

  Goal({
    required this.id,
    required this.accountId,
    required this.targetAmount,
    required this.deadline,
    required this.isCompleted,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      accountId: json['account_id'],
      targetAmount: json['target_amount'].toDouble(),
      deadline: DateTime.parse(json['deadline']),
      isCompleted: json['is_completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'target_amount': targetAmount,
      'deadline': deadline.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
    };
  }
}
