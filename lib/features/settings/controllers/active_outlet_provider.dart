import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mock/mock_state.dart';
import '../../../models/outlet.dart';
import 'outlet_controller.dart';

final activeOutletProvider = Provider<Outlet?>((ref) {
  final activeOutletId = ref.watch(bmbStateProvider).activeOutletId;
  final outletsAsync = ref.watch(outletControllerProvider);
  final outlets = outletsAsync.value ?? [];
  try {
    return outlets.firstWhere((o) => o.id == activeOutletId);
  } catch (e) {
    return outlets.isNotEmpty ? outlets.first : null;
  }
});
