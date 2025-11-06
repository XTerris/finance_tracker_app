class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['username'],
      email: json['login'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': name,
      'login': email,
    };
  }
}
