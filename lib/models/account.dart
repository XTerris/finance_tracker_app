import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 3)
class Account {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  double balance;

  Account({required this.id, required this.name, required this.balance});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'balance': balance};
  }
}
