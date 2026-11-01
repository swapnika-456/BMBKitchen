import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<User?> {
  late final AuthRepository _repository;

  @override
  Future<User?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    // When the app starts, check if the user is already authenticated
    return _repository.checkAuth();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.login(email, password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String organizationId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
        role: role,
        organizationId: organizationId,
      ),
    );
  }

  Future<bool> registerOrganization({
    required String userName,
    required String email,
    required String password,
    required String organizationName,
    String? phone,
  }) async {
    try {
      state = const AsyncValue.loading();
      // Use guard so that state updates properly, but wait for result to return boolean
      final result = await AsyncValue.guard(
        () => _repository.registerOrganization(
          userName: userName,
          email: email,
          password: password,
          organizationName: organizationName,
          phone: phone,
        ),
      );
      state = result;
      return result.hasValue;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    // Clear the user data from state
    state = const AsyncValue.data(null);
  }
}
