import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:bmb_kitchen/models/payment.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';
import 'package:bmb_kitchen/features/finance/controllers/payments_controller.dart';
import 'package:bmb_kitchen/features/finance/screens/payments_screen.dart';
import 'package:bmb_kitchen/features/finance/widgets/payment_detail_sheet.dart';
import 'package:bmb_kitchen/services/api/payment_api_service.dart';
import 'package:bmb_kitchen/core/network/api_response.dart';

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);
  @override
  Future<User?> build() async => _user;
}

class _FakePaymentsController extends PaymentsController {
  final PaymentListResponse _response;
  _FakePaymentsController(this._response);
  @override
  Future<PaymentListResponse> build() async => _response;
}

class _FakePaymentApiService extends PaymentApiService {
  final PaymentDetail _detail;
  _FakePaymentApiService(super.dio, this._detail);

  @override
  Future<ApiResponse<PaymentDetail>> getPaymentDetail(
    String organizationId,
    String paymentId,
  ) async {
    return ApiResponse<PaymentDetail>(
      success: true,
      statusCode: 200,
      message: 'Success',
      data: _detail,
    );
  }
}

void main() {
  final mockUser = User(
    id: 'user_1',
    organizationId: 'org_1',
    role: 'owner',
    email: 'owner@test.com',
    name: 'Test Owner',
    isActive: true,
  );

  final mockOutlet = Outlet(
    id: 'outlet_1',
    organizationId: 'org_1',
    name: 'Main Kitchen',
    code: 'MK-01',
    address: '123 Test St, Chennai, TN, 600001',
    phone: '9876543210',
    isActive: true,
  );

  final mockPaymentItem = PaymentItem(
    id: 'pay_1',
    outletId: 'outlet_1',
    outletName: 'Main Kitchen',
    outletCode: 'MK-01',
    orderType: 'takeaway',
    discountAmount: 10.0,
    taxAmount: 5.25,
    grandTotal: 110.25,
    paymentMethod: 'cash',
    paidAt: DateTime(2026, 10, 24, 7, 15, 34),
    orderNo: 'ORD-2026-0015',
    billNo: 'BILL-2026-0007',
  );

  final mockPaymentListResponse = PaymentListResponse(
    payments: [mockPaymentItem],
    total: 1,
    page: 1,
    limit: 20,
    totalPages: 1,
    summary: const PaymentSummary(
      totalCollected: 731.0,
      byMode: {
        'cash': PaymentModeSummary(amount: 310.5, count: 3),
        'split': PaymentModeSummary(amount: 210.25, count: 2),
        'unpaid': PaymentModeSummary(amount: 210.25, count: 2),
      },
    ),
  );

  final mockPaymentDetail = PaymentDetail(
    id: 'pay_1',
    outletId: 'outlet_1',
    outletName: 'Main Kitchen',
    outletCode: 'MK-01',
    orderType: 'takeaway',
    loyaltyPointsRedeemed: 0,
    items: [
      PaymentDetailItem(
        id: 'item_1',
        menuItemId: 'menu_1',
        name: 'Item 1',
        price: 100.0,
        quantity: 1,
        itemTotal: 100.0,
        notes: 'Extra spicy',
        status: 'served',
        sentToKitchenAt: DateTime(2026, 10, 24, 7, 15, 34),
      ),
    ],
    subTotal: 100.0,
    discountAmount: 0.0,
    taxPercent: 5.0,
    taxAmount: 5.25,
    grandTotal: 110.25,
    paymentMethod: 'cash',
    paidAt: DateTime(2026, 10, 24, 7, 15, 34),
    orderNo: 'ORD-2026-0015',
    billNo: 'BILL-2026-0007',
  );

  group('Module 13: Payment Models Deserialization Tests', () {
    test('#127 PaymentListResponse parses server JSON with summary and byMode', () {
      final json = {
        'payments': [
          {
            '_id': '6adc5b167878cd44ef7c86ab',
            'outletId': {'_id': 'out_1', 'name': 'Main Kitchen', 'code': 'MK'},
            'tableId': null,
            'orderType': 'takeaway',
            'discountAmount': 0,
            'taxAmount': 5.25,
            'grandTotal': 110.25,
            'paymentMethod': 'unpaid',
            'paidAt': '2026-10-24T07:15:34.562Z',
            'orderNo': 'ORD-2026-0015',
            'billNo': 'BILL-2026-0007',
          }
        ],
        'total': 7,
        'page': 1,
        'limit': 200,
        'summary': {
          'totalCollected': 731,
          'byMode': {
            'cash': {'amount': 310.5, 'count': 3},
            'split': {'amount': 210.25, 'count': 2},
          },
        },
      };

      final resp = PaymentListResponse.fromJson(json);
      expect(resp.payments.length, 1);
      expect(resp.payments[0].orderNo, 'ORD-2026-0015');
      expect(resp.payments[0].billNo, 'BILL-2026-0007');
      expect(resp.payments[0].grandTotal, 110.25);
      expect(resp.summary, isNotNull);
      expect(resp.summary!.totalCollected, 731.0);
      expect(resp.summary!.byMode['cash']?.amount, 310.5);
      expect(resp.summary!.byMode['cash']?.count, 3);
    });

    test('#128 PaymentDetail parses full receipt JSON with items and breakdown', () {
      final json = {
        '_id': '6adc5b167878cd44ef7c86ab',
        'outletId': {'_id': 'out_1', 'name': 'Main Kitchen', 'code': 'MK'},
        'tableId': null,
        'orderType': 'takeaway',
        'loyaltyPointsRedeemed': 0,
        'customerId': null,
        'items': [
          {
            'menuItemId': 'menu_123',
            'name': 'Paneer Butter Masala',
            'price': 250,
            'quantity': 2,
            'itemTotal': 500,
            'notes': 'Extra butter',
            'status': 'served',
            'sentToKitchenAt': '2026-10-24T07:15:34.434Z',
            '_id': 'item_123',
          }
        ],
        'subTotal': 500,
        'discountAmount': 50,
        'taxPercent': 5,
        'taxAmount': 22.5,
        'grandTotal': 472.5,
        'paymentMethod': 'cash',
        'paidAt': '2026-10-24T07:15:34.562Z',
        'orderNo': 'ORD-2026-0015',
        'billNo': 'BILL-2026-0007',
      };

      final detail = PaymentDetail.fromJson(json);
      expect(detail.id, '6adc5b167878cd44ef7c86ab');
      expect(detail.orderNo, 'ORD-2026-0015');
      expect(detail.billNo, 'BILL-2026-0007');
      expect(detail.items.length, 1);
      expect(detail.items[0].name, 'Paneer Butter Masala');
      expect(detail.items[0].price, 250.0);
      expect(detail.items[0].quantity, 2);
      expect(detail.subTotal, 500.0);
      expect(detail.discountAmount, 50.0);
      expect(detail.taxPercent, 5.0);
      expect(detail.grandTotal, 472.5);
    });
  });

  group('Module 13: PaymentsScreen UI & Responsiveness', () {
    testWidgets('PaymentsScreen renders #127 list, server summary, and filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            paymentsControllerProvider.overrideWith(() => _FakePaymentsController(mockPaymentListResponse)),
          ],
          child: const MaterialApp(home: PaymentsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payments & Receipts'), findsOneWidget);
      expect(find.text('TOTAL COLLECTED'), findsOneWidget);
      expect(find.text('₹731'), findsOneWidget);
      expect(find.text('CASH (3)'), findsOneWidget);
      expect(find.text('Order #ORD-2026-0015'), findsOneWidget);
      expect(find.text('Bill: BILL-2026-0007'), findsOneWidget);
      expect(find.text('₹110'), findsOneWidget);
      expect(find.text('Showing 1 of 1 payments'), findsOneWidget);
    });

    testWidgets('Responsiveness: PaymentsScreen at 360x800 portrait with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            paymentsControllerProvider.overrideWith(() => _FakePaymentsController(mockPaymentListResponse)),
          ],
          child: const MaterialApp(home: PaymentsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: PaymentsScreen at 800x360 landscape with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            paymentsControllerProvider.overrideWith(() => _FakePaymentsController(mockPaymentListResponse)),
          ],
          child: const MaterialApp(home: PaymentsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: PaymentsScreen at 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            paymentsControllerProvider.overrideWith(() => _FakePaymentsController(mockPaymentListResponse)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: PaymentsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PaymentDetailSheet renders full receipt breakdown for #128', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            paymentApiServiceProvider.overrideWithValue(_FakePaymentApiService(Dio(), mockPaymentDetail)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentDetailSheet(paymentId: 'pay_1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payment #ORD-2026-0015'), findsOneWidget);
      expect(find.text('Bill: BILL-2026-0007'), findsOneWidget);
      expect(find.text('1x Item 1'), findsOneWidget);
      expect(find.text('₹110.25'), findsOneWidget);
    });

    testWidgets('Responsiveness: PaymentDetailSheet at 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            paymentApiServiceProvider.overrideWithValue(_FakePaymentApiService(Dio(), mockPaymentDetail)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: PaymentDetailSheet(paymentId: 'pay_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
