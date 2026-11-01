import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://bmbproducts.com/',
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => true,
  ));

  // 1. Skip register

  // 2. Login
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
  print('Login: ${loginRes.data}');
  final token = loginRes.data['token'];
  dio.options.headers['Authorization'] = 'Bearer $token';

  // 3. Extract OrgId from User
  final orgId = loginRes.data['data']?['organizationId']?['_id'];

  if (orgId == null) {
      print('Failed to get orgId');
      return;
  }

  // 4. Create Inventory Item without image
  final invRes = await dio.post('/api/inventory/v1/$orgId', data: {
    'material': 'Salt with Image',
    'category': 'Spices',
    'unit': 'kg',
    'inStock': 10,
    'minLevel': 2,
    'rate': 20,
  });

  print('Create Inventory: ${invRes.data}');
  final invId = invRes.data['data']?['_id'];
  
  if (invId == null) {
      print('Failed to get invId');
      return;
  }

  // 4b. Add image
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile('test_image.png', filename: 'test_image.png')
  });
  final imgRes = await dio.put('/api/inventory/v1/$orgId/$invId/image', data: formData);
  print('Add Image: ${imgRes.data}');

  // 4c. Get item to see image shape
  final getRes = await dio.get('/api/inventory/v1/$orgId/$invId');
  print('Get Item: ${getRes.data}');
  
  if (invId == null) {
      print('Failed to get invId');
      return;
  }

  // 5. Test Dropdown
  final dropRes = await dio.get('/api/inventory/v1/$orgId/dropdown');
  print('Dropdown: ${dropRes.data}');

  // 6. Test Adjust with invalid action
  final adjustRes = await dio.post('/api/inventory/v1/$orgId/$invId/adjust', data: {
    'action': 'invalid_action',
    'quantity': 5
  });
  print('Adjust Invalid: ${adjustRes.data}');
}
