import 'dart:convert';
import 'package:finance_tracker_app/models/token.dart';
import 'package:finance_tracker_app/models/user.dart';
import 'package:finance_tracker_app/models/category.dart';
import 'package:finance_tracker_app/models/transaction.dart';
import 'package:finance_tracker_app/models/account.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exceptions.dart';

enum HttpMethod { get, post, put, delete, patch }

class ApiService {
  static const String _defaultServerIp =
      'localhost'; // '192.168.1.142'; // '172.16.0.31';
  static const String _defaultServerPort = '8001';
  static const Duration _timeout = Duration(seconds: 5);

  late http.Client _client;
  String? _accessToken;
  final String _baseUrl = 'http://$_defaultServerIp:$_defaultServerPort';

  factory ApiService() => _instance;

  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  static Future<void> init() async {
    await _instance._loadTokenFromStorage();
    _instance._client = http.Client();
  }

  // Token management
  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _accessToken = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _accessToken = null;
  }

  bool get isAuthenticated => _accessToken != null;

  // Helper methods for HTTP requests
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Map<String, String> get _formHeaders {
    final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    dynamic data;
    try {
      data = response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (e) {
      throw ApiException('Сервер вернул некорректный JSON ответ');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return data;
      case 401:
        await clearToken();
        throw UnauthorizedException('Неавторизованный доступ');
      case 404:
        throw NotFoundException('Ресурс не найден');
      case 422:
        final errors =
            data != null && data['detail'] != null
                ? (data['detail'] as List)
                    .map((e) => ValidationError.fromJson(e))
                    .toList()
                : <ValidationError>[];
        throw ValidationException('Ошибка валидации', errors: errors);
      default:
        throw ApiException(
          'Ошибка при выполнении запроса',
          statusCode: response.statusCode,
        );
    }
  }

  Future<dynamic> _makeRequest(
    HttpMethod method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool useFormData = false,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: queryParams);

    late http.Response response;
    final headers = useFormData ? _formHeaders : _headers;

    switch (method) {
      case HttpMethod.get:
        response = await _client.get(uri, headers: headers).timeout(_timeout);
        break;
      case HttpMethod.post:
        if (useFormData) {
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body?.entries.map((e) => '${e.key}=${e.value}').join('&'),
              )
              .timeout(_timeout);
        } else {
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(_timeout);
        }
        break;
      case HttpMethod.put:
        response = await _client
            .put(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            )
            .timeout(_timeout);
        break;
      case HttpMethod.delete:
        response = await _client
            .delete(uri, headers: headers)
            .timeout(_timeout);
        break;
      case HttpMethod.patch:
        response = await _client
            .patch(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            )
            .timeout(_timeout);
        break;
    }

    return await _handleResponse(response);
  }

  Future<Token> login(String username, String password) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/login',
      body: {
        'username': username,
        'password': password,
        'grant_type': 'password',
      },
      useFormData: true,
    );

    final token = Token.fromJson(data);
    await _saveTokenToStorage(token.accessToken);
    return token;
  }

  Future<void> createUser(
    String username,
    String email,
    String password,
  ) async {
    try {
      await _makeRequest(
        HttpMethod.post,
        '/users/',
        body: {'username': username, 'login': email, 'password': password},
      );
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 409:
          throw UserEmailConflictException();
        case 422:
          throw ValidationException("Ошибка валидации данных пользователя");
        default:
          rethrow;
      }
    }
  }

  Future<User> getCurrentUser() async {
    final data = await _makeRequest(HttpMethod.get, '/users/me');

    return User.fromJson(data);
  }

  Future<Transaction> getTransaction(int id) async {
    final data = await _makeRequest(HttpMethod.get, '/transactions/$id');
    return Transaction.fromJson(data);
  }

  Future<List<Transaction>> getAllTransactions() async {
    final transactions = <Transaction>[];
    var currentOffset = 0;
    const limit = 100;

    while (true) {
      final data = await _makeRequest(
        HttpMethod.get,
        '/transactions/',
        queryParams: {
          'offset': currentOffset.toString(),
          'limit': limit.toString(),
        },
      );

      final page = ((data as Map)['items'] as List)
          .map((e) => Transaction.fromJson(e))
          .toList(growable: false);

      transactions.addAll(page);

      if (page.length < limit) {
        break;
      }

      currentOffset += limit;
    }

    return transactions;
  }

  Future<List<int>> getUpdatedTransactionIds(int since) async {
    final data = await _makeRequest(
      HttpMethod.get,
      '/transactions/updated',
      queryParams: {'updated_since': since.toString()},
    );

    return (data as List).map((e) => e as int).toList();
  }

  Future<Transaction> createTransaction({
    required String title,
    required double amount,
    required int categoryId,
    required int accountId,
    DateTime? doneAt,
  }) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/transactions/',
      body: {
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        if (doneAt != null) 'done_at': doneAt.toIso8601String(),
      },
    );
    return Transaction.fromJson(data);
  }

  Future<void> deleteTransaction(int id) async {
    await _makeRequest(HttpMethod.delete, '/transactions/$id');
  }

  Future<List<Category>> getAllCategories() async {
    final data = await _makeRequest(HttpMethod.get, '/categories/');
    return (data as List)
        .map((e) => Category.fromJson(e))
        .toList(growable: false);
  }

  Future<Category> createCategory(String name) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/categories/',
      body: {'name': name},
    );
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(int id) async {
    await _makeRequest(HttpMethod.delete, '/categories/$id');
  }

  Future<List<Account>> getAllAccounts() async {
    final data = await _makeRequest(HttpMethod.get, '/accounts/');
    return (data as List)
        .map((e) => Account.fromJson(e))
        .toList(growable: false);
  }

  Future<Account> createAccount(String name, double initialBalance) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/accounts/',
      body: {'name': name, 'initial_balance': initialBalance},
    );
    return Account.fromJson(data);
  }

  Future<void> deleteAccount(int id) async {
    await _makeRequest(HttpMethod.delete, '/accounts/$id');
  }

  void dispose() {
    _client.close();
  }
}
