import 'dart:convert';
import 'package:finance_tracker_app/models/token.dart';
import 'package:finance_tracker_app/models/user.dart';
import 'package:finance_tracker_app/models/category.dart';
import 'package:finance_tracker_app/models/transaction.dart';
import 'package:finance_tracker_app/models/account.dart';
import 'package:finance_tracker_app/models/goal.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exceptions.dart';

enum HttpMethod { get, post, put, delete, patch }

class ApiService {
  // static const String _defaultServerIp = '192.168.1.142';
  static const String _defaultServerIp = 'localhost';
  // static const String _defaultServerIp = '172.16.0.31';
  static const String _defaultServerPort = '8001';
  static const Duration _timeout = Duration(seconds: 5);

  late http.Client _client;
  String? _accessToken;
  String? _refreshToken;
  final String _baseUrl = 'http://$_defaultServerIp:$_defaultServerPort';
  bool _isRefreshing = false;

  // Callback to notify when session expires
  void Function()? onSessionExpired;

  factory ApiService() => _instance;

  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  static Future<void> init() async {
    await _instance._loadTokenFromStorage();
    _instance._client = http.Client();
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _saveTokenToStorage(Token token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token.accessToken);
    await prefs.setString('refresh_token', token.refreshToken);
    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
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

  Future<dynamic> _handleResponse(
    http.Response response, {
    bool isRetry = false,
  }) async {
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
        // If this is already a retry or we're currently refreshing, don't retry again
        if (isRetry || _isRefreshing) {
          await clearToken();
          throw UnauthorizedException('Неавторизованный доступ');
        }
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
    bool isRetry = false,
  }) async {
    try {
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
                  body: body?.entries
                      .map((e) => '${e.key}=${e.value}')
                      .join('&'),
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

      return await _handleResponse(response, isRetry: isRetry);
    } on UnauthorizedException {
      // If not already retrying and we have a refresh token, try to refresh
      if (!isRetry && _refreshToken != null && !_isRefreshing) {
        try {
          await refreshToken();
          // Retry the request with the new token
          return await _makeRequest(
            method,
            endpoint,
            body: body,
            queryParams: queryParams,
            useFormData: useFormData,
            isRetry: true,
          );
        } catch (e) {
          // If refresh fails, clear tokens and notify session expired
          await clearToken();
          onSessionExpired?.call();
          rethrow;
        }
      }
      // If we can't refresh, clear tokens and notify session expired
      await clearToken();
      onSessionExpired?.call();
      rethrow;
    }
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
    await _saveTokenToStorage(token);
    return token;
  }

  Future<Token> refreshToken() async {
    if (_refreshToken == null) {
      throw ApiException('No refresh token available');
    }

    _isRefreshing = true;
    try {
      final uri = Uri.parse(
        '$_baseUrl/refresh',
      ).replace(queryParameters: {'refresh_token': _refreshToken!});

      final response = await _client
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_timeout);

      dynamic data;
      try {
        data = response.body.isNotEmpty ? json.decode(response.body) : null;
      } catch (e) {
        throw ApiException('Сервер вернул некорректный JSON ответ');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = Token.fromJson(data);
        await _saveTokenToStorage(token);
        return token;
      } else if (response.statusCode == 401) {
        await clearToken();
        onSessionExpired?.call();
        throw UnauthorizedException('Refresh token истек или недействителен');
      } else {
        throw ApiException(
          'Ошибка при обновлении токена',
          statusCode: response.statusCode,
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    try {
      await _makeRequest(HttpMethod.post, '/logout');
    } finally {
      // Always clear tokens locally, even if the request fails
      await clearToken();
    }
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
    DateTime? doneAt,
    int? fromAccountId,
    int? toAccountId,
  }) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/transactions/',
      body: {
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        if (doneAt != null) 'done_at': doneAt.toIso8601String(),
        if (fromAccountId != null) 'from_account_id': fromAccountId,
        if (toAccountId != null) 'to_account_id': toAccountId,
      },
    );
    return Transaction.fromJson(data);
  }

  Future<Transaction> updateTransaction({
    required int id,
    String? title,
    int? categoryId,
  }) async {
    final data = await _makeRequest(
      HttpMethod.put,
      '/transactions/$id',
      body: {
        if (title != null) 'title': title,
        if (categoryId != null) 'category_id': categoryId,
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
      body: {'name': name, 'balance': initialBalance},
    );
    return Account.fromJson(data);
  }

  Future<void> deleteAccount(int id) async {
    await _makeRequest(HttpMethod.delete, '/accounts/$id');
  }

  Future<List<Goal>> getAllGoals() async {
    final data = await _makeRequest(HttpMethod.get, '/goals/');
    return (data as List).map((e) => Goal.fromJson(e)).toList(growable: false);
  }

  Future<Goal> createGoal({
    required int accountId,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final data = await _makeRequest(
      HttpMethod.post,
      '/goals/',
      body: {
        'account_id': accountId,
        'target_amount': targetAmount,
        'deadline': deadline.toIso8601String().split('T')[0],
      },
    );
    return Goal.fromJson(data);
  }

  Future<Goal> updateGoal({
    required int id,
    int? accountId,
    double? targetAmount,
    DateTime? deadline,
    bool? isCompleted,
  }) async {
    final data = await _makeRequest(
      HttpMethod.put,
      '/goals/$id',
      body: {
        if (accountId != null) 'account_id': accountId,
        if (targetAmount != null) 'target_amount': targetAmount,
        if (deadline != null)
          'deadline': deadline.toIso8601String().split('T')[0],
        if (isCompleted != null) 'is_completed': isCompleted,
      },
    );
    return Goal.fromJson(data);
  }

  Future<Goal> markGoalComplete(int id) async {
    final data = await _makeRequest(HttpMethod.patch, '/goals/$id/complete');
    return Goal.fromJson(data);
  }

  Future<Goal> markGoalIncomplete(int id) async {
    final data = await _makeRequest(HttpMethod.patch, '/goals/$id/incomplete');
    return Goal.fromJson(data);
  }

  Future<void> deleteGoal(int id) async {
    await _makeRequest(HttpMethod.delete, '/goals/$id');
  }

  void dispose() {
    _client.close();
  }
}
