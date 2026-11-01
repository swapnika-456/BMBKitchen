import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://bmbproducts.com/',
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => true,
  ));

  final email = Platform.environment['BMB_TEST_EMAIL'] ?? '';
  final password = Platform.environment['BMB_TEST_PASSWORD'] ?? '';
  if (email.isEmpty || password.isEmpty) {
    print('Please set BMB_TEST_EMAIL and BMB_TEST_PASSWORD environment variables');
    return;
  }

  final loginRes = await dio.post('/api/auth/v1/login', data: {
    'email': email,
    'password': password,
  });
  
  final token = loginRes.data['token'];
  dio.options.headers['Authorization'] = 'Bearer $token';

  final usersRes = await dio.get('/api/auth/');
  print('Users: ${usersRes.data}');
}
