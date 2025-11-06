class Account {
  final int id;
  final String name;
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
