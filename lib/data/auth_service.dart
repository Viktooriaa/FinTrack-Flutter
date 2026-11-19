import 'package:dio/dio.dart';

/// Email/password auth backed by Firebase Authentication's public client API.
/// The API key is supplied at build/run time and is not stored in source.
class AuthService {
  AuthService._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _apiBase = 'https://identitytoolkit.googleapis.com/v1/';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiBase,
      headers: const {
        'Content-Type': 'application/json',
        'X-Firebase-Locale': 'uk',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<AuthSession> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _post('signUp', {
      'email': email.trim(),
      'password': password,
      'displayName': name.trim(),
      'returnSecureToken': true,
    });
    return AuthSession.fromMap(data);
  }

  static Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _post('signInWithPassword', {
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    });
    return AuthSession.fromMap(data);
  }

  static Future<void> sendVerificationEmail(AuthSession session) async {
    await _post('sendOobCode', {
      'requestType': 'VERIFY_EMAIL',
      'idToken': session.idToken,
    });
  }

  static Future<bool> isEmailVerified(AuthSession session) async {
    final data = await _post('lookup', {'idToken': session.idToken});
    final users = data['users'];
    return users is List &&
        users.isNotEmpty &&
        users.first is Map &&
        (users.first as Map)['emailVerified'] == true;
  }

  static Future<void> sendPasswordReset(String email) async {
    await _post('sendOobCode', {
      'requestType': 'PASSWORD_RESET',
      'email': email.trim(),
    });
  }

  static Future<Map<String, dynamic>> _post(
    String method,
    Map<String, Object?> body,
  ) async {
    if (!isConfigured) {
      throw const AuthException(
        'Авторизація ще не налаштована. Додайте FIREBASE_API_KEY і ввімкніть Email/Password у Firebase.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'accounts:$method',
        queryParameters: {'key': _apiKey},
        data: body,
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      final responseBody = error.response?.data;
      String? rawCode;
      if (responseBody is Map) {
        final errorBody = responseBody['error'];
        if (errorBody is Map) rawCode = errorBody['message']?.toString();
      }
      throw AuthException(_messageFor(rawCode));
    }
  }

  static String _messageFor(String? code) => switch (code) {
    'EMAIL_EXISTS' => 'Ця електронна пошта вже зареєстрована.',
    'WEAK_PASSWORD' =>
      'Пароль надто простий. Використайте щонайменше 8 символів.',
    'INVALID_EMAIL' => 'Перевірте адресу електронної пошти.',
    'INVALID_PASSWORD' ||
    'EMAIL_NOT_FOUND' ||
    'INVALID_LOGIN_CREDENTIALS' => 'Неправильний email або пароль.',
    'OPERATION_NOT_ALLOWED' =>
      'У Firebase не ввімкнено вхід через email і пароль.',
    'API_KEY_INVALID' || 'INVALID_API_KEY' =>
      'FIREBASE_API_KEY неправильний. Перевірте ключ вебзастосунку Firebase.',
    'TOO_MANY_ATTEMPTS_TRY_LATER' =>
      'Забагато спроб. Спробуйте ще раз трохи пізніше.',
    'USER_DISABLED' => 'Цей обліковий запис вимкнено.',
    'EXPIRED_OOB_CODE' || 'INVALID_OOB_CODE' =>
      'Посилання застаріло або вже використане. Надішліть лист повторно.',
    _ =>
      'Не вдалося зв’язатися з авторизацією. Перевірте інтернет і налаштування Firebase.',
  };
}

class AuthSession {
  const AuthSession({required this.email, required this.idToken});

  final String email;
  final String idToken;

  factory AuthSession.fromMap(Map<String, dynamic> data) {
    final email = data['email'];
    final idToken = data['idToken'];
    if (email is! String || idToken is! String) {
      throw const AuthException(
        'Firebase повернув неповні дані облікового запису.',
      );
    }
    return AuthSession(email: email, idToken: idToken);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
