import '../models/user.dart';


class ApiService {
  // TODO: Implement REST API methods
  Future<Map<String, dynamic>> get(String endpoint) async {
    // Placeholder for GET request
    return {};
  }

  Future<User> getCurrentUser() async {
    // Imitate delay
    await Future.delayed(Duration(seconds: 5));

    // Placeholder for getting current user from API
    return User(id: "1", name: "Max", email: "max@example.com");
  }
}
