import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AuthGate serves as the landing page after a successful login or signup.
/// In the future, this will check if an outlet exists for the organization
/// before routing to the dashboard. For now, it simply routes to /dashboard.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // For now, immediately redirect to dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
