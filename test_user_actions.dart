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

  // 1. Create a new user (simulate someone joining)
  final registerRes = await dio.post('/api/auth/v1/register', data: {
    'name': 'Test Staff',
    'email': 'stafftest_${DateTime.now().millisecondsSinceEpoch}@bmb.com',
    'password': password,
    'organizationId': '6ac78e4f0a063d3e07a1bed5',
    'role': 'staff'
  });
  print('Register staff: ${registerRes.data}');

  // 2. Login as owner to do operations
  final loginRes = await dio.post('/api/auth/v1/login', data: {
    'email': email,
    'password': password,
  });
  final token = loginRes.data['token'];
  dio.options.headers['Authorization'] = 'Bearer $token';

  // 3. List users
  var usersRes = await dio.get('/api/auth/');
  print('Users before deactivate: ${(usersRes.data['data']['users'] as List).length}');
  
  final staffUserId = registerRes.data['data']['userId'] ?? registerRes.data['data']['_id'];
  print('Staff ID: $staffUserId');

  // 4. Deactivate
  if (staffUserId != null) {
      final deactRes = await dio.patch('/api/auth/v1/$staffUserId/deactivate');
      print('Deactivate: ${deactRes.data}');
      
      // 5. List users again
      usersRes = await dio.get('/api/auth/');
      final allUsers = usersRes.data['data']['users'] as List;
      print('Users after deactivate: ${allUsers.length}');
      final isFound = allUsers.any((u) => u['_id'] == staffUserId);
      print('Is deactivated user found in list? $isFound');
      if (isFound) {
          final found = allUsers.firstWhere((u) => u['_id'] == staffUserId);
          print('isActive flag: ${found['isActive']}');
      }

      // 6. Recover
      final recRes = await dio.patch('/api/auth/v1/$staffUserId/recover');
      print('Recover: ${recRes.data}');

      // 7. Change role
      final roleRes = await dio.put('/api/auth/v1/$staffUserId/role', data: {'role': 'admin'});
      print('Change Role: ${roleRes.data}');

      // 8. Delete
      final delRes = await dio.delete('/api/auth/v1/$staffUserId/delete');
      print('Delete: ${delRes.data}');
  }
}
